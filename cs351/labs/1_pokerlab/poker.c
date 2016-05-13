#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "poker.h"

/* converts a hand (of 5 cards) to a string representation, and stores it in the
 * provided buffer. The buffer is assumed to be large enough.
 */
void hand_to_string (hand_t hand, char *handstr) {
    char *p = handstr;
    int i;
    char *val, *suit;
    for (i=0; i<5; i++) {
        if (hand[i].value < 10) {
            *p++ = hand[i].value + '0'; // Make use of ASCII offset from '0'
        } else {
            switch(hand[i].value) {
            case 10: *p++ = 'T'; break;
            case 11: *p++ = 'J'; break;
            case 12: *p++ = 'Q'; break;
            case 13: *p++ = 'K'; break;
            case 14: *p++ = 'A'; break;
            }
        }
        switch(hand[i].suit) {
        case DIAMOND: *p++ = 'D'; break;
        case CLUB: *p++ = 'C'; break;
        case HEART: *p++ = 'H'; break;
        case SPADE: *p++ = 'S'; break;
        }
        if (i<=3) *p++ = ' ';
    }
    *p = '\0'; // Finish with a null-terminator
}

/* converts a string representation of a hand into 5 separate card structs. The
 * given array of cards is populated with the card values.
 */
void string_to_hand (const char *handstr, hand_t hand) {
    const char *p = handstr;
    char c;
    int i;
    for (i=0; i<5; i++) {
        c = *p++;
        if (c > '1' && c <= '9') {
            hand[i].value = c - '0'; // Convert character '0'-'9' to value 0-9
        } else {
            switch(c) {
            case 'T': hand[i].value = 10; break;
            case 'J': hand[i].value = 11; break;
            case 'Q': hand[i].value = 12; break;
            case 'K': hand[i].value = 13; break;
            case 'A': hand[i].value = 14; break;
            default:  hand[i].value =  0; // Invalid card
            }
        }
        c = *p++;
        switch(c) {
        case 'D': hand[i].suit = DIAMOND; break;
        case 'C': hand[i].suit = CLUB;    break;
        case 'H': hand[i].suit = HEART;   break;
        case 'S': hand[i].suit = SPADE;   break;
        default:  hand[i].value = 0; // Invalid card
        }
        p++; // Skip a space
    }
}

/* PRIVATE
 * compares two cards, 
 * returns c2 > c1 ? 1 : 0 
 */
int compare_cards (card_t c1, card_t c2) {
    if (c2.value > c1.value) return 1;
    if (c2.value < c1.value) return 0;
    // Compare by suits alphabetically (ASCII)
    if (c2.suit > c1.suit) return 1;
    return 0;
}

/* PRIVATE
 * checks if a hand is sorted
 */
int is_sorted (hand_t hand) {
    int i;
    for (i=0; i<4; i++) {
        if (compare_cards(hand[i+1], hand[i])) return 0;
    }
    return 1;
}

/* sorts the hands so that the cards are in ascending order of value (two
 * lowest, ace highest. Uses in-place selection sort because in-place is
 * cleaner than other methods and selection sort has minimal swaps.
 */
void sort_hand (hand_t hand) {
    int i,j;
    // Search i<4 because if i=5 the subset is 1 element and does not need sorting
    for (i=0; i<4; i++) {
        int low = i;
        // Search j > i and j < 5 for a lower card in the set
        for (j=i+1; j<5; j++) {
            low = compare_cards(hand[low], hand[j]) ? low : j;
        }
        if (low != i) {
            // Swap lowest card with lowers considered position
            card_t swap = hand[i];
            hand[i] = hand[low];
            hand[low] = swap;
        }
    }
}

/* PRIVATE
 * counts the number of distinct sets of 2 cards (or more) of the same value. 
 */
int count_pairs (hand_t hand) {
    int i,j;
    int pairs = 0;
    for (i=0; i<4; i++) {
        int num = 0;
        for (j=0; j<5; j++) {
            if (hand[j].value == hand[i].value) num++;
        }
        if (num >= 2) {
            int ispair = 1;
            for (j=0; j<i && ispair; j++) {
                if (hand[j].value == hand[i].value) ispair = 0;
            }
            if (ispair) pairs++;
        }
    }
    return pairs;
}

/* PRIVATE
 * checks if the hand contains x (or more) cards of the same value
 */ 
int is_xofakindrev (hand_t hand, int x) {
    int i,j,num;
    for (i=4; i>=(x-1); i--) {
        num = 1;
        for (j=i-1; j>=0; j--) {
            if (hand[j].value == hand[i].value) num++;
            if (num == x) return hand[i].value;
        }
    }
    return 0;
}

/* PRIVATE
 * checks if the hand contains x (or more) cards of the same value
 */ 
int is_xofakind (hand_t hand, int x) {
    int i,j,num;
    for (i=0; i<(6-x); i++) {
        num = 1;
        for (j=i+1; j<5; j++) {
            if (hand[j].value == hand[i].value) num++;
            if (num == x) return hand[i].value;
        }
    }
    return 0;
}

/* checks if the hand contains two cards (or more) of the same value
 */
int is_onepair (hand_t hand) {
    return is_xofakind(hand, 2);
}

/* checks if the hand contains two distinct sets of 2 (or more) cards of the same value
 */
int is_twopairs (hand_t hand) {
    return count_pairs(hand) >= 2;
}

/* checks if the hand contains three cards (or more) of the same value
 */
int is_threeofakind (hand_t hand) {
    return is_xofakind(hand, 3);
}

