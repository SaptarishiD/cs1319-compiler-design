CC=gcc-13
TARGET_EXEC=parser
LEX=flex
YACC=bison
COMPILE_FLAGS=-ll -ly $(LDFLAGS) -Werror
BISON_DEBUG_FLAGS=-Wall -rstates -rsolved -rall -v -t
HEADER=7_A3.tab.h
INCLUDES= *.o lex.yy.c 7_A3.tab.*
DEBUG_INCLUDES=7_A3.output

.SUFFIXES:

.PHONY = clean
clean:
	rm -f $(INCLUDES) $(TARGET_EXEC) $(DEBUG_INCLUDES)

debug: 7_A3.c 7_A3.l 7_A3.y
	$(LEX) 7_A3.l
	$(YACC) 7_A3.y --header=$(HEADER) $(BISON_DEBUG_FLAGS) -o 7_A3.tab.c
	$(CC) lex.yy.c 7_A3.tab.c 7_A3.c $(COMPILE_FLAGS) -DYYDEBUG=1 -o $(TARGET_EXEC)

build: lex.yy.c 7_A3.tab.c 7_A3.c
	$(CC) $^ $(COMPILE_FLAGS) -o $(TARGET_EXEC)
	rm -f $(INCLUDES)

7_A3.tab.c: 7_A3.y
	$(YACC) $^ --header=$(HEADER) -o $@

lex.yy.c: 7_A3.l
	$(LEX) $^