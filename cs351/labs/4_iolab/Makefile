# Makefile for the CS:APP Shell Lab

DRIVER = ./sdriver.pl
TSH = ./tsh
TSHREF = /bin/sh
TSHARGS = "-p"
CC = gcc
CFLAGS = -Wall -g
FILES = $(TSH)

all: $(FILES)

##################
# Regression tests
##################

# Run tests using the student's shell program
test01:
	$(DRIVER) -t trace01.txt -s $(TSH) -a $(TSHARGS)
test02:
	$(DRIVER) -t trace02.txt -s $(TSH) -a $(TSHARGS)
test03:
	$(DRIVER) -t trace03.txt -s $(TSH) -a $(TSHARGS)
test04:
	$(DRIVER) -t trace04.txt -s $(TSH) -a $(TSHARGS)

# Run the tests using the reference shell program
rtest01:
	$(DRIVER) -t trace01.txt -s $(TSHREF) -a $(TSHARGS)
rtest02:
	$(DRIVER) -t trace02.txt -s $(TSHREF) -a $(TSHARGS)
rtest03:
	$(DRIVER) -t trace03.txt -s $(TSHREF) -a $(TSHARGS)
rtest04:
	$(DRIVER) -t trace04.txt -s $(TSHREF) -a $(TSHARGS)

# clean up
clean:
	rm -f $(FILES) *.o *~


