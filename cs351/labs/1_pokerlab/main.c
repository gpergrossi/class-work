#include <stdio.h>
#include <stdlib.h>
#include "poker.h"

#define DEFAULT_GAME_FILE "poker.txt"

int main (int argc, char *argv[]) {
    char buf[40];
    FILE *infile;

    if (argc > 1) {
        infile = fopen(argv[1], "r");
    } else {
        infile = fopen(DEFAULT_GAME_FILE, "r");
    }
    if (!infile) {
        perror(NULL);
        exit(1);
    }

    int win, wins = 0, games = 0;
    char *h1, *h2;
    card_t hand1[5], hand2[5];
    
    while (fgets(buf, 40, infile)) {
        h1 = buf;
        buf[14] = '\0';
        h2 = &buf[15];
        buf[29] = '\0';

        string_to_hand(h1, hand1);
        string_to_hand(h2, hand2);

        wins += (win = compare_hands(hand2, hand1));
        printf("%4d: %s vs. %s; P%d wins!\n", games+1, h1, h2, win?1:2);
        games++;
    }
    fclose(infile);

    printf("\nSummary: P1 (%d wins) vs. P2 (%d wins)\n", wins, games-wins);
}
