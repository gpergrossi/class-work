CC = gcc
CFLAGS = -g -Wall
OBJS = graph.o

graph: main.c $(OBJS)
	$(CC) $(CFLAGS) -o graph main.c $(OBJS)

graph.o: graph.c

clean:
	rm -f *~ *.o graph
