%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "7_A4_translator.h"

    extern char * yytext;
    extern int yylex();
    void yyerror(char *s);
    

    const unsigned int size_of_char = 1;
    const unsigned int size_of_int = 4;
    const unsigned int size_of_pointer = 4;

    char globalstr[10] = "Global";
    char dummy[10] = "Dummy";
    char * func_name;
%}


%union { // Placeholder for a value
	int intval;
    char* charval;
    char * strval;
    int num_params;
    char unary_op;
    struct _expression* expr;
    struct _symtab_entry * loc;
    struct _statement * stmt;
    struct _param_node * param;
    struct _arg_expr_list * argexpr;
    int instr;
}

%token <intval> INTEGER_CONSTANT
%token <charval> CHAR_CONSTANT
%token <strval> STRING_LITERAL
%token <strval> IDENTIFIER

%token VOID CHAR INT IF ELSE FOR RETURN OPEN_SQR_BRACKET CLOSE_SQR_BRACKET OPEN_PARENTHESIS CLOSE_PARENTHESIS OPEN_CURLY_BRACE CLOSE_CURLY_BRACE
%token ARROW AMPERSAND ASTERISK PLUS MINUS SLASH PERCENT EXCLAMATION QUESTION LESS_THAN GREATER_THAN LESS_THAN_OR_EQUAL GREATER_THAN_OR_EQUAL
%token EQUAL_EQUAL NOT_EQUAL LOGICAL_AND LOGICAL_OR ASSIGNMENT COLON SEMICOLON COMMA


%type <strval>
    type_specifier

%type <intval>
    pointer_opt
    pointer

%type <strval>
    identifier_opt


%type <expr>
	primary_expression
	postfix_expression
	unary_expression
	multiplicative_expression
	additive_expression
%type <expr>
	relational_expression
	equality_expression
	logical_AND_expression
	logical_OR_expression
%type <expr>
	conditional_expression
%type <expr>
	assignment_expression
%type <expr>
    expression
    expression_opt


%type <stmt>
    statement
    compound_statement
	iteration_statement
	selection_statement
	jump_statement
    block_item
    block_item_list
    block_item_list_opt
	expression_statement

%type <unary_op>
    unary_operator

%type <argexpr>
    argument_expression_list
    argument_expression_list_opt


%type <loc> 
    direct_declarator 
    init_declarator 
    declarator


%type <loc>
    initializer


%type <argexpr>
    parameter_declaration
    parameter_list
    parameter_list_opt

%type <instr>
    M

%type <stmt>
    N1
    N2
    

%type <strval>
    function_guard


%start translation_unit

%%
M: %empty
{
    $$ = quad_counter;
    printrule("M -> epsilon");
}

// for the if statements
N1: %empty
{
    $$ = init_statement();
    $$->nextlist = make_list(quad_counter);
    quad_array[quad_counter++] = new_quad_instr(op_JUMP, ""); 
    printrule("N1 -> epsilon");
}


// for the for loop (separate to account for for(;;))
N2: %empty
{
    $$ = init_statement();
    $$->nextlist = make_list(quad_counter);
    if ($<expr>0) {quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");} 
    printrule("N2 -> epsilon");
}

function_guard: %empty
{
    // printf("Function name: %s\n", $<loc>0->name);
    symtab_entry * temp_func = symlookup(global_symtab, $<loc>0->name);
    current_symtab = temp_func->nested_table;
    // printf("current_symtab changed: %s\n", current_symtab->name);
    // printf("%s", current_symtab->name);
    // printf("REACHED HERE\n");
    printrule("function_guard -> epsilon");
}


primary_expression:
    IDENTIFIER
    // need to do symlookup to get the type of the thing being called in func invocation cause it's like max(x,y) so bison stack doesnt work. will also work for stuff like int x; x = 5;
    {
        $$ = init_expression();
        symtab_entry * func_check = search_symtab(global_symtab, $1); // so that we don't put function inside function when we're just calling it
        if (!func_check) // if the symbol is not in the global ST
        {
            $$->loc = symlookup(current_symtab, $1); 
            // printf("curr ST name primary expr: %s\n", current_symtab->name);
            // printf("primary expr name: %s type: %s\n", $$->loc->name, $$->loc->type);
        }
        else if (func_check)  // if symbol is in the glb // what if a symbol has the same name in the global and the function symtab
        {
            if (strcmp(func_check->category, "funct, glb") == 0) // if it's a function
            {
                $$->loc = func_check;
            }
            else // just a global variable being accessed
            {
                $$->loc = symlookup(global_symtab, $1);
            }
        }
        // printf("ID name %s ID type %s\n",$$->loc->name, $$->loc->type);
        printrule("primary-expression -> IDENTIFIER");
        printrule($$->loc->name);
        // We don't know the value at this stage, cannot assign a type or val
    } // Simple identifier

    // separating constant into integer and character constant

    | INTEGER_CONSTANT
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab); 
        // printf("%s in %s\n", $$->loc->name, current_symtab->name);
        char* num_s = strdup(int_to_str($1));
        // $$->intval = $1;
        $$->loc->initial_val = strdup(num_s);
        update_entry($$->loc, "int", "temp", size_of_int, UNKNOWN_OFFSET, NULL);

        // $$->type = strdup("int"); // type in the expression struct
        // $$->intval = $1;
        // $$->loc->name means the name of the temporary which is what we want it to be assigned to
        // e.g quad: txxx = 45
        quad_array[quad_counter++] = new_quad_unary(op_COPY, $$->loc->name, num_s);
        printrule("primary-expression -> INTEGER_CONSTANT");
    }

    | CHAR_CONSTANT
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->loc->initial_val = strdup($1);
        update_entry($$->loc, "char", "temp", size_of_char, UNKNOWN_OFFSET, NULL);
        quad_array[quad_counter++] = new_quad_unary(op_COPY, $$->loc->name, $$->loc->initial_val);
        printrule("primary-expression -> CHAR_CONSTANT");
    }

    | STRING_LITERAL                                        
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->loc->initial_val = strdup($1);
        // printf("string literal: %s\n", $$->loc->initial_val);
        update_entry($$->loc, "char *", "temp", size_of_pointer, UNKNOWN_OFFSET, NULL);
        quad_array[quad_counter++] = new_quad_unary(op_COPY, $$->loc->name, $$->loc->initial_val);
        printrule("primary-expression -> STRING_LITERAL");
    }

    | OPEN_PARENTHESIS expression CLOSE_PARENTHESIS
    {
        $$ = $2;
        printrule("primary-expression -> ( expression )");
    }
    ;

