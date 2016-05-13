#include <stdio.h>
#include <stdlib.h>
#include "cache.h"

void printUsage(char *arg0) {
    printf("Usage: ");
    printf(arg0);
    printf(" num_lines lines_per_set bytes_per_block\n");
}

int main (int argc, char *argv[]) {

    if (argc < 4) {
        printUsage(argv[0]);
    }
    
    int num_lines = atoi(argv[1]),
        lines_per_set = atoi(argv[2]),
        bytes_per_block = atoi(argv[3]);

    // Verify valid input
    if (num_lines == 0 || lines_per_set == 0 || bytes_per_block == 0) {
        printUsage(argv[0]);
        printf("All arguments must be positive integers!\n");
        return 1;
    }

    // Lines is divisible by lines per set
    if ((num_lines % lines_per_set) != 0) {
        printUsage(argv[0]);
        printf("Number of lines must be evenly divisible by lines per set!\n");
        return 1;
    }

    // Bytes per block is power of 2
    int i, power = -1;
    for (i = 0; i < 32; i++) {
        if ((1 << i) == bytes_per_block) {
            power = i;
            break;
        }
    }
    if (power == -1) {
        printUsage(argv[0]);
        printf("Bytes per block must be an integer power of 2!\n");
        return 1;
    }

    char line[80];

    long addr_req;

    //printf("Simulating cache with:\n");
    //printf(" - Total lines   = %d\n", num_lines);
    //printf(" - Lines per set = %d\n", lines_per_set);
    //printf(" - Block size    = %d bytes\n", bytes_per_block);
   
    cache_t *cache = cache_make(num_lines, lines_per_set, bytes_per_block);
    
    int hits = 0, total = 0;

    while (fgets(line, 80, stdin)) {
        addr_req = strtol(line, NULL, 0);

        /* simulate cache fetch with address `addr_req` */
        // printf("Processing request: 0x%lX - ", addr_req);
               
        char success = cache_sim_read(cache, addr_req);
        hits += (success ? 1 : 0);
        total++;
    }

    float hit_rate = 100.0f * ((float)hits / (float)total);
    float miss_rate = 100.0f - hit_rate;

    printf("Hit rate: %.2f% | Miss rate: %.2f%\n", hit_rate, miss_rate);

    cache_free(cache);

    return 0;
}
