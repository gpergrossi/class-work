#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "graph.h"

// Define function namespace, all public functions are formed as
// graph_<function name>(). These save space in implementation.
//
// While this practice is weird it has been wonderful writing
// the shorthand in this file without worrying about namespace
// clashes (although for this project those are not likely to
// be an issue). It also acts as a sort of table of contents.

#define vtx_t graph_vtx_t
#define adj_t graph_adj_t
#define add_edge graph_add_edge
#define find_vertex graph_find_vertex
#define touch_vertex graph_touch_vertex
#define remove_vertex graph_remove_vertex
#define connect graph_connect
#define direct graph_direct
#define disconnect graph_disconnect
#define disdirect graph_disdirect
#define find_tour graph_find_tour
#define print_adjacencies graph_print_adjacencies
#define print_vertices graph_print_vertices
#define sum_weight graph_sum_weight
#define get_allocs graph_get_allocs

int graph_allocs = 0;

//=================================================================
//==== PRIVATE FUNCTIONS FOLLOW ==== SEARCH 'PUBLIC' TO SKIP ======
//=================================================================

/* PRIVATE: Track memory usage
 */
void *std_malloc (size_t size) {
    void *ptr = malloc(size);
    graph_allocs = graph_allocs + 1;
    //printf("Allocated %zu bytes at %p.\n", size, ptr);
    return ptr;
}
void std_free(void *ptr) {
    graph_allocs = graph_allocs - 1;
    free(ptr);
}

/* PRIVATE: Adds a new vertex to the head of the graph and 
 * returns that new vertex.
 */
vtx_t *add_vertex (vtx_t **graph, char *name) {
    // Handle NULL graphs
    if (graph == NULL) return NULL;

    // Safe string copy, names must be 20 characters or less
    vtx_t *new_vtx = std_malloc(sizeof(vtx_t)); 
    int len = strnlen(name, 20) + 1;
    char *new_str = std_malloc(len);
    strncpy(new_str, name, len-1);
    new_str[len-1] = 0;

    new_vtx->name = new_str;
    new_vtx->adj_list = NULL;

    if (graph != NULL) {
        new_vtx->next = *graph;
    } else {
        new_vtx->next = NULL;
    }
    *graph = new_vtx;
    return new_vtx;
}


/* Removes the given vertex from the given adjacency list,
 * frees the relevant adjacency entries and returns the 
 * modified adjacency list.
 */
adj_t *remove_adj (adj_t *adj_list, vtx_t *vtx) {
    if (adj_list == NULL) return NULL;
    if (adj_list->vertex == vtx) {
        adj_t *next = adj_list->next;
        std_free(adj_list);
        return remove_adj(next, vtx);
    }
    adj_list->next = remove_adj(adj_list->next, vtx);
    return adj_list;
}


/* Removes vtx from the graph represented by the head vertex given. 
 * Returns the new vertex list of the graph. Does not free the vertex
 * as this would be difficult. Freeing is done by remove_vertex().
 */
vtx_t *remove_vertex_internal (vtx_t *graph,  vtx_t *vtx) {
    if (graph == NULL) return NULL;
    if (graph == vtx) return remove_vertex_internal(graph->next, vtx);
    graph->next = remove_vertex_internal(graph->next, vtx);
    graph->adj_list = remove_adj(graph->adj_list, vtx);
    return graph;
}


/* PRIVATE: Removes the first vertex of the graph, which is assumed
 * to be a tour graph. It's adjacency is removed from the second
 * vertex and the rest of the graph is returned.
 */
void tour_remove_head(vtx_t **tour) {
    vtx_t *head = *tour;
    vtx_t *next = head->next;
    if (head->adj_list != NULL) std_free(head->adj_list);
    std_free(head->name);
    std_free(head);
    *tour = next;
}


/* PRIVATE: Adds a new vertex to the head of the graph and connects
 * it to the previous head using connect().
 */
void tour_connect_head(vtx_t **tour, char *name, int weight) {
    vtx_t *fst = add_vertex(tour, name);
    vtx_t *snd = fst->next;
    if (snd == NULL) return;
    direct(fst, snd, weight);
}


/* PRIVATE: Returns true if all vertices in the graph are included 
 * in the tour (by name). Else, returns false.
 */
