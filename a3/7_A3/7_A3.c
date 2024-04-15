int yylex();
int yyparse();

int main()
{
    #if YYDEBUG
        extern int yydebug;
        yydebug = 1;
    #endif
    yyparse();
}