/* 
 * tsh - A tiny shell program with job control
 */
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>

/* Misc manifest constants */
#define MAXLINE    1024   /* max line size */
#define MAXARGS     128   /* max args on a command line */
#define MAXJOBS      16   /* max jobs at any point in time */
#define MAXJID    1<<16   /* max job ID */

/* Magic Numbers */
#define NOTFOUND 127 /* Returned when command not found (127 is used by bash as well) */

/* Job states */
#define UNDEF 0 /* undefined */
#define FG 1    /* running in foreground */
#define BG 2    /* running in background */
#define ST 3    /* stopped */

/* 
 * Jobs states: FG (foreground), BG (background), ST (stopped)
 * Job state transitions and enabling actions:
 *     FG -> ST  : ctrl-z
 *     ST -> FG  : fg command
 *     ST -> BG  : bg command
 *     BG -> FG  : fg command
 * At most 1 job can be in the FG state.
 */

/* Global variables */
extern char **environ;      /* defined in libc */
char prompt[] = "tsh> ";    /* command line prompt (DO NOT CHANGE) */
int verbose = 0;            /* if true, print additional output */
int nextjid = 1;            /* next job ID to allocate */
char sbuf[MAXLINE];         /* for composing sprintf messages */

struct job_t {              /* The job struct */
    pid_t pid;              /* job PID */
    int jid;                /* job ID [1, 2, ...] */
    int state;              /* UNDEF, BG, FG, or ST */
    char cmdline[MAXLINE];  /* command line */
};
struct job_t jobs[MAXJOBS]; /* The job list */
/* End global variables */


/* Function prototypes */

/* Here are the functions that you will implement */
void eval(char *cmdline);
int builtin_cmd(char **argv);
void do_bgfg(char **argv);
void waitfg(pid_t pid);

void sigchld_handler(int sig);
void sigtstp_handler(int sig);
void sigint_handler(int sig);

/* Here are helper routines that we've provided for you */
int parseline(const char *cmdline, char **argv); 
void sigquit_handler(int sig);

void clearjob(struct job_t *job);
void initjobs(struct job_t *jobs);
int maxjid(struct job_t *jobs); 
int addjob(struct job_t *jobs, pid_t pid, int state, char *cmdline);
int deletejob(struct job_t *jobs, pid_t pid); 
pid_t fgpid(struct job_t *jobs);
struct job_t *getjobpid(struct job_t *jobs, pid_t pid);
struct job_t *getjobjid(struct job_t *jobs, int jid); 
int pid2jid(pid_t pid); 
void listjobs(struct job_t *jobs);

void usage(void);
void unix_error(char *msg);
void app_error(char *msg);
typedef void handler_t(int);
handler_t *Signal(int signum, handler_t *handler);

/*
 * main - The shell's main routine 
 */
int main(int argc, char **argv) 
{
    char c;
    char cmdline[MAXLINE];
    int emit_prompt = 1; /* emit prompt (default) */

    /* Redirect stderr to stdout (so that driver will get all output
     * on the pipe connected to stdout) */
    dup2(1, 2);

    /* Parse the command line */
    while ((c = getopt(argc, argv, "hvp")) != EOF) {
        switch (c) {
        case 'h':             /* print help message */
            usage();
	    break;
        case 'v':             /* emit additional diagnostic info */
            verbose = 1;
	    break;
        case 'p':             /* don't print a prompt */
            emit_prompt = 0;  /* handy for automatic testing */
	    break;
	default:
            usage();
	}
    }

    /* Install the signal handlers */

    /* These are the ones you will need to implement */
    Signal(SIGINT,  sigint_handler);   /* ctrl-c */
    Signal(SIGTSTP, sigtstp_handler);  /* ctrl-z */
    Signal(SIGCHLD, sigchld_handler);  /* Terminated or stopped child */

    /* This one provides a clean way to kill the shell */
    Signal(SIGQUIT, sigquit_handler); 

    /* Initialize the job list */
    initjobs(jobs);

    /* Execute the shell's read/eval loop */
    while (1) {

	  /* Read command line */
	  if (emit_prompt) {
	      printf("%s", prompt);
	      fflush(stdout);
	  }
	  if ((fgets(cmdline, MAXLINE, stdin) == NULL) && ferror(stdin))
	      app_error("fgets error");
	  if (feof(stdin)) { /* End of file (ctrl-d) */
	      fflush(stdout);
	      exit(0);
	  }

	  /* Evaluate the command line */
	  eval(cmdline);
	  fflush(stdout);
	  fflush(stdout);
    } 

    exit(0); /* control never reaches here */
}
  
