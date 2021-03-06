#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sudoku.h"

#define NUM_DIGITS 9
#define NUM_ROWS   NUM_DIGITS
#define NUM_COLS   NUM_DIGITS
#define NUM_CELLS  NUM_DIGITS
#define CELL_SIZE  3
#define NUM_PEERS  20
#define NUM_UNITS  3
#define DIGITS     "123456789"
#define C_RED      "\x1B[31m"
#define C_BLUE     "\x1B[34m"
#define C_WHITE    "\x1B[37m"
#define C_PURPLE   "\x1B[35m"

#define DEBUG_ON    false
#define DEBUG       if(DEBUG_ON)

typedef unsigned char bool;
enum { false, true };

typedef struct square {
    char num_vals;  // Number of values left (1 if has been determined)
    bool vals[9];   // Possible values (boolean for each value 1 through 9)
    char assigned;  // 0 if not assigned, else the character that was assigned
    char row;       // The row number
    char col;       // the column number (NOT LETTERS!)
} square_t;

typedef struct puzzle {
    square_t squares[NUM_ROWS][NUM_COLS];
} puzzle_t;

void solve(unsigned char grid[9][9]);



// following are static ("private") function declarations --- add as needed

static puzzle_t *create_puzzle(unsigned char grid[9][9]);
static puzzle_t *copy_puzzle(puzzle_t *puz);
static void free_puzzle(puzzle_t *puz);
static void print_puzzle(puzzle_t *);

static puzzle_t *search(puzzle_t *puz);
static bool assign(puzzle_t *puz, int row, int col, char val);
static bool eliminate(puzzle_t *puz, int row, int col, char val);


/*************************/
/* Public solve function */
/*************************/

/**
 * Solves a sudoku puzzle. The puzzle must be a 9x9 array of grids using the 
 * values 1-9 to represent given numbers and 0 or '.' for unknowns.
 */
void solve(unsigned char grid[9][9]) {

    puzzle_t *puz = create_puzzle(grid);
    puzzle_t *solved;
    if ((solved = search(puz)) != NULL) {
        print_puzzle(solved);
        free_puzzle(solved);
    }
    free_puzzle(puz);
}



/*******************************************/
/* Puzzle data structure related functions */
/*******************************************/


/**
 * Initializes a puzzle_t structure given the raw character input.
 * The puzzle is interpretted as vals[row][col]
 */
static puzzle_t *create_puzzle(unsigned char vals[9][9]) {
    
    // Allocate the puzzle
    // This allocation includes space for all squares
    // and every square's peer and unit arrays (quite big)
    puzzle_t *puz = (puzzle_t *)malloc(sizeof(puzzle_t));

    int row,col,i;
    square_t *sqr;
    char chr;

    // Fill the squares
    for (row = 0; row < NUM_ROWS; row++) {
        for (col = 0; col < NUM_COLS; col++) {
            sqr = &(puz->squares[row][col]);
            chr = vals[row][col];

            // Fill in the possible values
            sqr->assigned = 0;

            if (chr == '0' || chr == '.') {
                // Unknown value
                for (i = 0; i < NUM_DIGITS; i++) {
                    sqr->vals[i] = true;
                }
                sqr->num_vals = 9;
            } else if ('1' <= chr && chr <= '9') {
                for (i = 0; i < NUM_DIGITS; i++) {
                    sqr->vals[i] = false;
                }
                int index = chr - '1';
                sqr->vals[index] = true;
                sqr->num_vals = 1;
            } else {
                fprintf(stderr, "Invalid character in puzzle '%c'\n.", chr);
            }
            
            // Fill in the row and col names
            sqr->row = (char)row;
            sqr->col = (char)col;
        }
    }

    return puz;
}

static void free_puzzle(puzzle_t *puz) {
    free(puz);
}

