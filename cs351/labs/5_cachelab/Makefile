CC = gcc
CFLAGS = -Wall -g -I

all: cachesim

cachesim: cachesim.c cache.c
		$(CC) cachesim.c cache.c -o cachesim

gettrace:
	@curl -O http://soi2.s3.amazonaws.com/cs351/trace02.txt.bz2
	@bunzip2 -v trace02.txt.bz2



clean:
	rm -rf *~ *.o cache