/* 
 * eval - Evaluate the command line that the user has just typed in
 * 
 * If the user has requested a built-in command (quit, jobs, bg or fg)
 * then execute it immediately. Otherwise, fork a child process and
 * run the job in the context of the child. If the job is running in
 * the foreground, wait for it to terminate and then return.  Note:
 * each child process must have a unique process group ID so that our
 * background children don't receive SIGINT (SIGTSTP) from the kernel
 * when we type ctrl-c (ctrl-z) at the keyboard.  
*/
void eval(char *cmdline) {
    pid_t pid;
    char *argv[MAXARGS];
    char *p = cmdline;
    int fdin = 0, fdout = 0, pfds[2], ispipe = 0;
    struct job_t *job;
    sigset_t mask;

    // Check for IO redirection
    if (strchr(cmdline, '>')) { 
        strsep(&p, ">");
        parseline(p, argv);
        
        // Check if second part is a filename (one arg, no spaces)
        if (argv[0] == NULL || argv[1] != NULL) {
            printf("Output redirection '>' only supports 'command > file' syntax.\n");
            return;
        }
        fdout = open(argv[0], O_WRONLY | O_CREAT | O_TRUNC, 0644);

        if (fdout < 0) {
            printf("Failed to open file for writing \"%s\".\n", p);
            return;
        }
    } else if (strchr(cmdline, '<')) { 
        strsep(&p, "<");
        parseline(p, argv);
        
        // Check if second part is a filename (one arg, no spaces)
        if (argv[0] == NULL || argv[1] != NULL) {
            printf("Output redirection '>' only supports 'command > file' syntax.\n");
            return;
        }
        fdin = open(argv[0], O_RDONLY);
        
        if (fdin < 0) {
            printf("Failed to open file for reading \"%s\".\n", p);
            return;
        }
    } else if (strchr(cmdline, '|')) {
        strsep(&p, "|");
        ispipe = 1;
        if (pipe(pfds) < 0) {
            printf("Error creating pipe.\n");
            return;
        }
    }
    int bg = parseline(cmdline, argv);
    
    // Check for built in command
    if (builtin_cmd(argv)) return;

    // Fork and Exec in child process
    sigemptyset(&mask);
    sigaddset(&mask, SIGCHLD);
    sigprocmask(SIG_BLOCK, &mask, NULL);  // Block SIGCHLD for now
    if ((pid = fork()) == 0) {
        // In child process:
        pid = getpid();
        setpgid(pid, pid);                     // Make process its own group
        sigprocmask(SIG_UNBLOCK, &mask, NULL); // Unblock child's SIGCHLD

        // If fdout is open, redirect output
        if (fdout && dup2(fdout, 1) < 0) printf("Problem redirecting output.\n");

        // If fdin is open, redirect input
        if (fdin && dup2(fdin, 0) < 0) printf("Problem redirecting input.\n");

        // If pipe is open, redirect output
        if (ispipe) {
            if (dup2(pfds[1], 1) < 0) printf("Problem redirecting output to pipe.\n");
            if (close(pfds[0]) < 0) printf("Problem closing read end of pipe.\n");
        }

        execvp(argv[0], argv);                 // Exec, replacing this process
        exit(NOTFOUND);                        // If failed, exit with NOTFOUND
    } else {
        if (fdout > 0 && close(fdout) < 0) {
            printf("Problem closing file descriptor %d.\n", fdout);
        }
        if (fdin > 0 && close(fdin) < 0) {
            printf("Problem closing file descriptor %d.\n", fdin);
        }

        // Shell waits or prints background job info
        addjob(jobs, pid, (bg || ispipe) ? BG : FG, cmdline); // Add the job to the job list
        sigprocmask(SIG_UNBLOCK, &mask, NULL);    // Unblock shell's SIGCHLD

        if (ispipe) {
            sigprocmask(SIG_BLOCK, &mask, NULL);  // Block SIGCHLD for now
            if ((pid = fork()) == 0) {
                // In child process:
                pid = getpid();
                setpgid(pid, pid);                     // Make process its own group
                sigprocmask(SIG_UNBLOCK, &mask, NULL); // Unblock child's SIGCHLD

                // If pipe is open, redirect input
                if (dup2(pfds[0], 0) < 0) printf("Problem redirecting input to pipe.\n");
                if (close(pfds[1]) < 0) printf("Problem closing write end of pipe.\n");
    
                parseline(p, argv);
                execvp(argv[0], argv);                 // Exec, replacing this process
                exit(NOTFOUND);                        // If failed, exit with NOTFOUND
            } else {
                // Shell waits or prints background job info
                addjob(jobs, pid, FG, p); // Add the job to the job list
                sigprocmask(SIG_UNBLOCK, &mask, NULL);    // Unblock shell's SIGCHLD
                
                // Shell doesn't need pipe
                if (close(pfds[0]) < 0) printf("Problem closing pipe[0] on shell.\n");
                if (close(pfds[1]) < 0) printf("Problem closing pipe[1] on shell.\n");
            }
        }

    }

    if(bg && !ispipe) {
        // Print background job info
        job = getjobpid(jobs, pid);
        printf("[%d] (%d) %s",job->jid, job->pid, job->cmdline);
    } else {
        // Wait for the foreground process to finish
        waitfg(pid);
    }
    return;
}

