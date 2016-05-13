#include <stdlib.h>
#include <stdio.h>
#include "cache.h"

/**
 * PRIVATE: Creates a doubly linked list assuming a sentinel at <*set>
 * and a number of elements equal to <lines>. The elements are initialized
 * to invalid and all elements and the sentinel are linked appropriately.
 */
void init_set(cache_line_t *set, long lines) {
    set->prev = set + lines; // set prev = last element
    set->prev->next = set;   // last element next = set
    set->prev->valid = 0;

    cache_line_t *tmp1, *tmp2;
    long i;
    for (i = 0; i < lines; i++) {
        tmp1 = set + i;
        tmp2 = set + (i+1);
        tmp1->next = tmp2;
        tmp2->prev = tmp1;
        tmp2->valid = 0;
    }
}

/**
 * PRIVATE: Finds the tag in the given cache set and returns 
 * its index or -1 if the tag is not found before the first 
 * invalid line. Note: all valid lines should be at the front, 
 * so an invalid line marks the "end" of the list.
 */
long cache_set_indexof(cache_line_t *set, long tag) {
    long i = 0;
    cache_line_t *on = set->next;
    while (on != set) {
        if (!on->valid) return -1;
        if (on->tag == tag) return i;
        on = on->next;
        i++;
    }
    return -1;
}

/*
long cache_prlong(cache_line_t *set) {
    long i = 0;
    cache_line_t *on = set->next;
    while (on != set) {
        prlongf("%d: %d: tag=%d valid=%d\n", on, i, on->tag, on->valid);
        on = on->next;
        i++;
    }
    return -1;
}
*/

/**
 * PRIVATE: Re-links the linked list whos sentinel is found at <*set>
 * such that the line found at <*line> is now at the front.
 */
void cache_set_promote(cache_line_t *set, cache_line_t *line) {
    if (set->next == line) return; // Short cut if already at front.
    
    // Remove line
    line->prev->next = line->next;
    line->next->prev = line->prev;

    // Add line to start
    line->prev = set;
    line->next = set->next;
    set->next->prev = line;
    set->next = line;
}

/**
 * PRIVATE: Returns the i'th element in a set.
 * Invalid indicies can expect strange return values (no checking)
 */
cache_line_t *cache_set_get(cache_line_t *set, long i) {
    cache_line_t *on = set->next;
    long j;
    for (j = 0; j < i; j++) {
        on = on->next;
    }
    return on;
}

/**
 * PRIVATE: Returns the i'th set of the given cache
 */
cache_line_t *cache_get_set(cache_t *cache, long i) {
    return cache->sets + (1 + cache->lines_per_set)*i;
}

/** 
 * Constructs a new cache with the parameters given.
 *
 *  total_lines    : Number of cache lines
 *  lines_per_set  : Number of lines in each set (cache associativity)
 *  bytes_per_line : Number of bytes in a block (1 block per line)
 *
 * Notes:
 * - Total lines should be evenly divisible by lines per set.
 * - Bytes per line should be a power of 2.
 */
cache_t *cache_make(long total_lines, long lines_per_set, long bytes_per_line) {

    long num_sets = (total_lines + (lines_per_set-1)) / lines_per_set;
    long set_size = (1 + lines_per_set) * sizeof(cache_line_t);

    // Allocate all in one go. (groups memory together)
    // Only possible for statically sized data structures
    cache_t *cache = malloc(sizeof(cache_t) + num_sets*set_size);

    cache->num_sets = num_sets; 
    cache->set_size = set_size;
    cache->sets = (cache_line_t *)((char*)cache + sizeof(cache_t));

    cache->total_lines = total_lines;
    cache->lines_per_set = lines_per_set;
    cache->bytes_per_line = bytes_per_line;

    long s;
    cache_line_t *set;
    for (s = 0; s < num_sets; s++) {
       set = cache_get_set(cache, s);
       init_set(set, lines_per_set);
    }

    cache->tag_mask = ~(bytes_per_line - 1);

    return cache;
}

void cache_free(cache_t *cache) {
    free(cache); // Nice side-effect of forcing one malloc
}

/**
 * Simulates a cache read of the given byte address
 * Returns 1 if hit, 0 if miss. Cache is updated to
 * include the address specified, evicting the 
 * Least Recently Used cache line.
 */
char cache_sim_read(cache_t *cache, long address) {
    long block = address / cache->bytes_per_line;
    long set_id = block % cache->num_sets;
    long tag = cache->tag_mask & block;

    cache_line_t *set = cache_get_set(cache, set_id);
    long index = cache_set_indexof(set, tag);

    cache_line_t *line = 0;
    if (index == -1) {
        line = set->prev; // Set is a sentinel, set->prev is last element.
        line->valid = 1;  // Mark as valid (in case old node was invalid)
        line->tag = tag;
        cache_set_promote(set, line);
        return 0;
    } else {
        line = cache_set_get(set, index); // Memory is laid out such that this works
        cache_set_promote(set, line);
        return 1;
    }
}

