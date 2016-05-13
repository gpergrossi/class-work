HANDINDIR = /home/spring-06/submissions/cs351/${USER}
INSTALLOPT = --backup=t -m 644

CC = gcc
CFLAGS = -Wall -g 
LDFLAGS =  -l pthread

OBJS = proxy.o csapp.o

all: proxy

proxy: $(OBJS)

csapp.o: csapp.c
	$(CC) $(CFLAGS) -c csapp.c

proxy.o: proxy.c
	$(CC) $(CFLAGS) -c proxy.c

clean:
	rm -f *~ *.o proxy core