/* 
 * parseline - Parse the command line and build the argv array.
 * 
 * Characters enclosed in single quotes are treated as a single
 * argument.  Return true if the user has requested a BG job, false if
 * the user has requested a FG job.  
 */
int parseline(const char *cmdline, char **argv) {
    static char array[MAXLINE]; /* holds local copy of command line */
    char *buf = array;          /* ptr that traverses command line */
    char *delim;                /* points to first space delimiter */
    int argc;                   /* number of args */
    int bg;                     /* background job? */

    strcpy(buf, cmdline);
    buf[strlen(buf)-1] = ' ';  /* replace trailing '\n' with space */
    while (*buf && (*buf == ' ')) /* ignore leading spaces */
	buf++;

    /* Build the argv list */
    argc = 0;
    if (*buf == '\'') {
	buf++;
	delim = strchr(buf, '\'');
    }
    else {
	delim = strchr(buf, ' ');
    }

    while (delim) {
	    argv[argc++] = buf;
    	*delim = '\0';
    	buf = delim + 1;
    	while (*buf && (*buf == ' ')) /* ignore spaces */
            buf++;
     
        if (*buf == '\'') {
	        buf++;
    	    delim = strchr(buf, '\'');
    	} else {
    	    delim = strchr(buf, ' ');
    	}
    }
    argv[argc] = NULL;
    
    if (argc == 0)  /* ignore blank line */
	return 1;

    /* should the job run in the background? */
    if ((bg = (*argv[argc-1] == '&')) != 0) {
	    argv[--argc] = NULL;
    }
    return bg;
}

/* 
 * builtin_cmd - If the user has typed a built-in command then execute
 *    it immediately.  
 */
int builtin_cmd(char **argv) {
  if (strcmp(argv[0], "quit") == 0) {
    exit(0);
  } else if (strcmp(argv[0], "jobs") == 0) {
    listjobs(jobs); 
    return 1;
  } else if (strcmp(argv[0], "bg") == 0) {
    do_bgfg(argv);
    return 1;
  } else if (strcmp(argv[0], "fg") == 0) {
    do_bgfg(argv);
    return 1;
  } else if (strcmp(argv[0], "kill") == 0) {
    return 1;
  }
  return 0;     /* not a builtin command */
}

/* 
 * do_bgfg - Execute the builtin bg and fg commands
 */
void do_bgfg(char **argv) {
    int bg = -1;
    char c = *(argv[0]);
    bg = (c == 'f') ? 0 : ((c == 'b') ? 1 : -1); // FG -> 0, BG -> 1, else -1
    
    //Assert, command is either bg or fg.
    if (bg == -1) {
        printf("Bad do_bgfg call.");
        return;
    }
    
    // Bad arguments: No args or too many
    if (argv[1] == 0 || argv[2] != 0) {
        printf("%s command requires PID or %%jobid argument\n", argv[0]);
        return;
    }
    
    // Check if using job syntax
    int isjob = 0;
    char *number = argv[1];
    if (*(argv[1]) == '%') {
        isjob = 1;
        number = &argv[1][1]; // Remove leading '%'
    }

    // Check for a valid unsigned int with no trailing characters
    int id = 0;
    char trash = 0;
    int success = sscanf(number, "%u%c", &id, &trash); // Unsigned integer

    // Check if argument is a valid number
    if (success != 1) {
        printf("%s: argument must be a PID or %%jobid\n", argv[0]);
        return;
    }

    // Get the job from the job id or process id
    struct job_t *job = NULL;
    if (isjob) { 
        job = getjobjid(jobs, id); 
    } else { 
        job = getjobpid(jobs, id); 
    }

    // Check if job exists
    if (job == NULL) {
        if (isjob) {
            printf("%s: No such job\n", argv[1]);
        } else {
            printf("%s: No such process\n", argv[1]);
        }
        return;
    }

    // Check for strange condition
    if (job->state == FG) {
        printf("%s cannot be used on a foreground process!\n", argv[0]);
        return;
    }

    // Finish up
    int needcont = (job->state == ST);  // Check if a SIGCONT is needed
    job->state = bg ? BG : FG;          // Change state first to avoid race condition
    if (needcont) {
        killpg(job->pid, SIGCONT);      // Send SIGCONT to process group if needed
    }
    if (!bg) {
        waitfg(job->pid);               // Wait if foreground process
    } else {
        printf("[%d] (%d) %s",job->jid, job->pid, job->cmdline); // Print bg message
    }
    return;
}

