%{
    #include <stdio.h>

    extern char * yytext;
    extern int yylex();
    void yyerror(char *s);
%}

%token IDENTIFIER
%token INTEGER_CONSTANT
%token CHAR_CONSTANT
%token STRING_LITERAL
%token VOID
%token CHAR
%token INT
%token IF
%token ELSE
%token FOR
%token RETURN

%token OPEN_SQR_BRACKET
%token CLOSE_SQR_BRACKET
%token OPEN_PARENTHESIS
%token CLOSE_PARENTHESIS
%token OPEN_CURLY_BRACE
%token CLOSE_CURLY_BRACE
%token ARROW
%token AMPERSAND
%token ASTERISK
%token PLUS
%token MINUS
%token SLASH
%token PERCENT
%token EXCLAMATION
%token QUESTION
%token LESS_THAN
%token GREATER_THAN
%token LESS_THAN_OR_EQUAL
%token GREATER_THAN_OR_EQUAL
%token EQUAL_EQUAL
%token NOT_EQUAL
%token LOGICAL_AND
%token LOGICAL_OR
%token ASSIGNMENT
%token COLON
%token SEMICOLON
%token COMMA




%start translation_unit

%%

constant:
    INTEGER_CONSTANT
    | CHAR_CONSTANT
    ;

primary_expression:
    IDENTIFIER                                      {printf("primary-expression-> IDENTIFIER\n");} // Simple identifier 
    | constant                                      {printf("primary-expression\n");} // Integer or character constant
    | STRING_LITERAL                                {printf("primary-expression -> STRING_LITERAL\n");}
    | OPEN_PARENTHESIS expression CLOSE_PARENTHESIS {printf("primary-expression\n");}
    ;

postfix_expression: // Expressions with postfix operators. Left assoc. in C; non_assoc. here
    primary_expression                                                                    {printf("postfix-expression\n");}
    | postfix_expression OPEN_SQR_BRACKET expression CLOSE_SQR_BRACKET                    {printf("postfix-expression\n");} // 1_D array access
    | postfix_expression OPEN_PARENTHESIS argument_expression_list_opt CLOSE_PARENTHESIS  {printf("postfix-expression\n");} // Function invocation
    | postfix_expression ARROW IDENTIFIER                                                 {printf("postfix-expression\n");} // Pointer indirection. Only one level
    ;

argument_expression_list:
    assignment_expression                                   {printf("argument-expression-list\n");} 
    | argument_expression_list COMMA assignment_expression  {printf("argument-expression-list\n");} 
    ;

argument_expression_list_opt:
    argument_expression_list
    | %empty
    ;   



unary_expression:
    postfix_expression                 {printf("unary-expression\n");}
    | unary_operator unary_expression  {printf("unary-expression\n");} // Expr. with prefix ops. Right assoc. in C; non_assoc. here // Only a single prefix op is allowed in an expression here
    ;

unary_operator:
    AMPERSAND       {printf("unary-operator\n");} 
    | ASTERISK      {printf("unary-operator\n");} 
    | PLUS          {printf("unary-operator\n");} 
    | MINUS         {printf("unary-operator\n");} 
    | EXCLAMATION   {printf("unary-operator\n");} 
    ; // address op, de_reference op, sign ops, boolean negation op



multiplicative_expression: // Left associative operators
    unary_expression                                        {printf("multiplicative-expression\n");}
    | multiplicative_expression ASTERISK unary_expression   {printf("multiplicative-expression\n");}
    | multiplicative_expression SLASH unary_expression      {printf("multiplicative-expression\n");}
    | multiplicative_expression PERCENT unary_expression    {printf("multiplicative-expression\n");}
    ;


additive_expression: // Left associative operators
    multiplicative_expression                               {printf("additive-expression\n");}
    | additive_expression MINUS multiplicative_expression   {printf("additive-expression\n");}
    | additive_expression PLUS multiplicative_expression    {printf("additive-expression\n");}
    ;

relational_expression:
    additive_expression                                                 {printf("relational-expression\n");}
    | relational_expression LESS_THAN additive_expression               {printf("relational-expression\n");}
    | relational_expression GREATER_THAN additive_expression            {printf("relational-expression\n");}
    | relational_expression LESS_THAN_OR_EQUAL additive_expression      {printf("relational-expression\n");}
    | relational_expression GREATER_THAN_OR_EQUAL additive_expression   {printf("relational-expression\n");}
    ;

equality_expression: // Left associative operators
    relational_expression                                       {printf("equality-expression\n");}
    | equality_expression EQUAL_EQUAL relational_expression     {printf("equality-expression\n");}
    | equality_expression NOT_EQUAL relational_expression       {printf("equality-expression\n");}
    ;


logical_AND_expression: // Left associative operators
    equality_expression                                         {printf("logical-AND-expression\n");}
    | logical_AND_expression LOGICAL_AND equality_expression    {printf("logical-AND-expression\n");}
    ;


