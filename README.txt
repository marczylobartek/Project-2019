I. Kompilator składa się z trzech plików i pliku Makefile

1. Plik Lex
- kompilator.l
2. Plik Bison
- kompilator.y
3. Plik nagłówkowy 
- types.h

Uruchomienie:
1. Trzeba użyć polecenia 'make" , które utworzy program wynikowy 
o nazwie kompilator
2. kompilator <nazwa pliku wejściowego> <nazwa pliku wyjściowego>
 
 
Program został przetestowany
* g++ (GCC) 7.3.0 z opcją -std=gnu++11
* flex 2.6.4
* bison (GNU Bison) 3.0.4