/* 
 * waitfg - Block until process pid is no longer the foreground process
 */
void waitfg(pid_t pid) {
    struct job_t *job = getjobpid(jobs, pid);
    if (job == NULL) return; // Job already terminated.
    while (job->state == FG) {
        sleep(1); // Note signals stop this immediately. No performance problem
    }
    return;
}

/*****************
 * Signal handlers
 *****************/

/* 
 * sigchld_handler - The kernel sends a SIGCHLD to the shell whenever
 *     a child job terminates (becomes a zombie), or stops because it
 *     received a SIGSTOP or SIGTSTP signal. The handler reaps all
 *     available zombie children, but doesn't wait for any other
 *     currently running children to terminate.  
 */
void sigchld_handler(int sig) {
    pid_t pid;
    int status;
    struct job_t *job;

    while ((pid = waitpid(-1, &status, WNOHANG | WUNTRACED | WCONTINUED)) > 0) {
        // Get pointer to job struct
        job = getjobpid(jobs, pid);

        if (WIFEXITED(status)) { 
        // Case exited normally
        
            if (WEXITSTATUS(status) == NOTFOUND) {
                char *argv[MAXARGS];
                parseline(job->cmdline, argv);
                printf("%s: Command not found\n", argv[0]);
            }  else {
                //printf("Process exited normally with return value of %d\n", 
                //    WEXITSTATUS(status));
            }
            deletejob(jobs, pid); // Job reaped, remove from jobs list

        } else if (WIFSIGNALED(status)) { 
        // Case terminated to signal
        
            printf("Job [%d] (%d) terminated by signal %d\n", 
                job->jid, job->pid, WTERMSIG(status));
            deletejob(jobs, pid); // Job reaped, remove from jobs list

        } else if (WIFSTOPPED(status)) {
        // Case stopped by signal
        
            printf("Job [%d] (%d) stopped by signal %d\n", 
                job->jid, job->pid, WSTOPSIG(status));
            job->state = ST; // Stopped

        } else if (WIFCONTINUED(status)) {
        // Case process reporting continuation
            
        } else {
        // Else, unknown
            printf("Unhandled status change: (%d) %d\n", pid, status);
        }

    }
    return;
}

/* 
 * sigint_handler - The kernel sends a SIGINT to the shell whenever the
 *    user types ctrl-c at the keyboard.  Catch it and send it along
 *    to the foreground job.  
 */
void sigint_handler(int sig) {
    pid_t pid = fgpid(jobs);
    // Send interrupt signal
    if (pid != 0) killpg(pid, sig);
    return;
}

/*
 * sigtstp_handler - The kernel sends a SIGTSTP to the shell whenever
 *     the user types ctrl-z at the keyboard. Catch it and suspend the
 *     foreground job by sending it a SIGTSTP.  
 */
void sigtstp_handler(int sig) {
    pid_t pid = fgpid(jobs);
    // Send stop signal (TODO: send to group id)
    if (pid != 0) killpg(pid, sig);
    return;
}

/*********************
 * End signal handlers
 *********************/

/***********************************************
 * Helper routines that manipulate the job list
 **********************************************/

/* clearjob - Clear the entries in a job struct */
void clearjob(struct job_t *job) {
    job->pid = 0;
    job->jid = 0;
    job->state = UNDEF;
    job->cmdline[0] = '\0';
}

/* initjobs - Initialize the job list */
void initjobs(struct job_t *jobs) {
    int i;

    for (i = 0; i < MAXJOBS; i++)
	clearjob(&jobs[i]);
}

/* maxjid - Returns largest allocated job ID */
int maxjid(struct job_t *jobs) 
{
    int i, max=0;

    for (i = 0; i < MAXJOBS; i++)
	if (jobs[i].jid > max)
	    max = jobs[i].jid;
    return max;
}

