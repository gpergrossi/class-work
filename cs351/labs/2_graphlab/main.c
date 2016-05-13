#ifndef NULL
#define NULL 0
#endif

#include <stdlib.h>
#include <stdio.h>
#include "graph.h"

int main (int argc, char *argv[]) {
    
    // Check arguments
    if ((argc-1) % 3 != 0) {
        printf("Arguments should be in sets of 3!\n");
        return 1;
    }
    printf("\n"); // Seperates input from output for aesthetic

    // Feed arguments to graph
    graph_vtx_t *vtxhead = 0;
    graph_vtx_t **graph = &vtxhead;
    int i;
    for (i=1; i<argc; i+=3) {
        graph_add_edge(graph, argv[i], argv[i+1], atoi(argv[i+2]));
    }
    
    // Print adjacency list
    graph_print_adjacencies(graph);
    printf("\n");

    // Count number of tours
    graph_vtx_t *tourhead = 0;
    graph_vtx_t **tour = &tourhead;
    int max = 10000;
    int count = graph_find_tour(tour, graph, max);
    if (count == 0) {
        printf("No tours found.\n");
    } else {
        if (count == 1) {
            printf("1 tour found.\n");
        } else {
            if (count == max) {
                printf("%i+ tours found.\n", max);
            } else {
                printf("%i tours found.\n", count);
            }
        }
    }
    graph_free(tour);
    
    if(count > 0) {
        // List tour path for first tour
        printf("Tour #1:\n");
        graph_find_tour(tour, graph, 1);
        printf("  Path: ");
        graph_print_vertices(tour);
        printf("\n");

        // Print tour length
        int length = graph_sum_weight(tour);
        printf("  Length: %i\n", length);
        if(count > 1) printf("...\n");
    }

    printf("\n");

    // Free used memory
    graph_free(tour);
    graph_free(graph);
    printf("Unfreed allocations: %i\n", graph_get_allocs());
    return 0;

    /* 
	// Programatically constructing the following simple graph:
	//
	//     10         5
	// A <-----> B <-----> C
	//
	// Delete this code and add your own!

    vertex_t *v1, *v2, *v3, *vlist_head, *vp;
	adj_vertex_t *adj_v;

	vlist_head = v1 = malloc(sizeof(vertex_t));
	v1->name = "A";
	v2 = malloc(sizeof(vertex_t));
	v2->name = "B";
	v3 = malloc(sizeof(vertex_t));
	v3->name = "C";

	v1->next = v2;
	v2->next = v3;
	v3->next = NULL;

	adj_v = v1->adj_list = malloc(sizeof(adj_vertex_t));
	adj_v->vertex = v2;
	adj_v->edge_weight = 10;
	adj_v->next = NULL;

	adj_v = v2->adj_list = malloc(sizeof(adj_vertex_t));
	adj_v->vertex = v1;
	adj_v->edge_weight = 10;
	adj_v = adj_v->next = malloc(sizeof(adj_vertex_t));
	adj_v->vertex = v3;
	adj_v->edge_weight = 5;
	adj_v->next = NULL;

	adj_v = v3->adj_list = malloc(sizeof(adj_vertex_t));
	adj_v->vertex = v2;
	adj_v->edge_weight = 5;
	adj_v->next = NULL;

	// print out our adjacency list
	printf("Adjacency list:\n");
	for (vp = vlist_head; vp != NULL; vp = vp->next) {
		printf("  %s: ", vp->name);
		for (adj_v = vp->adj_list; adj_v != NULL; adj_v = adj_v->next) {
			printf("%s(%d) ", adj_v->vertex->name, adj_v->edge_weight);
		}
		printf("\n");
	}

	// note, I'm not free-ing here, but you should!
    */

}
