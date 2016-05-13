typedef struct cache cache_t;
typedef struct cache_line cache_line_t;

struct cache_line {

    /* Cache lines form a doubly linked list with newer (more recently used)
     * entries in front and old (most time unused) entries in back. 
     * I chose this because it allows a cache hit to update LRU in constant 
     * time and finish the linear search early (instead of updating all ages).
     * 
     * NOTE: Can run set size of 16,384 in ~12 seconds.
     * Hit rate 97.81% | Miss rate 2.19% (Cannot verify:
     * Web site failed to respond with set size of 256.)
     */
    cache_line_t *prev;
    cache_line_t *next;

    /* Boolean value of entry validity.
     */
    char valid;

    /* The address tag. (Upper bits of address, not including byte index)
     */
    long tag;
};

struct cache {
    cache_line_t *sets; // Array of cache line sentinels
    long num_sets;       // Length of array (number of sets)
    long set_size;       // Stride of array (size of a set in bytes);

    long total_lines; 
    long lines_per_set;
    long bytes_per_line;
    long tag_mask;       // Bitwise & with address block to get tag.
};

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
cache_t *cache_make(long num_lines, long lines_per_set, long bytes_per_block);

/**
 * Frees the memory of the cache
 */
void cache_free(cache_t *cache);

/**
 * Simulates a cache read of the given byte address
 * Returns 1 if hit, 0 if miss. Cache is updated to
 * include the address specified, evicting the 
 * Least Recently Used cache line.
 */
char cache_sim_read(cache_t *cache, long address);