// NEED TO ADD LOCAL TO THE LOCAL VARIABLES CATEGORY IF THE CURRENT SYMTAB ISN'T GLOBAL (IF THE CURRENT SYMTAB KA PARENT ISN'T NULL)
postfix_expression: // Expressions with postfix operators. Left assoc. in C; non_assoc. here
    primary_expression
    {
        $$=$1;
        printrule("postfix-expression-> primary_expression");
    }
    | postfix_expression OPEN_SQR_BRACKET expression CLOSE_SQR_BRACKET
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isarray = 1;
        $$->array_base = $1->loc;      // need to remember this so that we know how many elements in the array
        // printf("Array base type: %s\n", $1->loc->name);
        // printf("REACHED\n");
        $$->loc->type = strdup($$->array_base->type);
        char arr_elem_typesize[5];
        $$->elem_access = strdup($3->loc->name); // need to remember this so know what index we want
        if(strcmp($3->loc->type, "int") == 0 || strcmp($3->loc->type, "int*") == 0 || strcmp($3->loc->type, "char*") == 0)
        {
            $$->arr_elem_size = 4; // hardcoded for this assignment
            sprintf(arr_elem_typesize, "%s", "4"); // could also just do array_base->type
        }
        else if(strcmp($3->loc->type, "char") == 0)
        {
            $$->arr_elem_size = 1;
            sprintf(arr_elem_typesize, "%s", "1"); // could also just do array_base->type
        }
        // quad_array[quad_counter++] = new_quad_binary(op_MULT, $$->loc->name, $3->loc->name, arr_elem_typesize);  // we need for e.g. 4*i to get to ith integer

        printrule("postfix-expression-> postfix-expression [ expression ]");
    } // 1_D array access

    | postfix_expression OPEN_PARENTHESIS argument_expression_list_opt CLOSE_PARENTHESIS
    {
        // symtab_entry * temp_entry = symlookup(current_symtab, $1->loc->name); 
        // i assume that params will match since pdf said no wrong programs will be given
        // printf("\n %s", %3->loc->name);
        // printf("%i", $3->myargs->count);
        if ($3)
        {
            arg_expr_list * temp_list = NULL;
            int count = count_LL_elements_arg($3);
            char countstr[10];
            sprintf(countstr, "%d", count);
            arg_expr_list * temp = NULL;
            int i = 0;
            // for (temp = $3; temp->next != NULL; temp = temp->next)
            // {
            //     printf("%s\n", temp->loc->name);
            // }
            
            for (temp = $3; temp != NULL; temp = temp->next)
            {
                // printf("counter: %i\n", i);
                // i++;
                quad_array[quad_counter++] = new_quad_instr(op_PARAM, temp->loc->name);
            }

            // why was func in main ka symtab
            // printf("postfix expression: %s\n", $1->loc->name);
            symtab_entry * func_entry = symlookup(global_symtab, $1->loc->name);
            $$->loc = gentemp(current_symtab);
            char * func_type = strdup(func_entry->type);
            if (strcmp(func_type, "int") == 0) 
            {
                update_entry($$->loc, func_type, "temp", size_of_int, UNKNOWN_OFFSET, NULL);
            } 
            else if (strcmp(func_type, "char") == 0) 
            {
                update_entry($$->loc, func_type, "temp", size_of_char, UNKNOWN_OFFSET, NULL);
            }

            if (strcmp(func_type, "void") == 0)
            {
                quad_array[quad_counter++] = new_quad_binary(op_CALL, "", func_entry->name, countstr);
            }
            else
            {
                quad_array[quad_counter++] = new_quad_binary(op_CALL, $$->loc->name, func_entry->name, countstr);
            }
            printrule("postfix-expression-> ( argument_expression_list_opt )");
        }


    } // Function invocation

    | postfix_expression ARROW IDENTIFIER
    {
        // we don't have structs so don't need this
        printrule("postfix-expression-> postfix-expression ARROW IDENTIFIER");
    } // Pointer indirection. Only one level
    ;
    // Only a single postfix op is allowed in an expression here