/* checks if the values of the cards are in ascending order
 * including the special case of {A,2,3,4,5}.
 * IMPORTANT: this method will sort the hand as a side effect!
 */
int is_straight (hand_t hand) {
    if (!is_sorted(hand)) sort_hand(hand);
    int i;
    for (i=1; i<5; i++) {
        if (hand[i].value != hand[i-1].value+1
         && (hand[i].value != 14 || hand[i-1].value != 5)) {
            return 0;
        }
    }
    return 1;
}

/* checks if the hand contains two distinct sets of cards of the same value
 * with one set have 3 cards.
 */
int is_fullhouse (hand_t hand) {
    if (!is_threeofakind(hand)) return 0;
    if (!is_twopairs(hand)) return 0;
    return 1;
}

/* checks if all cards in the hand are of the same suit
 */
int is_flush (hand_t hand) {
    int i;
    for (i=1; i<5; i++) {
        if (hand[i].suit != hand[0].suit) return 0;
    }
    return 1;
}

/* checks if the hand is both a flush and straight
 * IMPORTANT: this method will sort the hand as a side effect
 */
int is_straightflush (hand_t hand) {
    if (!is_flush(hand)) return 0;
    if (!is_straight(hand)) return 0;
    return 1;
}

/* checks if the hand contains 4 cards (or more) of the same value.
 * "or more" may be impossible in a normal hand but will still be counted.
 */
int is_fourofakind (hand_t hand) {
    return is_xofakind(hand, 4);
}

/* checks if the hand is straight and ten low. T,J,Q,K,A only!
 * note: A,2,3,4,5 is technically straight and ace high
 */
int is_royalflush (hand_t hand) {
    if (!is_straightflush(hand)) return 0;
    // if straight flush then is_straight() returned and hand is sorted
    if (hand[0].value != 10) return 0; // A,2,3,4,5 doesn't count
    return 1;
}

/* compares the hands based on rank -- if the ranks (and rank values) are
 * identical, compares the hands based on their highcards.
 * returns 0 if h1 > h2, 1 if h2 > h1.
 */
int compare_hands (hand_t h1, hand_t h2) {
    static int (*check[9])(hand_t) = 
        {is_royalflush, is_straightflush, is_fourofakind,
        is_fullhouse, is_flush, is_straight, 
        is_threeofakind, is_twopairs, is_onepair};
    int i;
    int h1rv, h2rv; // temporary rank values
    for (i=0; i<9; i++) {
        // First check, is_royalflush(), will sort the hands
        // from here on, assume sorted
        if (check[i](h1)) {
        if (check[i](h2)) {
            switch(i) {

            // Royal Flush
            case 1: break; // This should be a tie but instead it gets
                           // passed off to compare_highcards and will
                           // eventually be resolved by suit (greater ASCII value)

            // Straight Flush or Straight
            case 2:
            case 6: 
                // compare low to avoid A,2,3,4,5 winning when it shouldn't
                if (h2[0].value > h1[0].value) return 1;
                return 0;

            // Four of a Kind
            case 3:
                // is_fourofakind() returns the card value that met the condition
                h1rv = is_fourofakind(h1);
                h2rv = is_fourofakind(h2);
                if (h2rv > h1rv) return 1;
                if (h2rv < h1rv) return 0;
                break; // compare_highcards

            // Full House or Three of a Kind
            case 4:
            case 7:
                // is_threeofakind() returns the card value that met the condition
                h1rv = is_threeofakind(h1);
                h2rv = is_threeofakind(h2);
                if (h2rv > h1rv) return 1;
                if (h2rv < h1rv) return 0;
                break; // break passes off to compare_highcards 
                       // which will handle the other pair correctly    
            
            // Flush
            case 5:
                break; // compare_highcards
            
            // Two Pair
            case 8:
                // is_xofakind returns the card value of the first group encountered
                // is_xofakindrev does the same thing but checks in reverse
                // by this point in the code h1 and h2 are sorted, thus:
                // is_xofakind returns the low pair
                // is_xofakindrev returns the high pair
                
                h1rv = is_xofakindrev(h1, 2);
                h2rv = is_xofakindrev(h2, 2);
                if (h2rv > h1rv) return 1;
                if (h2rv < h1rv) return 0;
                
                h1rv = is_xofakind(h1, 2);
                h2rv = is_xofakind(h2, 2);
                if (h2rv > h1rv) return 1;
                if (h2rv < h1rv) return 0;
                
                break; // compare_highcards

            // One Pair
            case 9:
                // is_twoofakind() returns the card value that met the condition
                h1rv = is_onepair(h1);
                h2rv = is_onepair(h2);
                if (h2rv > h1rv) return 1;
                if (h2rv < h1rv) return 0;
                break; // compare_highcards

            }
            return compare_highcards(h1, h2);
            } else {
                return 0;
            }
        } else if (check[i](h2)) return 1;
    }
    return compare_highcards(h1, h2);
}

/* compares the hands based solely on their highcard values (ignoring rank). if
 * the highcards are a draw, compare the next set of highcards, and so forth.
 */
int compare_highcards (hand_t h1, hand_t h2) {
    if (!is_sorted(h1)) sort_hand(h1);
    if (!is_sorted(h2)) sort_hand(h2);
    int i;
    for (i=4; i>=0; i--) {
        if (h2[i].value > h1[i].value) return 1;
        if (h2[i].value < h1[i].value) return 0;
    }
    if (h2[i].suit > h1[i].suit) return 1;
    return 0;
}