static puzzle_t *copy_puzzle(puzzle_t *puz) {
    puzzle_t *cpy = (puzzle_t *)malloc(sizeof(puzzle_t));

    // Copies a lot of pointless data (pointers not updated)
    //memcpy((void *) cpy, (void *)puz, sizeof(puzzle_t));

    square_t *sqr_from, *sqr_to;
    int i, j;
    for (i = 0; i < NUM_ROWS; i++) {
        for (j = 0; j < NUM_COLS; j++) {
            sqr_from = &(puz->squares[i][j]);
            sqr_to = &(cpy->squares[i][j]);

            memcpy((void *) &(sqr_to->vals), (void *) &(sqr_from->vals), 9);
            sqr_to->num_vals = sqr_from->num_vals;
            sqr_to->assigned = sqr_from->assigned;
            sqr_to->row = sqr_from->row;
            sqr_to->col = sqr_from->col;    
        }
    }

    return cpy;
}

void print_puzzle(puzzle_t *p) {
    int i, j, k;
    square_t *sqr;

    printf(C_WHITE "    1  2  3    4  5  6    7  8  9\n");
    for (i = 0; i < NUM_ROWS; i++) {

        if (i % 3 == 0) printf(C_WHITE " +----------+----------+----------+\n");
        printf("%c", "ABCDEFGHI"[i]);

        for (j = 0; j < NUM_COLS; j++) {
            sqr = &(p->squares[i][j]);

            if (j % 3 == 0) printf(C_WHITE "| ");

            if (p->squares[i][j].assigned) {
                printf(C_WHITE " %c ", sqr->assigned);
            } else {
                if (sqr->num_vals > 2) {
                    printf(C_BLUE " %d ", sqr->num_vals);
                } else {
                    printf(C_PURPLE);
                    if (sqr->num_vals == 1) printf(" ");
                    for (k = 0; k < NUM_DIGITS; k++) {
                        if (sqr->vals[k]) printf("%c", ('1'+k));
                    }
                    printf(" ");
                }
            }
        }
        printf(C_WHITE "|\n");
    }
    printf(C_WHITE " +----------+----------+----------+\n");
    printf("\n");
}


/**********/
/* Search */
/**********/

/**
 * Assign known values
 * Return false if conflicts are found, else true
 */
static int assign_knowns(puzzle_t *puz) {
    int row, col, i, assigns_made, success, total_assigns = 0;
    square_t *sqr;
    do {
        assigns_made = 0;
        for (row = 0; row < NUM_ROWS; row++) {
            for (col = 0; col < NUM_COLS; col++) {
                sqr = &(puz->squares[row][col]);
                if (sqr->assigned) continue;
                if (sqr->num_vals == 1) {
                    for (i = 0; i < NUM_DIGITS && !sqr->vals[i]; i++);
                    success = assign(puz, row, col, '1'+i);
                    if (!success) return 0;
                    assigns_made++;
                }
            }
        }
        total_assigns += assigns_made;
    } while (assigns_made > 0);
    DEBUG {
        if (total_assigns > 0) {
            printf("Assigned %d values\n", total_assigns);
        } else {
            printf("No assignable values found");
        }
    }
    return 1;
}

/**
 * Searches the puzzle for solutions by the following process:
 * 
 * 1. Looking for any squares with only one possible value and assign them
 *
 * 2. Repeat step 1 until no assigns are made (Recursive approach could be very deep)i
 *       If there are conflicts
 *          Free original puzzle
 *          Return NULL
 *
 * 3. Pick square with lowest number of possible values
 *
 * 4. For each possible value:
 *    Create a copy of the puzzle
 *    Assign the guess value
 *    Call search()
 *    If search returns successful
 *       Return solved
 *    Else
 *       Continue with Step 4
 *
 * 5. If Step 4 completes without a solution
 *    Free original puzzle
 *    Return NULL, the puzzle is unsolvable
 *
 * This approach will not create any unfreed puzzled. In doing so, it will
 * free the original puzzle unless the original puzzle happens to be solved
 * in which case it is returned untouched.
 *
 * After calling this function, the puz pointer passed in is no longer valid,
 * only the returned puzzle is guaranteed to be valid.
 */