// if we allow func(i) to be called as func(1+2) then will need to remember the value of the arithmetic expression in the temp for which will need to evaluate stuff // no
argument_expression_list:
    assignment_expression
    {
        // argument expression list could have a type struct arg_expr which has fields a list which will contain arguments and a counter which tracks the number of arguments 
        // printf("REACHED1 %s\n", $1->loc->type);
        // printf("%s, %s", $1->loc->name, $1->loc->type);
        $$ = make_list_arg($1->loc, $1->loc->type);       
        // printf("REACHED2\n");
        printrule("argument-expression-list-> assignment_expression");
    }

    | argument_expression_list COMMA assignment_expression
    {
        
        struct _arg_expr_list * temp = make_list_arg($3->loc, $3->loc->type);
        $$ = merge_lists_arg($1, temp);
        printrule("argument-expression-list-> argument_expression_list , assignment_expression");
    }
    ;

argument_expression_list_opt:
    argument_expression_list
    {
        $$ = $1;
        // printf("arglistoptcount: %i", $1->myargs->count);
        printrule("argument_expression_list_opt -> argument_expression_list");
    }
    | %empty
    {
        $$ = NULL;
        printrule("argument_expression_list_opt -> epsilon");
    }
    ;



unary_expression:
    postfix_expression
    {
        printrule("unary-expression-> postfix_expression regular");
    }
    | unary_operator unary_expression
    {
        $$ = init_expression();
        switch($1){

            case '&':
                $$->loc = gentemp(current_symtab);
                $$->loc->isptr = 1;
                $$->loc->type = strdup($2->loc->type);
                $$->loc->size = size_of_pointer;
                quad_array[quad_counter++] = new_quad_unary(op_UAND, $$->loc->name, $2->loc->name);
                break;

            case '*':
                $$->loc = gentemp(current_symtab);
                $2->loc->isptr = 1;
                
                if (strcmp($2->loc->type, "int*") == 0)
                {
                    $$->loc->type = strdup("int");
                    $$->loc->size = size_of_int;
                }
                else if (strcmp($2->loc->type, "char*") == 0)
                {
                    $$->loc->type = strdup("char");
                    $$->loc->size = size_of_char;
                }
                quad_array[quad_counter++] = new_quad_unary(op_USTAR, $$->loc->name, $2->loc->name);
                break;
            
            case '+':
                $$ = $2;
                break;
            case '-':
                $$->loc = gentemp(current_symtab);
                update_entry($$->loc, $2->loc->type, $2->loc->category, $2->loc->size, UNKNOWN_OFFSET, NULL);
                quad_array[quad_counter++] = new_quad_unary(op_UMINUS, $$->loc->name, $2->loc->name);
                break;
            
            case '!':
            // i assume that the given unary expression is boolean otherwise doesn't make sense and in the pdf it's mentioned that no error handling needed
                // no new temp needed in this case
                $$->isbool = 1;
                $$->truelist = $2->falselist;
                $$->falselist = $2->truelist;
                $$->loc = $2->loc;
                quad_array[quad_counter++] = new_quad_unary(op_UNOT, $$->loc->name, $2->loc->name);
                break;
        }
        printrule("unary-expression-> unary_operator unary_expression");
    } // Expr. with prefix ops. Right assoc. in C; non_assoc. here // Only a single prefix op is allowed in an expression here
    ;


unary_operator:
    AMPERSAND
    { // address op
        $$ = '&';
        printrule("unary-operator-> &");
    }
    | ASTERISK
    { // de_reference op
        $$ = '*';
        printrule("unary-operator-> *");
    }
    | EXCLAMATION
    { // boolean negation op
        $$ = '!';
        printrule("unary-operator-> !");
    }
    | PLUS
    { // sign op plus
        $$ = '+';
        printrule("unary-operator-> +");
    }
    | MINUS
    { // sign op minus
        $$ = '-';
        printrule("unary-operator-> -");
    }
     
    ; // address op, de_reference op, sign ops, boolean negation op



multiplicative_expression: // Left associative operators
    unary_expression
    {
        $$=$1;
        printrule("multiplicative-expression -> unary_expression"); // what to do here
    }
    | multiplicative_expression ASTERISK unary_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        update_entry($$->loc, "int", "temp", size_of_int, UNKNOWN_OFFSET, NULL);                        // assuming we do arithmetic with just ints
        quad_array[quad_counter++] = new_quad_binary(op_MULT, $$->loc->name, $1->loc->name, $3->loc->name);
        printrule("multiplicative-expression -> multiplicative-expression * unary_expression");
    }
    | multiplicative_expression SLASH unary_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        update_entry($$->loc, "int", "temp", size_of_int, UNKNOWN_OFFSET, NULL);                        // assuming we do arithmetic with just ints
        quad_array[quad_counter++] = new_quad_binary(op_DIV, $$->loc->name, $1->loc->name, $3->loc->name);
        printrule("multiplicative-expression -> multiplicative-expression / unary_expression");
    }
    | multiplicative_expression PERCENT unary_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        update_entry($$->loc, "int", "temp", size_of_int, UNKNOWN_OFFSET, NULL);                        // assuming we do arithmetic with just ints
        quad_array[quad_counter++] = new_quad_binary(op_MOD, $$->loc->name, $1->loc->name, $3->loc->name);
        printrule("multiplicative-expression -> multiplicative-expression PERCENT unary_expression");
    }
    ;


additive_expression: // Left associative operators
    multiplicative_expression
    {
        $$=$1;
        printrule("additive-expression -> multiplicative_expression"); 
    }
    | additive_expression MINUS multiplicative_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        update_entry($$->loc, "int", "temp", size_of_int, UNKNOWN_OFFSET, NULL);
        quad_array[quad_counter++] = new_quad_binary(op_MINUS, $$->loc->name, $1->loc->name, $3->loc->name);
        printrule("additive-expression -> additive-expression - multiplicative_expression");
    }
    | additive_expression PLUS multiplicative_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        // $$->intval = $1->intval + $3->intval;
        update_entry($$->loc, "int", "temp", size_of_int, UNKNOWN_OFFSET, NULL);
        quad_array[quad_counter++] = new_quad_binary(op_PLUS, $$->loc->name, $1->loc->name, $3->loc->name);
        printrule("additive-expression -> additive-expression + multiplicative_expression");
    }
    ;

