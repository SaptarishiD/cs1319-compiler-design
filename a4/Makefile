CC=gcc-13
TARGET_EXEC=translator
LEX=flex
YACC=bison
COMPILE_FLAGS=-ll -ly $(LDFLAGS) -Werror
BISON_DEBUG_FLAGS=-Wall -rstates -rsolved -rall -v -t
HEADER=7_A4.tab.h
INCLUDES= *.o lex.yy.c 7_A4.tab.*
DEBUG_INCLUDES=7_A4.output

.SUFFIXES:

.PHONY = clean
clean:
	rm -f $(INCLUDES) $(TARGET_EXEC) $(DEBUG_INCLUDES)

debug: 7_A4_translator.c 7_A4.l 7_A4.y
	$(LEX) 7_A4.l
	$(YACC) 7_A4.y --header=$(HEADER) $(BISON_DEBUG_FLAGS) -o 7_A4.tab.c
	$(CC) lex.yy.c 7_A4.tab.c 7_A4_translator.c $(COMPILE_FLAGS) -g -DYYDEBUG=1 -o $(TARGET_EXEC)

build: lex.yy.c 7_A4.tab.c 7_A4_translator.c
	$(CC) $^ $(COMPILE_FLAGS) -o $(TARGET_EXEC)
	rm -f $(INCLUDES)

7_A4.tab.c: 7_A4.y
	$(YACC) $^ --header=$(HEADER) -o $@

lex.yy.c: 7_A4.l
	$(LEX) $^