#include <string.h>
#include "CuTest.h"
#include "poker.h"

/* Test hands */

const char *test_hand_1_str = "5C 3D TS AD 2H";
card_t test_hand_1[] = {{  5, CLUB    },
                        {  3, DIAMOND },
                        { 10, SPADE   },
                        { 14, DIAMOND },
                        {  2, HEART   }};

const char *test_hand_2_str = "2D 4S 3H 5C 6C";
card_t test_hand_2[] = {{  2, DIAMOND },
                        {  4, SPADE   },
                        {  3, HEART   },
                        {  5, CLUB    },
                        {  6, CLUB    }};

const char *test_hand_3_str = "6H 4H 3H 2H 5H";
card_t test_hand_3[] = {{  6, HEART   },
                        {  4, HEART   },
                        {  3, HEART   },
                        {  2, HEART   },
                        {  5, HEART   }};

const char *test_hand_4_str = "2D 3H 4S 3C 2C";
card_t test_hand_4[] = {{  2, DIAMOND },
                        {  3, HEART   },
                        {  4, SPADE   },
                        {  3, CLUB    },
                        {  2, CLUB    }};

const char *test_hand_5_str = "2D AH 2S AC 2C";
card_t test_hand_5[] = {{  2, DIAMOND },
                        { 14, HEART   },
                        {  2, SPADE   },
                        { 14, CLUB    },
                        {  2, CLUB    }};

const char *test_hand_6_str = "2D 2H 2S 2C 7C";
card_t test_hand_6[] = {{  2, DIAMOND },
                        {  2, HEART   },
                        {  2, SPADE   },
                        {  2, CLUB    },
                        {  7, CLUB    }};

const char *test_hand_7_str = "TD JD QD KD AD";
card_t test_hand_7[] = {{ 10, DIAMOND },
                        { 11, DIAMOND },
                        { 12, DIAMOND },
                        { 13, DIAMOND },
                        { 14, DIAMOND }};

const char *test_hand_8_str = "3H 5C 2D AD 4C";
card_t test_hand_8[] = {{  3, HEART   },
                        {  5, CLUB    },
                        {  2, DIAMOND },
                        { 14, DIAMOND },
                        {  4, CLUB    }};

const char *test_hand_9_str = "3H 4C 3S 5D 3D";
card_t test_hand_9[] = {{  3, HEART   },
                        {  4, CLUB    },
                        {  3, SPADE   },
                        {  5, DIAMOND },
                        {  3, DIAMOND }};

/****************************** Begin unit tests ******************************/

void test_hand_to_string (CuTest *tc) {
    char buf[30];
    hand_to_string(test_hand_1, buf);
    CuAssertStrEquals(tc, test_hand_1_str, buf);
    hand_to_string(test_hand_2, buf);
    CuAssertStrEquals(tc, test_hand_2_str, buf);
}

void test_string_to_hand (CuTest *tc) {
    char buf[30];
    card_t hand[5];
    string_to_hand(test_hand_1_str, hand);
    hand_to_string(hand, buf);
    CuAssertStrEquals(tc, test_hand_1_str, buf);
    string_to_hand(test_hand_2_str, hand);
    hand_to_string(hand, buf);
    CuAssertStrEquals(tc, test_hand_2_str, buf);
}

void test_sort_hand (CuTest *tc) {
    char buf[30];
    card_t tmp_hand[5];
    
    memcpy(tmp_hand, test_hand_1, 5*sizeof(card_t));
    sort_hand(tmp_hand);
    hand_to_string(tmp_hand, buf);
    CuAssertStrEquals(tc, "2H 3D 5C TS AD", buf);
    
    memcpy(tmp_hand, test_hand_2, 5*sizeof(card_t));
    sort_hand(tmp_hand);
    hand_to_string(tmp_hand, buf);
    CuAssertStrEquals(tc, "2D 3H 4S 5C 6C", buf);
}