relational_expression:
    additive_expression
    {
        $$=$1;
        printrule("relational-expression-> additive_expression");
    }
    | relational_expression LESS_THAN additive_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isbool = 1;
        $$->truelist = make_list(quad_counter+1);
        $$->falselist = make_list(quad_counter+2);
        quad_array[quad_counter++] = new_quad_binary(op_LESS, $$->loc->name, $1->loc->name, $3->loc->name);
        quad_array[quad_counter++] = new_quad_unary(op_JUMP_CN, "", $$->loc->name);
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");        
        printrule("relational-expression-> relational_expression < additive_expression");
    }
    | relational_expression GREATER_THAN additive_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isbool = 1;
        $$->truelist = make_list(quad_counter+1);
        $$->falselist = make_list(quad_counter+2);
        quad_array[quad_counter++] = new_quad_binary(op_GREATER, $$->loc->name, $1->loc->name, $3->loc->name);
        quad_array[quad_counter++] = new_quad_unary(op_JUMP_CN, "", $$->loc->name);
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");
        printrule("relational-expression-> relational_expression > additive_expression");
    }
    | relational_expression LESS_THAN_OR_EQUAL additive_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isbool = 1;
        $$->truelist = make_list(quad_counter+1);
        $$->falselist = make_list(quad_counter+2);
        quad_array[quad_counter++] = new_quad_binary(op_LESSEQ, $$->loc->name, $1->loc->name, $3->loc->name);
        quad_array[quad_counter++] = new_quad_unary(op_JUMP_CN, "", $$->loc->name);
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");
        printrule("relational-expression-> relational_expression <= additive_expression");
    }
    | relational_expression GREATER_THAN_OR_EQUAL additive_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isbool = 1;
        $$->truelist = make_list(quad_counter+1);
        $$->falselist = make_list(quad_counter+2);
        quad_array[quad_counter++] = new_quad_binary(op_GREATEREQ, $$->loc->name, $1->loc->name, $3->loc->name);
        quad_array[quad_counter++] = new_quad_unary(op_JUMP_CN, "", $$->loc->name);
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");
        printrule("relational-expression-> relational_expression >= additive_expression");
    }
    ;

equality_expression: // Left associative operators
    relational_expression
    {
        $$=$1;
        printrule("equality-expression-> relational_expression");
    }
    | equality_expression EQUAL_EQUAL relational_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isbool = 1;
        $$->truelist = make_list(quad_counter+1);
        $$->falselist = make_list(quad_counter+2);
        // printf("equality expr: %s %s %s\n", $$->loc->name, $1->loc->name, $3->loc->name);
        quad_array[quad_counter++] = new_quad_binary(op_EQUAL, $$->loc->name, $1->loc->name, $3->loc->name);
        quad_array[quad_counter++] = new_quad_unary(op_JUMP_CN, "", $$->loc->name);
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");
        printrule("equality-expression-> equality_expression == relational_expression");
    }
    | equality_expression NOT_EQUAL relational_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isbool = 1;
        $$->truelist = make_list(quad_counter+1);
        $$->falselist = make_list(quad_counter+2);
        quad_array[quad_counter++] = new_quad_binary(op_NOTEQUAL, $$->loc->name, $1->loc->name, $3->loc->name);
        quad_array[quad_counter++] = new_quad_unary(op_JUMP_CN, "", $$->loc->name);
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");
        printrule("equality-expression-> equality_expression != relational_expression");
    }
    ;


logical_AND_expression: // Left associative operators
    equality_expression
    {
        $$=$1;
        printrule("logical-AND-expression-> equality_expression");
    }
    | logical_AND_expression LOGICAL_AND M equality_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isbool = 1;
        if(strcmp(search_symtab(current_symtab,$1->loc->name)->category, "temp") != 0) // if it's a non temp var matlab we're doing implicit bool stuff
        {
            // printf("in if\n");
            $1 = int2bool($1);
        }
        printf("Truelist of %s is: ", $1->loc->name);
        print_list($1->truelist);
        backpatch($1->truelist, $3);

        if(strcmp(search_symtab(current_symtab,$4->loc->name)->category, "temp") != 0) // if it's a non temp var matlab we're doing implicit bool stuff
        {
            // printf("in if\n");
            $4 = int2bool($4);
        }
        $$->truelist= $4->truelist;
        $$->falselist = merge_lists($1->falselist, $4->falselist);
        printrule("logical-AND-expression-> && equality expression");
    }
    ;


logical_OR_expression: // Left associative operators
    logical_AND_expression
    {
        $$=$1;
        printrule("logical-OR-expression-> logical_AND_expression ");
    }
    | logical_OR_expression LOGICAL_OR M logical_AND_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->isbool = 1;
        if(strcmp(search_symtab(current_symtab,$1->loc->name)->category, "temp") != 0) // if it's a non temp var matlab we're doing implicit bool stuff
        {
            // printf("in if\n");
            $1 = int2bool($1);
        }
        backpatch($1->falselist, $3);
        if(strcmp(search_symtab(current_symtab,$4->loc->name)->category, "temp") != 0) // if it's a non temp var matlab we're doing implicit bool stuff
        {
            // printf("in if\n");
            $4 = int2bool($4);
        }
        $$->truelist = merge_lists($1->truelist, $4->truelist);
        $$->falselist = $4->falselist;
        printrule("logical-OR-expression-> logical_OR_expression LOGICAL_OR logical_AND_expression");
    }
    ;


