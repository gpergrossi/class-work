# Sample Python implementation of the graph lab.
#
# Note that the output isn't quite what the lab writeup calls for, as this
# program prints out whether a tour exists for every start node in the graph.
#
# try this script with:
#   python graph.py A B 1 B C 2 C D 3

from __future__ import print_function
import sys

def print_adjlist(adjlist):
    print('Adjacency list:')
    for vec in adjlist:
        print(vec['name'], end=': ')
        for adj_vec in vec['adj']:
            print('{}({})'.format(adj_vec[0]['name'], adj_vec[1]), end=' ')
        print()

def add_edge(adj_list, nameA, nameB, weight):
    vA = find_or_make_vec(adj_list, nameA)
    vB = find_or_make_vec(adj_list, nameB)
    vA['adj'].append((vB, weight))
    vB['adj'].append((vA, weight))

def find_or_make_vec(adj_list, name):
    for vec in adj_list:
        if vec['name'] == name:
            return vec
    nvec = {'name' : name, 'adj' : []}
    adj_list.append(nvec)
    return nvec

# find_tour tries to find a tour starting at a given node; it takes:
# - a `start` vector
# - the number of `hops` remaining for the search to succeed
# - a list of names of already `visited` vertices in the search
# and returns:
# - the length of the tour, if one is found
# - None, if no tour has been found
def find_tour(start, hops, visited):
    if hops == 0:
        visited.append(start['name'])
        return 0
    else:
        visited.append(start['name'])
        for adj_vec in start['adj']:
            my_name = adj_vec[0]['name']
            if my_name not in visited:
                length = find_tour(adj_vec[0], hops-1, visited)
                if length is not None:
                    return adj_vec[1] + length
        visited.pop()
        return None

if __name__ == '__main__':
    adj_list = []
    
    # create adjacency list from command line args
    for i in range(1, len(sys.argv), 3):
        add_edge(adj_list, sys.argv[i], sys.argv[i+1], int(sys.argv[i+2]))

    print_adjlist(adj_list)
    print()

    # try finding a tour starting from every node
    for vec in adj_list:
        tour = []
        length = find_tour(vec, len(adj_list)-1, tour)
        if length is not None:
            print('Tour starting at {}: {} (length = {})'.format(
                    vec['name'], tour, length))
        else:
            print('No tour starting at {}'.format(vec['name']))