/* addjob - Add a job to the job list */
int addjob(struct job_t *jobs, pid_t pid, int state, char *cmdline) 
{
    int i;
    
    if (pid < 1)
	return 0;

    for (i = 0; i < MAXJOBS; i++) {
	if (jobs[i].pid == 0) {
	    jobs[i].pid = pid;
	    jobs[i].state = state;
	    jobs[i].jid = nextjid++;
	    if (nextjid > MAXJOBS)
		nextjid = 1;
	    strcpy(jobs[i].cmdline, cmdline);
  	    if(verbose){
	        printf("Added job [%d] %d %s\n", jobs[i].jid, jobs[i].pid, jobs[i].cmdline);
            }
            return 1;
	}
    }
    printf("Tried to create too many jobs\n");
    return 0;
}

/* deletejob - Delete a job whose PID=pid from the job list */
int deletejob(struct job_t *jobs, pid_t pid) 
{
    int i;

    if (pid < 1)
	return 0;

    for (i = 0; i < MAXJOBS; i++) {
	if (jobs[i].pid == pid) {
	    clearjob(&jobs[i]);
	    nextjid = maxjid(jobs)+1;
	    return 1;
	}
    }
    return 0;
}

/* fgpid - Return PID of current foreground job, 0 if no such job */
pid_t fgpid(struct job_t *jobs) {
    int i;

    for (i = 0; i < MAXJOBS; i++)
	if (jobs[i].state == FG)
	    return jobs[i].pid;
    return 0;
}

/* getjobpid  - Find a job (by PID) on the job list */
struct job_t *getjobpid(struct job_t *jobs, pid_t pid) {
    int i;

    if (pid < 1)
	return NULL;
    for (i = 0; i < MAXJOBS; i++)
	if (jobs[i].pid == pid)
	    return &jobs[i];
    return NULL;
}

/* getjobjid  - Find a job (by JID) on the job list */
struct job_t *getjobjid(struct job_t *jobs, int jid) 
{
    int i;

    if (jid < 1)
	return NULL;
    for (i = 0; i < MAXJOBS; i++)
	if (jobs[i].jid == jid)
	    return &jobs[i];
    return NULL;
}

/* pid2jid - Map process ID to job ID */
int pid2jid(pid_t pid) 
{
    int i;

    if (pid < 1)
	return 0;
    for (i = 0; i < MAXJOBS; i++)
	if (jobs[i].pid == pid) {
            return jobs[i].jid;
        }
    return 0;
}

/* listjobs - Print the job list */
void listjobs(struct job_t *jobs) 
{
    int i;
    
    for (i = 0; i < MAXJOBS; i++) {
	if (jobs[i].pid != 0) {
	    printf("[%d] (%d) ", jobs[i].jid, jobs[i].pid);
	    switch (jobs[i].state) {
		case BG: 
		    printf("Running ");
		    break;
		case FG: 
		    printf("Foreground ");
		    break;
		case ST: 
		    printf("Stopped ");
		    break;
	    default:
		    printf("listjobs: Internal error: job[%d].state=%d ", 
			   i, jobs[i].state);
	    }
	    printf("%s", jobs[i].cmdline);
	}
    }
}
/******************************
 * end job list helper routines
 ******************************/


/***********************
 * Other helper routines
 ***********************/

/*
 * usage - print a help message
 */
void usage(void) 
{
    printf("Usage: shell [-hvp]\n");
    printf("   -h   print this message\n");
    printf("   -v   print additional diagnostic information\n");
    printf("   -p   do not emit a command prompt\n");
    exit(1);
}

/*
 * unix_error - unix-style error routine
 */
void unix_error(char *msg)
{
    fprintf(stdout, "%s: %s\n", msg, strerror(errno));
    exit(1);
}

/*
 * app_error - application-style error routine
 */
void app_error(char *msg)
{
    fprintf(stdout, "%s\n", msg);
    exit(1);
}

/*
 * Signal - wrapper for the sigaction function
 */
handler_t *Signal(int signum, handler_t *handler) 
{
    struct sigaction action, old_action;

    action.sa_handler = handler;  
    sigemptyset(&action.sa_mask); /* block sigs of type being handled */
    action.sa_flags = SA_RESTART; /* restart syscalls if possible */

    if (sigaction(signum, &action, &old_action) < 0)
	unix_error("Signal error");
    return (old_action.sa_handler);
}

/*
 * sigquit_handler - The driver program can gracefully terminate the
 *    child shell by sending it a SIGQUIT signal.
 */
void sigquit_handler(int sig) 
{
    printf("Terminating after receipt of SIGQUIT signal\n");
    exit(1);
}