conditional_expression: // Right associative operator
    logical_OR_expression
    {
        $$=$1;
        printrule("conditional-expression-> logical_OR_expression");
    }
    | logical_OR_expression N1 QUESTION M expression N1 COLON M conditional_expression
    {
        $$ = init_expression();
        $$->loc = gentemp(current_symtab);
        $$->loc->type = $5->loc->type;
        quad_array[quad_counter++] = new_quad_unary(op_COPY, $$->loc->name, $9->loc->name);
        list * temp;
        temp = make_list(quad_counter);
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");
        backpatch($6->nextlist, quad_counter);
        quad_array[quad_counter++] = new_quad_unary(op_COPY, $$->loc->name, $5->loc->name);
        temp = merge_lists(temp, make_list(quad_counter));
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");
        backpatch($2->nextlist, quad_counter);
        $1 = int2bool($1);
        backpatch($1->truelist, $4);
        backpatch($1->falselist, $8);
        backpatch(temp, quad_counter);
        printrule("conditional-expression-> logical_OR_expression ? expression : conditional_expression");
    }
    ;


assignment_expression: // Right associative operator
    conditional_expression
    {
        $$=$1;
        // printf("assignment id: %s %s\n", $$->loc->type, $$->loc->name);
        printrule("assignment-expression-> conditional_expression");
    }
    | unary_expression ASSIGNMENT assignment_expression
    {
        $$ = init_expression();
        if ($1->isarray == 1)
        {
            symtab_entry * offset_calc = gentemp(current_symtab);
            char arr_elem_size_str[5];
            sprintf(arr_elem_size_str, "%d", $1->arr_elem_size);
            quad_array[quad_counter++] = new_quad_binary(op_MULT, offset_calc->name, $1->elem_access, arr_elem_size_str);  // we need for e.g. 4*i to get to ith integer
            // printf("array base name assignment: %s", $1->array_base->name);
            // printf("\nREACHED unary = ass\n");
            // printf("%s, %s, %s\n",$1->array_base->name, offset_calc->name, $3->loc->name);
            quad_array[quad_counter++] = new_quad_binary(op_ASSIGN_IND, $1->array_base->name, offset_calc->name, $3->loc->name);
        }
        else
        {
            quad_array[quad_counter++] = new_quad_unary(op_COPY, $1->loc->name, $3->loc->name);
        }
        printrule("assignment-expression-> unary_expression = assignment_expression");
    } // unary_expression must have lvalue
    ;


expression:
    assignment_expression
    {
        $$ = $1;
        printrule("expression-> assignment_expression");
    }
    ;


declaration: // Simple identifier, 1_D array or function declaration of built_in type
    type_specifier init_declarator SEMICOLON
    {
        if (strcmp($2->type, "arr") == 0 )
        {
            char * type_spec = strdup($1);         // using bison stack to get the type_specifier
            int arr_size;
            if((strcmp(type_spec, "int") == 0 || strcmp(type_spec, "char") == 0) && $2->isptr == 1)
            {
                strcat(type_spec, "*");
                arr_size = $2->size*size_of_pointer;
            }
            else if(strcmp(type_spec, "int") == 0)
            {
                arr_size = $2->size*size_of_int;
            } 
            else if(strcmp(type_spec, "char") == 0)
            {
                arr_size = $2->size*size_of_char;
            }
            else if(strcmp(type_spec, "char*") == 0 || (strcmp(type_spec, "int*") == 0 ))
            {
                arr_size = $2->size*size_of_pointer;
            }
            char arr_len_str[5];
            sprintf(arr_len_str, "%d", $2->size);
            char arr_type[15];
            sprintf(arr_type, "%s", "arr(");
            strcat(arr_type, type_spec);
            strcat(arr_type, ",");
            strcat(arr_type, arr_len_str);
            strcat(arr_type, ")");
            // printf("%s", arr_type);

            if (current_symtab->parent)
            {
                update_entry($2, arr_type, "local", arr_size, UNKNOWN_OFFSET, NULL);
            }
            else
            {
                update_entry($2, arr_type, "Global", arr_size, UNKNOWN_OFFSET, NULL);
            }
        }

        if (strcmp($2->category, "funct, glb") == 0)
        {
            current_symtab = global_symtab;
        }
        printrule("declaration-> type_specifier init_declarator ;");
    } // Only one element in a declaration
    ;


init_declarator:
    declarator
    {
        $$=$1;
        printrule("init-declarator-> declarator");
    } // Simple identifier, 1_D array or function declaration

    | declarator ASSIGNMENT initializer
    {   
        if ($3->initial_val) {$1->initial_val = $3->initial_val;}
        // printf("%s %s %s %s\n", $1->name, $1->type, $1->category, $1->size );
        update_entry($$, $$->type, $$->category, $$->size, UNKNOWN_OFFSET, NULL); // not sure if this works
        quad_array[quad_counter++] = new_quad_unary(op_COPY, $1->name, $3->name);
        printrule("init-declarator-> declarator = initializer");
    } // Simple id with init. initializer for array / fn/ is semantically skipped
    ;