int is_tour_done (vtx_t **tour, vtx_t **graph) {
    vtx_t *on;
    for (on = *graph; on != NULL; on = on->next) {
        if (find_vertex(tour, on->name) == NULL) return 0;
    }
    return 1;
}


/* PRIVATE: Searches tours
 * Returns number of valid endings to the tour less or equal to n.
 */
int find_tour_internal (vtx_t **tour, vtx_t **graph, int n) {
    // Is tour finished?
    if (is_tour_done(tour, graph)) return 1; // One tour
   
    // Prepare to search
    vtx_t *tour_vtx = find_vertex(graph, (*tour)->name);
    adj_t *on; 
    vtx_t *match;
    int num = 0; // number of tours found so far
    
    // Search adjacencies
    for (on = tour_vtx->adj_list; on != NULL; on = on->next) {
        match = find_vertex(tour, on->vertex->name);
        // adjacent vertex not yet toured
        if (match == NULL) {
            tour_connect_head(tour, on->vertex->name, on->edge_weight);
            num = num + find_tour_internal(tour, graph, n-num);
            if (num == n) return num;
            tour_remove_head(tour);
        }
    }

    // Note, returning from here means the tour hasn't changed.
    return num;
}


/* PRIVATE: Frees the entire adjacency list, does not remove connections
 * in the correct way, just frees the given adjacency list.
 */
void free_internal_adj(adj_t *adj_list) {
    if (adj_list == NULL) return;
    free_internal_adj(adj_list->next);
    std_free(adj_list);
}


/* PRIVATE: Frees the entire graph recursively from the given vertex
 */
void free_internal(vtx_t *vertex) {
    if (vertex == NULL) return;
    free_internal(vertex->next);
    free_internal_adj(vertex->adj_list);
    std_free(vertex->name);
    std_free(vertex);
}

// =========================================================================
// ==== END OF PRIVATE FUNCTIONS ===========================================
// =========================================================================
// PUBLIC


/* Adds an edge to the graph
 */
void add_edge (vtx_t **graph, char *v1_name, char *v2_name, int weight) {
    // Get verticies if they exist, or create them (NULL graph safe)
    vtx_t *v1 = touch_vertex(graph, v1_name);
    vtx_t *v2 = touch_vertex(graph, v2_name);
    
    connect(v1, v2, weight);
}


/* Finds a vertex in the graph with the given name and returns
 * a pointer to that vertex. If no such vertex exists, returns NULL.
 */
vtx_t *find_vertex (vtx_t **graph, char *name) {
    if (graph == NULL) return NULL;
    vtx_t *at;
    for (at = *graph; at != NULL; at = at->next) {
        if (strncmp(at->name, name, 20) == 0) {
            return at;
        }
    }
    return NULL;
}


/* Searches for and returns a pointer to a vertex if it exists. Else,
 * adds a new vertex to the head of the graph and returns that new vertex.
 */
vtx_t *touch_vertex (vtx_t **graph, char *name) {
    // Handle NULL graphs
    if (graph == NULL) return NULL;
    if (*graph == NULL) {
        return add_vertex(graph, name);
    }

    // Return vertex if it exists
    vtx_t *search = find_vertex(graph, name);
    if (search != NULL) return search;

    // Else, return new vertex
    return add_vertex(graph, name);
}


/* Removes the given vertex and all of it's connections
 * to other vertices in the graph. Free's the vertex that
 * was removed.
 */
void remove_vertex (vtx_t **graph, vtx_t *vtx) {
    if (graph == NULL) return;
    if (vtx == NULL) return;
    *graph = remove_vertex_internal(*graph, vtx);
    std_free(vtx);
}


/* Adds an edge with the given weight between two vertices (undirected)
 * each vertex points to the other.
 */
void connect (vtx_t *v1, vtx_t *v2, int weight) {
    if (v1 == NULL || v2 == NULL) return;

    // Create v1 adjacency definition
    adj_t *v1_adj = std_malloc(sizeof(adj_t));
    v1_adj->vertex = v1;
    v1_adj->edge_weight = weight;

    // Add v1 adjacency to v2's adjacency list
    v1_adj->next = v2->adj_list;
    v2->adj_list = v1_adj;

    // Create v2 adjacency definition
    adj_t *v2_adj = std_malloc(sizeof(adj_t));
    v2_adj->vertex = v2;
    v2_adj->edge_weight = weight;

    // Add v2 adjacency to v1's adjacency list
    v2_adj->next = v1->adj_list;
    v1->adj_list = v2_adj;
}