static puzzle_t *search_aux(puzzle_t *puz) {

    int row, col, success;
    square_t *sqr; 

    // 1. Looking for any squares with only one possible value and assign them
    // 2. Repeat step 1 until no assigns are made (Recursive approach could be very deep)
    success = assign_knowns(puz);
    if (!success) {
        DEBUG printf(C_RED "Solve attempt failed. Conflict in assignable values.\n\n" C_WHITE);
        free(puz);
        return NULL;
    }

    DEBUG {
        printf("Searching:\n");
        print_puzzle(puz);
    }

    // 3. Pick square with lowest number of possible values
    square_t *winner = NULL;
    int lowest_count = 10;
    for (row = 0; row < NUM_ROWS; row++) {
        for (col = 0; col < NUM_COLS; col++) {
            sqr = &(puz->squares[row][col]);
            if (sqr->assigned) continue;
            if (sqr->num_vals < lowest_count) {
                lowest_count = sqr->num_vals;
                winner = sqr;
                if (lowest_count == 2) goto done_searching_sudoku_squares;
            }
        }
    }
    done_searching_sudoku_squares:

    if (lowest_count == 10) {
        // The puzzle has no unknowns! Solved
        DEBUG printf("SOLVED: No unknowns left\n");
        return puz;
    }

    // 4. For each possible value:
    puzzle_t *solved = NULL;
    int i, processed = 0;
    for (i = 0; i < NUM_DIGITS; i++) {
        if (!winner->vals[i]) continue;

        // Create a copy of the puzzle
        puzzle_t *cpy = copy_puzzle(puz);

        // Assign the guess value
        assign(cpy, winner->row, winner->col, ('1'+i));

        // Call search()
        DEBUG printf("Trying %c in square %c%d\n", ('1'+i), "ABCDEFGHI"[(int) winner->row], winner->col+1);
        solved = search_aux(cpy);

        if (solved != NULL) { // If search returns successful
            free(puz);        //   Free original
            return solved;    //   Return solved
        } else {              // Else
            // Copy already freed by failed search_aux call
        }

        if (++processed >= winner->num_vals) break;
    } // Continue with step 4


    // 5. If Step 4 completes without a solution
    DEBUG printf(C_RED "Solve attempt failed. No attempted solutions returned successful.\n\n" C_WHITE);
    free(puz);   // Free original
    return NULL; // Return NULL, the puzzle is unsolvable
}

/**
 * Calls search_aux, see comments
 * Return value and original puzzle argument are
 * guaranteed to be separate and valid pointers.
 * However, the return pointer may be NULL if no
 * solution exists.
 */
static puzzle_t *search(puzzle_t *puz) {
    DEBUG printf("Solving:\n");
    DEBUG print_puzzle(puz);

    puzzle_t *cpy = copy_puzzle(puz);
    return search_aux(cpy);
}

/**************************/
/* Constraint propagation */
/**************************/

/**
 * Sets the square at (row, col) to val.
 * Eliminates val from all peers.
 * Returns false if there was a conflict, else true
 */
bool assign(puzzle_t *puz, int row, int col, char val) {
    square_t *sqr = &(puz->squares[row][col]);
    int i,j;

    // Mark this square as assigned, vals array no longer matters
    sqr->num_vals = 1;
    sqr->assigned = val;

    // Eliminate val in all peers, break on conflict
    int cell_x = (col / 3) * 3;
    int cell_y = (row / 3) * 3;
    // Eliminate Row and Col peers
    for (i = 0; i < NUM_ROWS; i++) {
        if (i != col)
            if (!eliminate(puz, row, i, val)) return false;
        if (i != row)
            if (!eliminate(puz, i, col, val)) return false;
    }
    // Finish the cell squares that weren't included in row or col
    for (i = cell_x; i < cell_x + 3; i++) {
        for (j = cell_y; j < cell_y + 3; j++) {
            if (i == col) continue;
            if (j == row) continue;
            if (!eliminate(puz, j, i, val)) return false;
        }
    }

    return true;
}

/**
 * Eliminates val from the square (row, col)
 * Returns false if val was last possible value for the square, else true
 */
bool eliminate(puzzle_t *puz, int row, int col, char val) { 
    square_t *sqr = &(puz->squares[row][col]);
    int index = val - '1';

    // Square is assigned and assigned value is not being eliminated
    if (sqr->assigned) {
        if (sqr->assigned == val) return false;
        return true;
    }

    if (!sqr->vals[index]) return true;     // Value already eliminated
    if (sqr->num_vals == 1) return false;   // Can't eliminate last value

    sqr->vals[index] = false;   // Eliminate value
    sqr->num_vals--;            // Decrement count

    return true;    // Return successful
}

/*****************************************/
/* Misc (e.g., utility) functions follow */
/*****************************************/