// assigning integers to particular types so that we can check which type it is later on
type_specifier: // Built_in types
    VOID
    {
        $$ = strdup("void");
        printrule("type-specifier-> VOID");
    }
    | CHAR
    {
        $$ = strdup("char");
        printrule("type-specifier-> CHAR");
    }
    | INT
    {
        $$ = strdup("int");
        printrule("type-specifier-> INT");
    }
    ;


declarator:
    pointer_opt direct_declarator
    {
        $$ = $2;
         // see what to do about pointer_opt I think then just update the type to be the old type with asterisk next to it
        if ($1 == 1) // if it's a pointer
        {
            $$->isptr = 1;
            if (strcmp($2->type, "int") == 0) 
            {
                $$->type = "int*";
                $$->size = size_of_pointer;

            } 
            else if (strcmp($2->type, "char") == 0) 
            {
                $$->type = "char*";
                $$->size = size_of_pointer;
            } 
            else if (strcmp($2->type, "void") == 0) 
            {
                $$->type = "void*";
                $$->size = size_of_pointer;
            }
        }

        if ($2->nested_table)   // if it's a function then we must go into it's symtab to put stuff there
        {
            current_symtab = $2->nested_table;
        }
        printrule("declarator-> pointer_opt direct_declarator");
        // printf("Function name decl: %s\n", $$->name);
    } // Optional injection of pointer
    ;

 // need to take care of multiple declarations also so so that duplicate entires don't get added
direct_declarator:
    IDENTIFIER
    {   
        $$ = symlookup(current_symtab, $1);  // we search the symbol table for the identifier and if it's not there we add it // can't do this for functions
        char * type_spec = strdup($<strval>-1);         // using bison stack to get the type_specifier
        if (strcmp(current_symtab->name, globalstr) == 0) 
            {
                $$->initial_val = strdup("0"); // globals initialised to 0 by default
            }
        // check if the the type_spec is int, char or void and depending on that update the type in the symbol table
        if (strcmp(type_spec, "int") == 0)
        {
            $$->type = "int";
            $$->size = size_of_int;
            if (current_symtab->is_global == 1) {$$->category = strdup(current_symtab->name);} // if it's global then we set the category to be the name of the symbol table (Global)
                                                                                                // will need to update in case of functions tho
             if (current_symtab->parent) // is the parent exists ie it's not the global symtab
             {
                $$->category = strdup("local");
             }                                                                                   

        }
        else if (strcmp(type_spec, "char") == 0)
        {
            $$->type = "char";
            $$->size = size_of_char;
            if (current_symtab->is_global == 1) {$$->category = strdup(current_symtab->name);}
            if (current_symtab->parent)
            {
                $$->category = strdup("local");
            }
        }
        else if (strcmp(type_spec, "void") == 0)
        {
            $$->type = "void";
            $$->size = 0;
            if (current_symtab->is_global == 1) {$$->category = strdup(current_symtab->name);}
            if (current_symtab->parent)
            {
                $$->category = strdup("local");
            }
        }
        printrule("direct-declarator-> IDENTIFIER");
        printrule($1);
        // printrule(current_symtab->name);
    } // Simple identifier

    | IDENTIFIER OPEN_SQR_BRACKET INTEGER_CONSTANT CLOSE_SQR_BRACKET
    {
        $$ = symlookup(current_symtab, $1);
        // char * type_spec = strdup($<strval>-1);         // using bison stack to get the type_specifier
        char arr_len_str[5];
        // int arr_len = $3;
        // int arr_size;
        $$->size = $3;

        // if(strcmp(type_spec, "int") == 0)
        // {
        //     arr_size = $3*size_of_int;
        // }
        // else if(strcmp(type_spec, "char") == 0)
        // {
        //     arr_size = $3*size_of_char;
        // }
        // else if(strcmp(type_spec, "char*") == 0 || (strcmp(type_spec, "int*") == 0 ))
        // {
        //     arr_size = $3*size_of_pointer;
        // }
        sprintf(arr_len_str, "%d", $3);
        char arr_type[15];
        sprintf(arr_type, "%s", "arr");
        // printf("Length %s\n", arr_len_str);
        // strcat(arr_type, type_spec);
        // strcat(arr_type, ",");
        // strcat(arr_type, arr_len_str);
        // strcat(arr_type, ")");
        // printf("%s", arr_type);
        update_entry($$, arr_type, "", UNDEFINED_SIZE, UNKNOWN_OFFSET, NULL);
        if (!current_symtab->parent) {$$->category = strdup("Global");}
        else if (current_symtab->parent)
        {
            // printf("In else block\n");
            $$->category = strdup("local");
        }
        // leaving category undefined cause not mentioned and idk whether to put local or arr or smth
        printrule("direct-declarator-> IDENTIFIER [ INTEGER_CONSTANT ]");
    } // 1_D array of a built_in type or ptr to it. Only +ve constant
    
    | IDENTIFIER OPEN_PARENTHESIS parameter_list_opt CLOSE_PARENTHESIS
    {
        // printf("Name of function: %s, Name of current symbol table: %s\n", $1, current_symtab->name);
        // printf("Address of function ST: %p\n", current_symtab); // for debugging
        // print_symtab(current_symtab);  // for debugging
        // print_symtab_debug(current_symtab);  // for debugging
        // symtab * nested_temp = current_symtab; // to remember the func ST for putting it into nested field

        // current_symtab = global_symtab;  
        // $$ = symlookup(current_symtab, $1);                                 // looking up the function in the global symbol table
        // char * type_spec = strdup($<strval>-1);
        // update_entry($$, type_spec, "funct, glb", 0, UNKNOWN_OFFSET, nested_temp);
        
        char * func_name = strdup($1);
        symtab_entry * check_name = search_symtab(global_symtab, func_name); // to prevent double declarations from happening and making duplicate params

        if (!check_name)
        {
            // printf("Function %s not there in the global ST\n", func_name);
            if (strcmp(current_symtab->name, globalstr) == 0)  // if the current symtab is global then make newsymtab for the function
                {
                    symtab* func_ST = new_symtab($1, globalstr);  // giving the name of the function to the function ST usign bison stack
                    current_symtab = func_ST; // need to be careful so as to reassign back to global later
                }
                // if the ST already been created means we already put one param in the function ST so we skip the new_symtab step
            

            arg_expr_list * temp = NULL;
            for (temp = $3; temp != NULL; temp = temp->next)
            {
                // printf("Current ST: %s symtab_entry : %s\n", current_symtab->name, temp->loc->name);
                insert_entry(current_symtab, temp->loc);
            }
            symtab * nested_temp = current_symtab;
            current_symtab = global_symtab;
            $$ = symlookup(current_symtab, $1);
            char * type_spec = strdup($<strval>-1);
            update_entry($$, type_spec, "funct, glb", 0, UNKNOWN_OFFSET, nested_temp);  
        }
        else
        {
            // printf("Function %s already there in the global ST\n", func_name);
            $$ = check_name;
        }
        // printf("REACHED %s\n", $1);
        printrule("direct-declarator-> IDENTIFIER ( parameter_list_opt )");
    } // Fn. header with params of built_in type or ptr to them
    ;


