all: kompilator

kompilator: kompilator.y kompilator.l
	bison -d kompilator.y
	flex kompilator.l
	g++  -std=gnu++11 -o kompilator lex.yy.c kompilator.tab.c -l cln

clean:
	rm -f kompilator kompilator.tab.c kompilator.tab.h lex.yy.c
	rm -f *.mr
 