/* Adds an edge with the given weight between two vertices (directed)
 */
void direct (vtx_t *vertex, vtx_t *point_to, int weight) {
    if (vertex == NULL || point_to == NULL) return;

    // Create vertex adjacency definition
    adj_t *adj = std_malloc(sizeof(adj_t));
    adj->vertex = point_to;
    adj->edge_weight = weight;

    // Add adjacency to point-to's adjacency list
    adj->next = vertex->adj_list;
    vertex->adj_list = adj;
}


/* Removes all connections between the given vertices
 */
void disconnect(vtx_t *v1, vtx_t *v2) {
    if (v1 == NULL || v2 == NULL) return;
    v1->adj_list = remove_adj(v1->adj_list, v2);
    v2->adj_list = remove_adj(v2->adj_list, v1);
}


/* Removes all connections pointing from `vertex` to `point_to`
 */
void disdirect(vtx_t *vertex, vtx_t *point_to) {
    if (vertex == NULL || point_to == NULL) return;
    vertex->adj_list = remove_adj(vertex->adj_list, point_to);
}


/* Locates the n'th tour of the graph (indexed from 0). 
 * Tour order is arbitrary but will not change unless 
 *   the graph being toured changes.
 *
 * If the n'th tour does not exist, tour will be last tour found. 
 * If no tours exist, tour will be pointer to pointer to NULL.
 *
 * Returns the number of tours discovered (usually n, unless the
 *   graph contains fewer than n tours. Can be used to count tours).
 *
 * Errors will return -1 and tour will be left unchanged.
 *   - tour must be an empty graph (e.g. ptr to ptr to NULL)
 *   - graph must be a graph with at least one vertex.
 *   - n must be 0 or greater
 */
int find_tour(vtx_t **tour, vtx_t **graph, int n) {
    if (tour == NULL || graph == NULL || n < 0) return -1;
    if (*tour != NULL) return -1;
    if (*graph == NULL) return -1;
    
    int num = 0;
    vtx_t *vtx;
    for (vtx = *graph; vtx != NULL; vtx = vtx->next) {
        // Start tour from here
        tour_connect_head(tour, vtx->name, 0);
        num = num + find_tour_internal(tour, graph, n-num);
        if (num == n) return num; // Nth tour located.
        tour_remove_head(tour);
    }
    
    // Note, returning from here means tour is empty.
    return num;
}

/* Prints a summary of the graph
 */
void print_adjacencies(vtx_t **graph) {
    printf("Adjacency list:\n");
    vtx_t *vert;
    adj_t *adj;
    for (vert = *graph; vert != NULL; vert = vert->next) {
        printf("  %s: ", vert->name);
        for (adj = vert->adj_list; adj != NULL; adj = adj->next) {
            printf("%s(%d) ", adj->vertex->name, adj->edge_weight);
        }
        printf("\n");
    }   
}

/* Prints the name of each vertex in the graph all on the
 * same line seperated by spaces.
 */
void print_vertices(vtx_t **graph) {
    if (graph == NULL) return;
    vtx_t *vtx;
    for (vtx = *graph; vtx != NULL; vtx = vtx->next) {
        printf("%s ", vtx->name);
    }
}

/* Adds up the edge weights of the entire graph.
 * Corresponds to twice the length of a tour.
 */
int sum_weight(vtx_t **tour) {
    if (tour == NULL) return -1;
    int weight = 0;
    vtx_t *vtx;
    adj_t *adj;
    for (vtx = *tour; vtx != NULL; vtx = vtx->next) {
        for (adj = vtx->adj_list; adj != NULL; adj = adj->next) {
            weight = weight + adj->edge_weight;
        }
    }
    return weight;
}

/* Returns the difference between malloc and free calls.
 * Test for memory leaks.
 */
int get_allocs() {
    return graph_allocs;
}

/* Frees the entire graph and sets the graph pointer to NULL.
 */
void graph_free (vtx_t **graph) {
    if (graph == NULL) return;
    free_internal(*graph);
    *graph = NULL;
}

