//#include <stdlib.h>
//#include <stdio.h>
#include "types.h"
#include "user.h"
#include "syscall.h"

int something = 0;

void somefunc(void *_) {
    something++;
    
    printf(1, "child reporting\n");
    
    exit();
}

int main(int argc, char *argv[]) {
    
    void *stack = malloc(4096);
    stack = (void *)((char *)stack + 4096); // Stack points to bottom, grows to lower addresses

    int thread_id = thread_create(&somefunc, stack, 0);

    printf(1, "child = %d\n", thread_id);

    int child = thread_join(&stack);

    printf(1, "join returned %d\n", child);

    printf(1, "something: %d\n", something);

    exit();
}