pointer_opt:
    pointer
    {
        $$ = 1;

        printrule("pointer_opt-> pointer");
    }
    | %empty
    {
        $$ = 0;
        printrule("pointer_opt -> epsilon");
    }
    ;

pointer:
    ASTERISK
    {
        printrule("pointer-> ASTERISK");
    }
    ;

parameter_list_opt:
    parameter_list 
    {
        $$ = $1;
    }
    | %empty // func()
    {
        $$ = NULL;
        printrule("parameter_list_opt -> epsilon");
    }
    ;

parameter_list:
    parameter_declaration
    {
        printrule("parameter-list-> parameter_declaration");
    }
    | parameter_list COMMA parameter_declaration
    {
        struct _arg_expr_list * temp = make_list_arg($3->loc, $3->loc->type);
        $$ = merge_lists_arg($1, temp);
        printrule("parameter-list-> parameter_list , parameter_declaration");
    }
    ;


parameter_declaration:
    type_specifier pointer_opt identifier_opt // intval intval strval
    {
        symtab_entry * param_entry = new_entry();
        param_entry->name = strdup($3);
        if (strcmp($1, "int") == 0)
        {
            update_entry(param_entry, $1, "param", size_of_int, UNKNOWN_OFFSET, NULL);
        }
        else if (strcmp($1, "char") == 0)
        {
            update_entry(param_entry, $1, "param", size_of_char, UNKNOWN_OFFSET, NULL);
        }
        else if (strcmp($1, "void") == 0)
        {
            update_entry(param_entry, $1, "param", 0, UNKNOWN_OFFSET, NULL);
        }
        if ($2 == 1)
        {
            if (strcmp($1, "int") == 0) 
            {
                param_entry->type = "int*";
                param_entry->size = size_of_pointer;
            } 
            else if (strcmp($1, "char") == 0) 
            {
                param_entry->type = "char*";
                param_entry->size = size_of_pointer;
            } 
            else if (strcmp($1, "void") == 0) 
            {
                param_entry->type = "void*";
                param_entry->size = size_of_pointer;
            }
        }

        $$ = make_list_arg(param_entry, param_entry->type);

        printrule("parameter-declaration-> type_specifier pointer_opt identifier_opt");
    }
    // Only simple ids of a built_in type or ptr to it as params
    ;

identifier_opt:
    IDENTIFIER
    {
        $$ = strdup($1);
        printrule("identifier_opt -> IDENTIFIER");
        printrule($$);
    }
    | %empty
    {
        $$ = NULL;
    }
    ;

initializer:
    assignment_expression
    {
        $$=$1->loc;
        printrule("initializer-> assignment_expression");
    }
    ;



statement:
    compound_statement
    {
        $$ = init_statement();
        $$->nextlist = $1->nextlist;
        printrule("statement-> compound_statement");
    } // Multiple statements and / or nest block/s
    | expression_statement // here can put the slide wala thing
    {
        $$ = init_statement();
        $$->nextlist = $1->nextlist;
        printrule("statement-> expression_statement");
    } // Any expression or null statements
    | selection_statement
    {
        $$ = init_statement();
        $$->nextlist = $1->nextlist;
        printrule("statement-> selection_statement");
    } // if or if_else
    | iteration_statement
    {
        $$ = init_statement();
        $$->nextlist = $1->nextlist;
        printrule("statement-> iteration_statement");
    } // for
    | jump_statement
    {
        $$ = init_statement();
        $$->nextlist = $1->nextlist;
        // printf("REACHED\n");
        printrule("statement-> jump_statement");
    } // return
    ;

block_item_list_opt:
    block_item_list
    {
        $$ = $1;
    }
    | %empty
    {
        ;           // what to do here??
    }
    ;

compound_statement:
    OPEN_CURLY_BRACE block_item_list_opt CLOSE_CURLY_BRACE
    {
        $$ = init_statement();
        $$->nextlist = $2->nextlist;
        printrule("compound-statement-> {block_item_list_opt}");
    }
    ;