logical_OR_expression: // Left associative operators
    logical_AND_expression  {printf("logical-OR-expression\n");}
    | logical_OR_expression LOGICAL_OR logical_AND_expression  {printf("logical-OR-expression\n");}
    ;


conditional_expression: // Right associative operator
    logical_OR_expression  {printf("conditional-expression\n");}
    | logical_OR_expression QUESTION expression COLON conditional_expression  {printf("conditional-expression\n");}
    ;


assignment_expression: // Right associative operator
    conditional_expression  {printf("assignment-expression\n");}
    | unary_expression ASSIGNMENT assignment_expression  {printf("assignment-expression\n");} // unary_expression must have lvalue
    ;


expression:
    assignment_expression  {printf("expression\n");}
    ;


declaration: // Simple identifier, 1_D array or function declaration of built_in type
    type_specifier init_declarator SEMICOLON  {printf("declaration\n");} // Only one element in a declaration
    ;


init_declarator:
    declarator  {printf("init-declarator\n");} // Simple identifier, 1_D array or function declaration
    | declarator ASSIGNMENT initializer  {printf("init-declarator\n");} // Simple id with init. initializer for array / fn/ is semantically skipped
    ;

type_specifier: // Built_in types
    VOID  {printf("type-specifier\n");}
    | CHAR  {printf("type-specifier\n");}
    | INT  {printf("type-specifier\n");}
    ;


declarator:
    pointer_opt direct_declarator  {printf("declarator\n");} // Optional injection of pointer
    ;


direct_declarator:
    IDENTIFIER  {
        printf("direct-declarator-> IDENTIFIER\n");
        } // Simple identifier
    | IDENTIFIER OPEN_SQR_BRACKET INTEGER_CONSTANT CLOSE_SQR_BRACKET  {printf("direct-declarator\n");} // 1_D array of a built_in type or ptr to it. Only +ve constant
    | IDENTIFIER OPEN_PARENTHESIS parameter_list_opt CLOSE_PARENTHESIS  {printf("direct-declarator\n");} // Fn. header with params of built_in type or ptr to them
    ;

pointer_opt:
    pointer
    | %empty
    ;

pointer:
    ASTERISK  {printf("pointer\n");}
    ;

parameter_list_opt:
    parameter_list
    | %empty
    ;

parameter_list:
    parameter_declaration  {printf("parameter-list\n");}
    | parameter_list COMMA parameter_declaration  {printf("parameter-list\n");}
    ;


parameter_declaration:
    type_specifier pointer_opt identifier_opt  {printf("parameter-declaration\n");} // Only simple ids of a built_in type or ptr to it as params
    ;

identifier_opt:
    IDENTIFIER
    | %empty
    ;

initializer:
    assignment_expression  {printf("initializer\n");}
    ;



statement:
    compound_statement  {printf("statement\n");} // Multiple statements and / or nest block/s
    | expression_statement  {printf("statement\n");} // Any expression or null statements
    | selection_statement  {printf("statement\n");} // if or if_else
    | iteration_statement  {printf("statement\n");} // for
    | jump_statement  {printf("statement\n");} // return
    ;

block_item_list_opt:
    block_item_list
    | %empty
    ;

compound_statement:
    OPEN_CURLY_BRACE block_item_list_opt CLOSE_CURLY_BRACE  {printf("compound-statement\n");}
    ;

block_item_list:
    block_item  {printf("block-item-list\n");}
    | block_item_list block_item  {printf("block-item-list\n");}
    ;


block_item: // Block scope _ declarations followed by statements
    declaration  {printf("block-item\n");}
    | statement  {printf("block-item\n");}
    ;

expression_opt:
    expression
    | %empty
    ;

expression_statement:
    expression_opt SEMICOLON  {printf("expression-statement\n");}
    ;


selection_statement:
    IF OPEN_PARENTHESIS expression CLOSE_PARENTHESIS statement  {printf("selection-statement\n");}
    | IF OPEN_PARENTHESIS expression CLOSE_PARENTHESIS statement ELSE statement  {printf("selection-statement\n");}
    ;


iteration_statement:
    FOR OPEN_PARENTHESIS expression_opt SEMICOLON expression_opt SEMICOLON expression_opt CLOSE_PARENTHESIS statement  {printf("iteration-statement\n");}
    ;


jump_statement:
    RETURN expression_opt SEMICOLON  {printf("jump-statement\n");}
    ;


translation_unit:
    external_declaration                    {printf("translation-unit\n");}
    | translation_unit external_declaration {printf("translation-unit\n");}
    ;

external_declaration:
    declaration           {printf("external-declaration\n");}
    | function_definition {printf("external-declaration\n");}
    ;

function_definition:
    type_specifier declarator compound_statement  {printf("function-definition\n");}
    ;


%%

void yyerror(char *s) 
{
    printf("Error: %s on '%s'\n",s,yytext);
}

