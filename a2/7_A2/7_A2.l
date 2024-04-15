%{
    #include <stdio.h>
    #include <stdlib.h>
%}

INT "int"
CHAR "char"
ELSE "else"
FOR "for"
IF "if"
RETURN "return"
VOID "void"

KEYWORD {INT}|{CHAR}|{ELSE}|{FOR}|{IF}|{RETURN}|{VOID}

letter [a-zA-Z]
digit [0-9]
idnondigit (_|{letter})
nonzerodigit [1-9]
intconst ({digit}*)|([+-]?{nonzerodigit}{digit}*)

escapeseq \\['"\\?abfnrtv]
cchar ([^'\\\n]|{escapeseq})
ccharseq {cchar}+
charconst \'{ccharseq}\'

CONST {intconst}|{charconst}

schar ([^"\\\n]|{escapeseq})
scharseq {schar}+
STRING-LITERAL \"{scharseq}*\"

ID {idnondigit}({idnondigit}|{digit})*
PUNC "["|"]"|"("|")"|"{"|"}"|"->"|"&"|"*"|"+"|"-"|"/"|"%"|"!"|"?"|"<"|">"|"<="|">="|"=="|"!="|"&&"|"||"|"="|":"|";"|","


WS [ \t\n]


%x MCOMMENT

%%
{KEYWORD}               {printf("<KEYWORD, %s>\n", yytext);}
{CONST}                 {printf("<CONSTANT, %s>\n", yytext);}
{STRING-LITERAL}        {printf("STRING-LITERAL, %s>\n", yytext);}
{ID}                    {printf("<IDENTIFIER, %s>\n", yytext);}
{PUNC}                  {printf("<PUNCTUATOR, %s>\n", yytext);}
"/*"                    {BEGIN(MCOMMENT);}
<MCOMMENT>"*/"          {BEGIN(0);}
<MCOMMENT>(\n)+|.       {;}
<MCOMMENT><<EOF>>       {printf("<INVALID INPUT, UNTERMINATED \"/*\">\n"); return yywrap();}
"//".*                  {;}

{WS}                    {;}
.                       {printf("<INVALID INPUT, %s>\n", yytext); return yywrap();}



%%

int yywrap(){
    return 1;
}