block_item_list:
    block_item
    {
        $$ = init_statement();
        $$->nextlist = $1->nextlist;
        // printf("Nextlist of block item: \n");
        // print_list($1->nextlist);
        printrule("block-item-list-> block_item");
    }
    | block_item_list M block_item
    {   
        $$ = init_statement();
        // printf("Nextlist of block item list: \n");
        // print_list($1->nextlist);
        backpatch($1->nextlist, $2);
        $$->nextlist = $3->nextlist;
        printrule("block-item-list-> block_item_list block_item");
    }
    ;


block_item: // Block scope _ declarations followed by statements
    declaration
    {
        $$ = init_statement();
        $$->nextlist = NULL;
        printrule("block-item-> declaration");
    }
    | statement
    {
        $$ = init_statement();
        $$ = $1;
        printrule("block-item-> statement");
    }
    ;

expression_opt:
    expression
    {
        $$ = $1;
        printrule("expression_opt-> expression");
    }
    | %empty
    {
        $$ = NULL;
        printrule("expression_opt-> epsilon");
    }
    ;

expression_statement:
    expression_opt SEMICOLON
    {
        $$ = init_statement();
        $$->nextlist = $1->nextlist;
        printrule("expression-statement-> expression_opt ;");
    }
    ;


selection_statement:
    IF OPEN_PARENTHESIS expression CLOSE_PARENTHESIS M statement
    {
        $$ = init_statement();
        // if we're doing smth like if(i) so need implicit bool
        if(strcmp(search_symtab(current_symtab,$3->loc->name)->category, "temp") != 0)
        {
            // printf("in if\n");
            $3 = int2bool($3);
        }
        // print_quad_array(quad_array, quad_counter);
        // printf("Truelist of %s: ", $3->loc->name);
        // print_list($3->truelist);
        // printf("Falselist of %s: ", $3->loc->name);
        // print_list($3->falselist);
        // printf("Nextlist of statement:\n");
        // print_list($6->nextlist);
        // printf("REACHED\n");
        // printf("M val: %i\n", $5);
        backpatch($3->truelist, $5);
        $$->nextlist = merge_lists($3->falselist, $6->nextlist);
        printrule("selection-statement-> IF ( expression ) statement");
    }
    | IF OPEN_PARENTHESIS expression /*N1*/ CLOSE_PARENTHESIS M statement N1 ELSE M statement
    {
        // backpatch($4->nextlist, quad_counter+1);
        $$ = init_statement();
        if(strcmp(search_symtab(current_symtab,$3->loc->name)->category, "temp") != 0)
        {
            // printf("in if\n");
            $3 = int2bool($3);
        }
        // printf("Truelist of %s: \n", $3->loc->name);
        // print_list($3->truelist);
        // printf("Falselist of %s: \n", $3->loc->name);
        // print_list($3->falselist);

        backpatch($3->truelist, $5);
        backpatch($3->falselist, $9);
        list * temp;
        temp = genList(); // use genlist or makelist here?
        temp = merge_lists($6->nextlist, $7->nextlist);
        $$->nextlist = merge_lists(temp, $10->nextlist);
        printrule("selection-statement-> IF ( expression ) statement ELSE statement");
    }
    ;

iteration_statement:
    // to allow implicit boolean type here we can set an isBoolean field of the Expression struct to be 1 or 0 and based on that value we can
    // treat it as a boolean or not here. Here set isBoolean of the Expression to 1
    
    FOR OPEN_PARENTHESIS expression_opt SEMICOLON M expression_opt SEMICOLON M expression_opt N2 CLOSE_PARENTHESIS M statement
    {
        $$ = init_statement();
        if(strcmp(search_symtab(current_symtab,$6->loc->name)->category, "temp") != 0)
        {
            // printf("in if\n");
            $6 = int2bool($6);
        }
        // printf("REACHED\n");
        if ($6) {backpatch($6->truelist, $12);}
        if ($6) {backpatch($10->nextlist, $5);}
        if ($6) {backpatch($13->nextlist, $8);}
        char m2_str[100];
        sprintf(m2_str, "%d", $8);
        quad_array[quad_counter++] = new_quad_instr(op_JUMP, m2_str);
        if ($6){$$->nextlist = $6->falselist;}
        printrule("iteration-statement-> FOR ( expression_opt ; expression_opt ; expression_opt ) statement");
    }
    ;


jump_statement:
    RETURN expression_opt SEMICOLON
    {
        $$ = init_statement();
        // printf("%s", $2->loc->name);
        if ($2)
        {
            quad_array[quad_counter++] = new_quad_instr(op_RET, $2->loc->name);
        }
        else
        {
            quad_array[quad_counter++] = new_quad_instr(op_RET, "");
        }
        // printf("REACHED HERE\n");
        printrule("jump-statement-> RETURN expression_opt ;");
    }
    ;


translation_unit:
    external_declaration
    {
        current_symtab = global_symtab;
        printrule("translation-unit-> external_declaration");
    }
    | translation_unit external_declaration
    {
        printrule("translation-unit-> translation_unit external_declaration");
    }
    ;

external_declaration:
    declaration
    {
        printrule("external-declaration-> declaration");
    }
    | function_definition
    {
        printrule("external-declaration-> function_definition");
    }
    ;

function_definition:
    type_specifier declarator function_guard compound_statement
    {
        $3 = strdup($2->name);
        current_symtab = global_symtab;
        printrule("function-definition-> type_specifier declarator compound_statement");
    }
    ;


%%

void yyerror(char *s)
{
    printf("Error: %s on '%s'\n",s,yytext);
}



