%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <math.h>
    #include "7_A4.tab.h"
    #include "7_A4_translator.h"  // i think some bugs will come cause of the different names 7_A4 vs 7_A4_translator but idk
%}

INT         "int"
CHAR        "char"
ELSE        "else"
FOR         "for"
IF          "if"
RETURN      "return"
VOID        "void"

letter          [a-zA-Z]
digit           [0-9]
idnondigit      (_|{letter})
nonzerodigit    [1-9]
intconst        {digit}+

escapeseq       \\['"\\?abfnrtv]
cchar           ([^'\\\n]|{escapeseq})
ccharseq        {cchar}+
charconst       \'{ccharseq}\'


schar           ([^"\\\n]|{escapeseq})
scharseq        {schar}+
STRING_LITERAL  \"{scharseq}*\"

ID              {idnondigit}({idnondigit}|{digit})* 


OPEN_SQR_BRACKET            "["
CLOSE_SQR_BRACKET           "]"
OPEN_PARENTHESIS            "("
CLOSE_PARENTHESIS           ")"
OPEN_CURLY_BRACE            "{"
CLOSE_CURLY_BRACE           "}"
ARROW                       "->"
AMPERSAND                   "&"
ASTERISK                    "*"
PLUS                        "+"
MINUS                       "-"
SLASH                       "/"
PERCENT                     "%"
EXCLAMATION                 "!"
QUESTION                    "?"
LESS_THAN                   "<"
GREATER_THAN                ">"
LESS_THAN_OR_EQUAL          "<="
GREATER_THAN_OR_EQUAL       ">="
EQUAL_EQUAL                 "=="
NOT_EQUAL                   "!="
LOGICAL_AND                 "&&"
LOGICAL_OR                  "||"
ASSIGNMENT                  "="
COLON                       ":"
SEMICOLON                   ";"
COMMA                       ","

WS              [ \t\n]

%x MCOMMENT
/* the {INT} and the return INT mean different things. the return INT is the bison wala and {INT} is matching regex */
%%
{INT}                       {return INT;} 
{CHAR}                      {return CHAR;}  
{ELSE}                      {return ELSE;}  
{FOR}                       {return FOR;} 
{IF}                        {return IF;}
{RETURN}                    {return RETURN;}    
{VOID}                      {return VOID;}  

{intconst}                  {
                            yylval.intval = atoi(yytext); // yylval denotes the attribute of the current symbol
                            return INTEGER_CONSTANT;
                            }
                            
{charconst}                 {
                            yylval.charval = strdup(yytext); // here the null termination part is also coming 
                            return CHAR_CONSTANT;
                            }

{STRING_LITERAL}            {
                            yylval.strval = strdup(yytext); // here the null termination part is also coming
                            return STRING_LITERAL;
                            }

{ID}                        {
                            // dont make this symlookup. add it to glb or func ST later on
                            yylval.strval = strdup(yytext); // return symbol pointer // since symp is a ptr should this be yylval->symptr??
                            return IDENTIFIER;              // TODO: Should this instead lookup in the current symbol table so need to make this a function of the struct
                            }

{OPEN_SQR_BRACKET}          {
                            return OPEN_SQR_BRACKET;
                            }
{CLOSE_SQR_BRACKET}         {
                            return CLOSE_SQR_BRACKET;
                            }
{OPEN_PARENTHESIS}          {
                            return OPEN_PARENTHESIS;
                            }
{CLOSE_PARENTHESIS}         {
                            return CLOSE_PARENTHESIS;
                            }
{OPEN_CURLY_BRACE}          {
                            return OPEN_CURLY_BRACE;
                            }
{CLOSE_CURLY_BRACE}         {
                            return CLOSE_CURLY_BRACE;
                            }
{ARROW}                     {
                            return ARROW;
                            }
{AMPERSAND}                 {
                            return AMPERSAND;
                            }
{ASTERISK}                  {
                            return ASTERISK;
                            }
{PLUS}                      {
                            return PLUS;
                            }
{MINUS}                     {
                            return MINUS;
                            }
{SLASH}                     {
                            return SLASH;
                            }
{PERCENT}                   {
                            return PERCENT;
                            }
{EXCLAMATION}               {
                            return EXCLAMATION;
                            }
{QUESTION}                  {
                            return QUESTION;
                            }
{LESS_THAN}                 {
                            return LESS_THAN;
                            }
{GREATER_THAN}              {
                            return GREATER_THAN;
                            }
{LESS_THAN_OR_EQUAL}        {
                            return LESS_THAN_OR_EQUAL;
                            }
{GREATER_THAN_OR_EQUAL}     {
                            return GREATER_THAN_OR_EQUAL;
                            }
{EQUAL_EQUAL}               {
                            return EQUAL_EQUAL;
                            }
{NOT_EQUAL}                 {
                            return NOT_EQUAL;
                            }
{LOGICAL_AND}               {
                            return LOGICAL_AND;
                            }
{LOGICAL_OR}                {
                            return LOGICAL_OR;
                            }
{ASSIGNMENT}                {
                            return ASSIGNMENT;
                            }
{COLON}                     {
                            return COLON;
                            }
{SEMICOLON}                 {
                            return SEMICOLON;
                            }
{COMMA}                     {
                            return COMMA;
                            }

"/*"                        {BEGIN(MCOMMENT);}
<MCOMMENT>"*/"              {BEGIN(INITIAL);}
<MCOMMENT>([^*]|\n)+|.      {;}                                                     // <MCOMMENT><<EOF>>           {printf("Unterminated multiline comment\n"); return yywrap();} // NEED TO LET YYERROR HANDLE THIS

"//".*                      {;}
{WS}                        {;}                                                 // should i return newline and anything else like \n|. like in the guide?                                             
.                           {return yytext[0];}                                 // so that only yyerror handles the errors                    

%%

int yywrap() {
    return 1; // in the guide yywrap returns 0 does that make a difference
}
