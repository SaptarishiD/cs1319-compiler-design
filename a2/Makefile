CC=gcc-13
TARGET_EXEC=lexer
LEX=flex

.SUFFIXES: 

.PHONY = clean
clean:
	rm -f *.o lex.yy.c $(TARGET_EXEC)

build: lex.yy.c 7_A2.c
	$(CC) lex.yy.c 7_A2.c -ll -o $(TARGET_EXEC) 
	rm -f *.o lex.yy.c

lex.yy.c: 7_A2.l
	$(LEX) 7_A2.l