void test_is_onepair (CuTest *tc) {
    CuAssertTrue(tc, !is_onepair(test_hand_1));
    CuAssertTrue(tc, !is_onepair(test_hand_2));
    CuAssertTrue(tc, !is_onepair(test_hand_3));
    CuAssertTrue(tc, is_onepair(test_hand_4));
    CuAssertTrue(tc, is_onepair(test_hand_5));
    CuAssertTrue(tc, is_onepair(test_hand_6));
}

void test_is_twopairs (CuTest *tc) {
    CuAssertTrue(tc, !is_twopairs(test_hand_2));
    CuAssertTrue(tc, !is_twopairs(test_hand_3));
    CuAssertTrue(tc, is_twopairs(test_hand_4));
}

void test_is_threeofakind (CuTest *tc) {
    CuAssertTrue(tc, !is_threeofakind(test_hand_3));
    CuAssertTrue(tc, !is_threeofakind(test_hand_4));
    CuAssertTrue(tc, is_threeofakind(test_hand_5));
    CuAssertTrue(tc, is_threeofakind(test_hand_9));
}

void test_is_straight (CuTest *tc) {
    CuAssertTrue(tc, !is_straight(test_hand_1));
    CuAssertTrue(tc, !is_straight(test_hand_5));
    CuAssertTrue(tc, is_straight(test_hand_2));
    CuAssertTrue(tc, is_straight(test_hand_3));
    CuAssertTrue(tc, is_straight(test_hand_7));
    CuAssertTrue(tc, is_straight(test_hand_8));
}

void test_is_fullhouse (CuTest *tc) {
    CuAssertTrue(tc, !is_fullhouse(test_hand_4));
    CuAssertTrue(tc, !is_fullhouse(test_hand_6));
    CuAssertTrue(tc, !is_fullhouse(test_hand_9));
    CuAssertTrue(tc, is_fullhouse(test_hand_5));
}

void test_is_flush (CuTest *tc) {
    CuAssertTrue(tc, !is_flush(test_hand_1));
    CuAssertTrue(tc, !is_flush(test_hand_6));
    CuAssertTrue(tc, is_flush(test_hand_3));
    CuAssertTrue(tc, is_flush(test_hand_7));
}

void test_is_straightflush (CuTest *tc) {
    CuAssertTrue(tc, !is_straightflush(test_hand_2));
    CuAssertTrue(tc, !is_straightflush(test_hand_4));
    CuAssertTrue(tc, is_straightflush(test_hand_3));
    CuAssertTrue(tc, is_straightflush(test_hand_7));
}

void test_is_fourofakind (CuTest *tc) {
    CuAssertTrue(tc, !is_fourofakind(test_hand_1));
    CuAssertTrue(tc, !is_fourofakind(test_hand_5));
    CuAssertTrue(tc, !is_fourofakind(test_hand_9));
    CuAssertTrue(tc, is_fourofakind(test_hand_6));
}

void test_is_royalflush (CuTest *tc) {
    CuAssertTrue(tc, !is_royalflush(test_hand_2));
    CuAssertTrue(tc, !is_royalflush(test_hand_3));
    CuAssertTrue(tc, is_royalflush(test_hand_7));
}

void test_compare_hands (CuTest *tc) {
    CuAssertIntEquals(tc, 1, compare_hands(test_hand_5, test_hand_6));
    CuAssertIntEquals(tc, 1, compare_hands(test_hand_2, test_hand_3));
    CuAssertIntEquals(tc, 0, compare_hands(test_hand_9, test_hand_4));
    CuAssertIntEquals(tc, 0, compare_hands(test_hand_7, test_hand_3));
}

void test_compare_highcards (CuTest *tc) {
    CuAssertIntEquals(tc, 0, compare_highcards(test_hand_5, test_hand_7));
    CuAssertIntEquals(tc, 1, compare_highcards(test_hand_2, test_hand_6));
    CuAssertIntEquals(tc, 0, compare_highcards(test_hand_7, test_hand_8));
}
