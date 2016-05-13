poker: poker.c poker.h main.c
	gcc -o poker poker.c poker.h main.c

tests: poker.c poker.h all-tests.c
	@echo "Collecting all unit tests ..."
	@./make-tests.sh > tests-main.c
	@echo "Compiling tests-main.c ..."
	@gcc -o tests poker.c poker.h CuTest.c all-tests.c tests-main.c
	@echo "Running tests ...\n"
	@./tests

clean:
	rm -f tests-main.c poker tests *.o
