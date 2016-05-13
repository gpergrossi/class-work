#ifndef GRAPH_H
#define GRAPH_H 1

/* forward declarations so self-referential structures are simpler */
typedef struct graph_vtx graph_vtx_t;
typedef struct graph_adj graph_adj_t;

struct graph_vtx {
	char *name;
	graph_adj_t *adj_list;
	graph_vtx_t *next;
};

struct graph_adj {
	int edge_weight;
	graph_vtx_t *vertex;
	graph_adj_t *next;	
};

/* Adds the specified edge to the graph. If either of the edge's vertices 
 * are not already in the graph, they are added. The vertices will then be
 * connected so that v1 is adjacent to v2 and visa versa. If the graph
 * is currently empty (i.e., *vtxhead == NULL), a new graph is created,
 * and the caller's vtxhead pointer is modified. 
 *
 * `graph`  : the pointer to the graph (more specifically, the head of the
 *            list of vertex_t structures)
 * `v1_name`: the name of the first vertex of the edge to add
 * `v2_name`: the name of the second vertex of the edge to add
 * `weight` : the weight of the edge to add
 */
void graph_add_edge (graph_vtx_t **graph, char *v1_name, 
                     char *v2_name, int weight);

/* Searches for a vertex by name or creates it if needed.
 * This is the only method to add a vertex because the API does
 * not allow two vertices to have the same name.
 *
 * `graph`: graph to search in or add to
 * `name` : name of the desired vertex
 *
 * returns vertex (no way to tell if it had to be created)
 */
graph_vtx_t *graph_touch_vertex (graph_vtx_t **graph, char *name);

/* Searches the graph for a vertex with a matching name.
 *
 * `graph`: graph to search in or add to
 * `name` : name of the desired vertex
 *
 * returns vertex if in graph, else NULL
 */ 
graph_vtx_t *graph_find_vertex (graph_vtx_t **graph, char *name);

/* Connects the given vertices with an undirected edge of the given weight.
 * Specifically, each vertex is added to the other's adjacency list.
 *
 * This API allows multi-graphs and will not check for pre-existing
 * connections. Use graph_disconnect() to sever previous connections.
 *
 * `v1`/`v2`: the verticies that will be connected
 * `weight` : weight of the connection.
 *
 * Note: a vertex can be made to point to itself using this method, however
 * graph_direct() would be better as graph_connect would add two connections.
 *
 * Use graph_find_vertex() or graph_touch_vertex() 
 * to get the necessary pointers.
 */
void graph_connect (graph_vtx_t *v1, graph_vtx_t *v2, int weight);

/* Connects the given vertices with a directed edge of the given weight.
 * Specifically, point_to is added to vtx's adjacency list.
 *
 * This API allows multi-graphs and will not check for pre-existing
 * connections. Use graph_disconnect() to sever previous connections.
 *
 * `vertex`  : the vertex that will have its adjacency list changed
 * `point_to`: the vertex that will be added to `vtx`'s adjacency list
 * `weight`  : weight of the connection
 *
 * Note: a vertex can be made to point to itself using this method.
 *
 * Use graph_find_vertex() or graph_touch_vertex() to get the necessary 
 * pointers. (Vertices are resolved by pointer not by name.)
 */
void graph_direct (graph_vtx_t *vertex, graph_vtx_t *point_to, int weight);

/* Removes all connections between the given vertices
 *
 * Use graph_find_vertex() or graph_touch_vertex() to get the necessary 
 * pointers. (Vertices are resolved by pointer not by name.)
 */
void graph_disconnect(graph_vtx_t *v1, graph_vtx_t *v2);

/* Removes all connections from one vertex pointing to the other.
 *
 * `vertex`  : Vertex that will have its adjacency list changed
 * `point_to`: Vertex that will be removed from the other's adjacency list
 * 
 * Use graph_find_vertex() or graph_touch_vertex() to get the necessary 
 * pointers. (Vertices are resolved by pointer not by name.)
 */
void graph_disdirect(graph_vtx_t *vertex, graph_vtx_t *point_to);

/* Removes the given vertex and all of it's connections to other
 * vertices from the graph. Free's the vertex that was removed.
 *
 * Use graph_find_vertex() or graph_touch_vertex() to get the necessary 
 * pointers. (Vertices are resolved by pointer not by name.)
 */
void graph_remove_vertex (graph_vtx_t **graph, graph_vtx_t *vtx);

/* Locates the n'th tour of the graph (indexed from 0). 
 * Tour order is arbitrary but will not change unless the graph being 
 *   toured is changed.
 *
 * If the n'th tour does not exist, tour will be left empty. 
 *
 * Returns the number of tours discovered (usually n, unless the
 *   graph contains fewer than n tours. Can be used to count tours).
 *
 * Errors will return -1 and tour will be left unchanged.
 *   - tour must be an empty graph (e.g. ptr to ptr to NULL)
 *   - graph must be a graph with at least one vertex.
 *   - n must be 0 or greater
 *
 * `tour` : pointer to an empty graph that will receive the tour output
 * `graph`: pointer to a full graph that will be searched for tours
 * `n`    : the index of the path to look for
 *
 * if return == n then the tour returned is the n'th tour and the tour pointer
 * will point to a graph including each step of the tour singly linked in order.
 */
int graph_find_tour (graph_vtx_t **tour, graph_vtx_t **graph, int n);

/* Prints a summary of the graph
 */
void graph_print_adjacencies(graph_vtx_t **graph);

/* Prints the name of each vertex in the graph all on the
 * same line seperated by spaces.
 */
void graph_print_vertices(graph_vtx_t **graph);

/* Adds up the edge weights of the entire graph.
 * Corresponds to the length of a tour.
 */
int graph_sum_weight(graph_vtx_t **tour);

/* Returns count of calls to malloc that have not been
 * countered with a call to free.
 */
int graph_get_allocs();

/* Frees the entire graph and sets the graph pointer to NULL.
 */
void graph_free (graph_vtx_t **graph);

#endif // ifdef GRAPH_H
