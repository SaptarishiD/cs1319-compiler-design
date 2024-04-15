#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "7_A4_translator.h"


int yylex();
int yyparse();
extern void yyerror(char *s);


symtab* current_symtab;
symtab* global_symtab;

quad* quad_array[QUAD_ARRAY_LEN];
int   quad_counter = 0;



// try to rewrite the file everytime or maintain smth which delimits each time I run the code. add the delimiter print in the main function
void printrule(char *s) {
	FILE *fp = fopen("trace.txt", "a");
	if (fp) {
		fprintf(fp, "%s\n", s);
	}
	fclose(fp);
}


// Destructor for symtab_entry
void free_entry(symtab_entry* sp)
{
	if (!sp) {
		fprintf(stderr, "Trying to free NULL symtab_entry.");
		exit(EXIT_FAILURE);
	}
	if (sp->name) {free(sp->name);}
	if (sp->type) {free(sp->type);}
	if (sp->nested_table)
	{
		// RECURSIVELY FREE NESTED SYMBOL TABLES
		// TODO: Check for correctness
			// since clearly, if the parent scope has gone out of scope and is about to be freed,
			// we clearly don't need the child
			free_symtab(sp->nested_table);
	}
	free(sp);
	return;
}

// Constructor for struct symtab
symtab* new_symtab(char * name, char * parent)
{
	symtab* stab = (symtab*) malloc(sizeof(symtab));
	if (!stab) {
		yyerror("Couldn't create new symbol table.");
		exit(EXIT_FAILURE);
	}
	if (name) {stab->name = strdup(name);}
	else {stab->name = NULL;}

	char globalstr[10] = "Global";
	if (strcmp(name, globalstr) == 0) {stab->is_global = 1;}
	else {stab->is_global = 0;}

	if (parent) {stab->parent = strdup(parent);}
	else {stab->parent = NULL;}

	stab->size = DEFAULT_SYMTAB_SIZE;
	stab->symboltable = (symtab_entry**) calloc(stab->size, sizeof(symtab_entry*));
	return stab;
}

void resize_symtab(symtab* st, resize_option opt)
{
    int new_size = 0;
	switch (opt) {
		// When n_elems is size - 1, call this before inserting
		case INCREASE:
			new_size = st->size * 2;
			st->symboltable = realloc(st->symboltable, new_size * sizeof(symtab_entry*));
			st->size = new_size;
			break;
		// When n_elems is < 0.4*size, call this before inserting
		case DECREASE:
			new_size = 1 + (st->size / 2);
			st->symboltable = realloc(st->symboltable, new_size * sizeof(symtab_entry*));
			st->size = new_size;
			break;
		default:
			return;
	}
	return;
}


void insert_entry(symtab* st, symtab_entry* entry)
{
	if (!st || !entry) {
		fprintf(stderr, "Symtab Insert error: pointer undefined.");
		exit(EXIT_FAILURE);
	}
	if (st->n_elems == st->size - 1) {
		resize_symtab(st, INCREASE);
	}
	// if there n elements, all indexes upto n-1 are used, and the next free index is n
	st->symboltable[st->n_elems] = entry;
	st->n_elems++;
	return;
}

// Constructor for symtab_entry
symtab_entry* new_entry()
{
	symtab_entry* sp = (symtab_entry*) malloc(sizeof(symtab_entry));
	if (!sp) {
		yyerror("Couldn't create symbol table entry.");
		exit(EXIT_FAILURE);
	}
	sp->name = NULL;
	sp->type = NULL;
	sp->category = NULL;
	sp->initial_val = NULL;
	sp->size = UNDEFINED_SIZE;
	sp->offset = UNKNOWN_OFFSET;
	sp->nested_table = NULL;
	return sp;
}

symtab_entry* search_symtab(symtab* st, char* entry_name)
{
	symtab_entry* sp;
	for (int i = 0; i < st->size; i++)
	{
		sp = st->symboltable[i];
		if (!sp) {continue;}            // why is this there??
        // it's already there in the symbol table
		if (sp->name && !strcmp(sp->name, entry_name)) 
		{
			return sp;
		}
	}
	// Not found
	return NULL;
}

symtab_entry* symlookup(symtab* st, char *s)
{
	symtab_entry* sp = search_symtab(st, s);
	if (!sp) {
		// ensuring that the symtab entry has ownership of "name"
		sp = new_entry();
		sp->name = strdup(s);
		insert_entry(st, sp);
	}
	return sp;
}

void free_symtab(symtab* stab)
{
	if (!stab) {
		yyerror("Trying to free NULL symbol table.");
		exit(EXIT_FAILURE);
	}
	if (stab->name) {free(stab->name);}
	if (stab->symboltable) {
		symtab_entry* sp;
		for (int i = 0; i < stab->size; i++)
		{
			sp = stab->symboltable[i];
			if (sp) {free_entry(sp);}
		}
	}
	return;
}

// Generate temporaries t00, t01, t02, ....
symtab_entry* gentemp(symtab* symboltable)
{
	static int counter = 0; // static variables's values are preserved across function calls
	char str[10];           // make this as needed so stuff like t204729347028374 can be supported?
	// that is insanely long, won't have more than like 5000 temp in the worst case i think
	sprintf(str, "t%04d", counter++);
	symtab_entry* sp = symlookup(symboltable, str);
	sp->category = strdup("temp");
	return sp;
}


void print_symtab_debug(symtab* symbol_table)
{
	if (!symbol_table) {return;}

	printf("=====================================================================================================================\n");

	printf("Symtab for debugging and seeing size offsets and initial vals and stuff since they haven't asked for all this\n\n");
	if (symbol_table->parent)
		{printf("ST: %s, Parent: %s\n", symbol_table->name, symbol_table->parent);}

	else 							
		{printf("ST: %s, Parent: null\n", symbol_table->name);}
	printf("=====================================================================================================================================================\n");

	printf("Name, \t\t\t  Type,\t\t\t  Init_val, \t\t\t Size, \t\t Offset, \t\t Category,\t\tNested_Table\n");
	printf("=====================================================================================================================================================\n");

	for (int i = 0; i < symbol_table->n_elems; i++)
	{
		symtab_entry* entry_ptr = symbol_table->symboltable[i];
		char null_str[] = "null";
		char initial_val_str[100]; // maybe increase this
		sprintf(initial_val_str, "%d", entry_ptr->initial_val);

		// numbers in the formatting are for left and right alignment
		if (entry_ptr->nested_table)
		{
			printf("%5s%5, \t\t  %8s%8, \t\t  %8s%8, \t\t  %8i%8, \t\t  %8i%8, \t\t  %8s%8, \t\t %p\n", entry_ptr->name, 
			(entry_ptr->type != NULL) ? entry_ptr->type : null_str, entry_ptr->initial_val, entry_ptr->size, entry_ptr->offset, (entry_ptr->category != NULL) ? entry_ptr->category : null_str
			, entry_ptr->nested_table);
			printf("-------------------------------------------------------------------------------------------------------------------------------------------\n");

		}
		else
		{
			printf("%5s%5, \t\t  %8s%8, \t\t  %8s%8, \t\t  %8i%8, \t\t  %8i%8,  \t\t  %8s%8, \t\t     null\n", 
			entry_ptr->name, (entry_ptr->type != NULL) ? entry_ptr->type : null_str,entry_ptr->initial_val, entry_ptr->size, entry_ptr->offset, (entry_ptr->category != NULL) ? entry_ptr->category : null_str);
			printf("--------------------------------------------------------------------------------------------------------------------------------------------\n");

		}
	}
	printf("=====================================================================================================================================================\n\n\n");

}


void print_symtab(symtab* symbol_table)
{
	if (!symbol_table) {return;}

	printf("=====================================================================================================================\n");

	if (symbol_table->parent)
		{printf("ST: %s, Parent: %s\n", symbol_table->name, symbol_table->parent);}

	else 							
		{printf("ST: %s, Parent: null\n", symbol_table->name);}
	printf("=====================================================================================================================================================\n");

	printf("Name, \t\t\t  Type,\t\t\t  Category / Scope, \t\t Nested_Table\n");
	printf("=====================================================================================================================================================\n");

	for (int i = 0; i < symbol_table->n_elems; i++)
	{
		symtab_entry* entry_ptr = symbol_table->symboltable[i];
		char null_str[] = "null";
		char initial_val_str[100]; // maybe increase this
		sprintf(initial_val_str, "%d", entry_ptr->initial_val);

		// numbers in the formatting are for left and right alignment
		if (entry_ptr->nested_table)
		{
			printf("%5s%5, \t\t  %8s%8, \t\t  %8s%8, \t\t %p\n", 
			entry_ptr->name, (entry_ptr->type != NULL) ? entry_ptr->type : null_str, (entry_ptr->category != NULL) ? entry_ptr->category : null_str, entry_ptr->nested_table);
			printf("-------------------------------------------------------------------------------------------------------------------------------------------\n");

		}
		else
		{
			printf("%5s%5, \t\t  %8s%8, \t\t  %8s%8, \t\t     null\n", 
			entry_ptr->name, (entry_ptr->type != NULL) ? entry_ptr->type : null_str, (entry_ptr->category != NULL) ? entry_ptr->category : null_str);
			printf("--------------------------------------------------------------------------------------------------------------------------------------------\n");

		}
	}
	printf("=====================================================================================================================================================\n\n\n");

}


// update(...) A method to update different fields of an existing entry // <- not needed because we can dereference the entry and change the related values in the struct

//===================================================

//===================================================

// Constructor for struct quad
quad* gen_quad()
{
	quad *q = (quad *)malloc(sizeof(quad));
	if (!q) {
		yyerror("Couldn't generate new quad.");
		exit(EXIT_FAILURE);
	}
	q->op 		= op_NONE,
	q->result 	= NULL;
	q->arg1   	= NULL;
	q->arg2   	= NULL;
	return q;
}

// Destructor for struct quad
void free_quad(quad* q)
{
	if (!q)
	{
		yyerror("Trying to free a quad that doesn't exist.");
		exit(EXIT_FAILURE);
	}
	if (q->result) 	{free(q->result);}
	if (q->arg1) 	{free(q->arg1);}
	if (q->arg2) 	{free(q->arg2);}
	free(q);
	return;
}

// Binary Assignment
// For quads of the type result = arg1 op arg2
/*
1. binary op
2. res(y) = op(call) arg1(proc) arg2(N_params)
3. indexd copy: result = arg1[arg2], where op = op_INDEX
4. indexd result: result[arg1] = arg2, where op = op_INDEX_res
*/
quad* new_quad_binary(opcodetype op1, char *result, char *arg1, char *arg2)
{
	quad *q = gen_quad();
	q->op = op1;
	// printf("gen_quad\n");
	if (result) {q->result = strdup(result);}
	else {q->result = NULL;}
	// printf("%s \n", q->result);
	// printf("%p\n", q->result);
	q->arg1 = strdup(arg1);
	q->arg2 = strdup(arg2); // 0x1342045f0
	return q;
}

// supports:
/*
1. copy: result = arg1
2. unary: result = op1 arg1
3. conditional jump: arg(condition) op(goto) result(label)
// todo \/
4. pointer/addr assign: op(op_res_STAR or op_res_AND) result = arg1
*/
quad* new_quad_unary(opcodetype op1, char *result, char *arg)
{
	quad *q = gen_quad();
	q->op = op1;
	q->result = strdup(result);
	q->arg1 = strdup(arg);
	return q;
}

// supports:
/*
1. unconditional jump: op(goto) result(label)
2. param: op(param) result(arg)
3. return: op(return) result(arg)
*/
quad* new_quad_instr(opcodetype op, char* result)
{
	quad *q = gen_quad();
	q->op = op;
	q->result = strdup(result);
	return q;;
}


// void print_quad(quad* q, int index)
// {
// 	char* tac = print_tac(q);
// }

// TODO: have to specify different print targets for different types of TAC
void print_quad(quad* q, int index)
{
	if (!q) {return;}
	char tac[50];
	if (q->op == op_EQUAL)
	{
		// printf("print_quad\n");
		// printf("%p\n", q->result);
		sprintf(tac, "%s = %s %s %s", q->result, q->arg1, print_opcode(q->op), q->arg2);
	}
	else if (op_PLUS <= q->op && q->op < op_MOD) {
		sprintf(tac, "%s = %s %s %s", q->result, q->arg1, print_opcode(q->op), q->arg2); // DO THIS
	}
	else if (q->op == op_MOD)
	{
		sprintf(tac, "%s = %s %s %s", q->result, q->arg1, print_opcode(q->op), q->arg2); // DO THIS
	}

	else if (op_UMINUS <= q->op && q->op <= op_USTAR) {
		sprintf(tac, "%s = %s%s", q->result, print_opcode(q->op), q->arg1);
	}

	else if (op_ResSTAR <= q->op && q->op <= op_ResAND) {
		sprintf(tac, "%s%s = %s", print_opcode(q->op), q->result, q->arg1);
	}

	else if (op_LESS <= q->op && q->op <= op_NOTEQUAL) {
		sprintf(tac, "%s = %s %s %s", q->result, q->arg1, print_opcode(q->op), q->arg2);
	}

	else if (op_LOGICAL_AND <= q->op && q->op <= op_LOGICAL_OR) {
		sprintf(tac, "%s = %s %s %s", q->result, q->arg1, print_opcode(q->op), q->arg2);
	}

	else if (op_COPY == q->op) {
		sprintf(tac, "%s = %s", q->result, q->arg1);
	}
	else if (op_JUMP == q->op) {
		sprintf(tac, "%s %s", print_opcode(q->op), q->result);
	}

	else if (op_JUMP_CN == q->op) {
		sprintf(tac, "if %s %s %s", q->arg1, print_opcode(q->op), q->result);
	}

	else if (op_PARAM == q->op) {
		sprintf(tac, "%s %s", print_opcode(q->op), q->result);
	}
	else if (op_CALL == q->op) 
	{
		if (strcmp(q->result, "") == 0)
		{
			sprintf(tac, "%s %s, %s", print_opcode(q->op), q->arg1, q->arg2);
		}
		else
		{
			sprintf(tac, "%s = %s %s, %s", q->result, print_opcode(q->op), q->arg1, q->arg2);
		}
	}
	else if (op_COPY_IND == q->op) {
		sprintf(tac, "%s = %s[%s]", q->result, q->arg1, q->arg2);
	}
	else if (op_ASSIGN_IND == q->op) { // Important: see how this prints and handles the args
		sprintf(tac, "%s[%s] = %s", q->result, q->arg1, q->arg2);
	}
	else if (op_RET == q->op)
	{
		sprintf(tac, "%s %s", print_opcode(q->op), q->result);
	}
	
	else {
		return /*"UNKNOWN"*/; // will tell us there's an issue
	}
	fprintf(stdout, "%d:\t%s\n", index, tac);
}

const char* print_opcode(opcodetype op)
{
    switch (op) {
        case op_PLUS:
            return "+";
        case op_MINUS:
            return "-";
        case op_MULT:
            return "*";
        case op_DIV:
            return "/";
        case op_MOD:
            return "%";

        case op_UMINUS:
            return "-";
        case op_UPLUS:
            return "+";
        case op_UAND:
            return "&";
        case op_UNOT:
            return "!";
        case op_USTAR:
            return "*";

        case op_ResSTAR:
            return "*";
        case op_ResAND:
            return "&";

		case op_LESS:
			return "<";
		case op_LESSEQ:
			return "<=";
		case op_GREATER:
			return ">";
		case op_GREATEREQ:
			return ">=";
		case op_EQUAL:
			return "==";
		case op_NOTEQUAL:
			return "!=";

		case op_LOGICAL_AND:
			return "&&";
		case op_LOGICAL_OR:
			return "||";

		case op_COPY:
			return "";
		case op_JUMP_CN:
			return "goto";
        case op_JUMP:
            return "\t goto";
		case op_PARAM:
			return "param";
		case op_CALL:
			return "call";

		case op_COPY_IND:
			return "";
		case op_ASSIGN_IND:
			return "";
		case op_RET:
			return "return";

        // Add more cases as needed
        default:
            return "UNKNOWN";
    }
}

void init_quad_array(quad** quad_array, int quad_array_size)
{
	for (int i = 0; i < quad_array_size; i++)
	{
		quad_array[i] = NULL;
	}
	return;
}

void print_quad_array(quad** quad_array, int quad_array_size)
{
	if (!quad_array) {return;}
	for (int i = 0; i < quad_array_size; i++)
	{
		if (quad_array[i])
			{print_quad(quad_array[i], i);}
	}
	return;
}
//===================================================
//===================================================


// constructor for struct expression
expression* init_expression()
{
    expression* e = (expression*)malloc(sizeof(expression));
    if (!e) {
        fprintf(stderr, "Couldn't create new expression.");
        exit(EXIT_FAILURE);
    }
    e->loc = NULL;
    e->type = NULL; // Setting void as the default
    // TODO see if "value" needs to be set
    e->intval     = UNDEFINED_INITIAL_VAL;
    e->charval    = '\0';
    e->strval     = NULL;
    e->truelist   = NULL;
    e->falselist  = NULL;
    e->nextlist   = NULL;
	e->isbool  = 0;
	e->isarray = 0;
	e->array_base = NULL;
	e->arr_len = 0;
	e->arr_elem_size = 0;
	e->elem_access = NULL;
    return e;
}


statement* init_statement()
{
    statement* s = (statement*)malloc(sizeof(statement));
    if (!s) {
        fprintf(stderr, "Couldn't create new statement.");
        exit(EXIT_FAILURE);
    }
    s->nextlist = NULL;
    return s;
}



void update_entry(symtab_entry* sp, char* type, char* category, int size, int offset, symtab* nested_table)
{
	if (!sp) {return;}
	if (type) 			            {sp->type = strdup(type);}
	if (category) 	                {sp->category = strdup(category);}
	if (size != UNDEFINED_SIZE)     {sp->size = size;}
	if (offset != UNKNOWN_OFFSET)   {sp->offset = offset;} // can cause issues if offset is =  unknown offset but prolly not
	if (nested_table) 	            {sp->nested_table = nested_table;}
	return;
}

void free_expression(expression* e)
{
    if (!e) {
        fprintf(stderr, "Trying to free a NULL expression.");
        exit(EXIT_FAILURE);
    }
    if (e->loc)         {free(e->loc);              e->loc = NULL;}
    if (e->strval)      {free(e->strval);           e->strval = NULL;}
    if (e->truelist)    {free_list(e->truelist);    e->truelist = NULL;}
    if (e->falselist)   {free_list(e->falselist);   e->falselist = NULL;}
    if (e->nextlist)    {free_list(e->nextlist);    e->nextlist = NULL;}
    free(e);
    return;
}


//===================================================

// Global Functions: Following (or similar) global functions and more may be needed to implement the
// semantic actions:

// typecheck(E1, E2)
// A function to check if E1 & E2 have same types (that is, if <type of E1> = <type of E2>).
// If not, then to check if they have compatible types (that is, one can be converted to
// the other), to use an appropriate conversion function conv<type of E1>2<type of E2>(E) or
// conv<type of E2>2<type of E1>(E) and to make the necessary changes in the Symbol Table
// entries.
// If not, that is, they are of incompatible types, to throw an exception during translation.
void typecheck(expression* E1, expression* E2)
{
	if (!E1 || !E2) {return;}
	if (strcmp(E1->type, E2->type) == 0) {return;}

	else if ( (strcmp(E1->type,"int") == 0) && strcmp(E2->type, "char") == 0) {
		E2->type 		= strdup("int");
		E2->loc->size 	= size_of_int;
		E2->loc->offset = UNKNOWN_OFFSET; // TODO update offset
		return;
	}
	else if ( (strcmp(E1->type,"char") == 0) && strcmp(E2->type, "int") == 0) {
		E1->type 		= strdup("int");
		E1->loc->size 	= size_of_int;
		E1->loc->offset = UNKNOWN_OFFSET; // TODO update offset
		return;
	}
	else {
		fprintf(stderr, "Typecheck error: incompatible types.");
		exit(EXIT_FAILURE);
	}
}

// conv<type1>2<type2>(E)
// A function to converta an expression E from its current type type1 to target type type2, to
// adjust the attributes of E accordingly, and finally to generate additional codes, if needed.
// a
// : This function is called from typecheck(E1, E2). Thus, the conversion is possible.

node* newNode(int num) {
	node* n = (node*) malloc(sizeof(node));
	if (!n) {
		fprintf(stderr, "newNode: malloc error.");
		exit(EXIT_FAILURE);
	}
	n->val = num;
	n->prev = NULL;
	n->next = NULL;
	return n;
}

void freeNode(node* n) {
	free(n);
}

list* genList() {
    list* l = (list*)malloc(sizeof(list));
    l->head = NULL;
    l->tail = NULL;
    l->count = 0;
    return l;
}

void appendNode(list* l, node* n) {
	if (!l || !n) {return;}
	if (!(l->head)) {
		l->head = n;
		l->tail = n;
	}
	else {
		l->tail->next = n;
		n->prev = l->tail;
		l->tail = n;
	}
	l->count++;
	return;
}

// allocates a node with val,
// inserts it into the list structure l
// (while updating the relevant fields)
void insert(list* l, int val)
{
	node* n = newNode(val);
	appendNode(l, n);
	return;
}

list* make_list(int val) {
	list* l = genList();
	insert(l, val);
	return l;
}

void _freeList(node* HEAD)
{
    node* prev;
    while (HEAD)
    {
        prev = HEAD;
        HEAD = HEAD->next;
        free(prev);
    }
}

void free_list(list* l)
{
	_freeList(l->head);
    free(l);
}

//Assume linked list is without loops
void printLinkedList(node* HEAD)
{
    if(HEAD == NULL)
    {
        fprintf(stderr, "Can't print empty list.\n");
        return;
    }
    node* newNode = HEAD;
    while(newNode != NULL)
    {
        char* chars;
        if(newNode->next == NULL) {chars = ".";}
        else {chars = ", ";}
        printf("%d%s", newNode->val,chars);
        newNode = newNode->next;
    }
    printf("\n");
}

void print_list(list* l)
{
	if (l) {printLinkedList(l->head);}
}

// merges l2 into l1 and frees the associated memory with struct of l2.
list* merge_lists(list* l1, list* l2)
{
	if (!l1 && !l2) {return NULL;}
	if (!l1) 		{return l2;}
	if (!l2) 		{return l1;}

	l1->count += l2->count;
	l1->tail->next = l2->head;
	l2->head->prev = l1->tail;
	l1->tail = l2->tail;
	free(l2);
	return l1;
}

list* duplicate_list(list* l)
{
	list* l2 = make_list(l->head->val);
	// starting from 1 instead of 0 because we've already allocated a head.
	node* l_curr = l->head;

	for (int i = 1; i < l->count; i++) {
		insert(l2, l_curr->val);
		l_curr = l_curr->next;
	}

	return l2;
}

void print_array(int_array* a)
{
	int* A = a->list;
	int  l = a->size;
    //printf("l%d\n",l);
    for (int i=0; i<l; i++)
    {
        printf(i? ", %d":"%d", A[i]);
    }
    printf(".\n");
}

//-------

arg_expr_list* make_list_arg(symtab_entry *entry, char * type)
{
	arg_expr_list * mylist = (arg_expr_list*)malloc(sizeof(arg_expr_list));
	mylist->loc = entry;
	mylist->type = strdup(type);
	mylist->next = NULL;
	return mylist;
}

arg_expr_list* merge_lists_arg(arg_expr_list* l1, arg_expr_list* l2)
{
	if (!l1 && !l2) {return NULL;}
	if (!l1) 		{return l2;}
	if (!l2) 		{return l1;}

	arg_expr_list *current = l1;
	while (current->next != NULL) 
	{
		current = current->next;
	}
	current->next = l2;

	return l1;
}

int count_LL_elements_arg(arg_expr_list* l)
{
	if (!l) {return 0;}
	int count = 0;
	arg_expr_list* curr = l;
	while (curr)
	{
		count++;
		curr = curr->next;
	}
	return count;
}


// ====
void update_offsets(symtab* st)
{
	if (!st) {return;}

	// find the first offset
	int offset;
	for (int i = 1; i < st->size; i++)
	{
		symtab_entry* sp = st->symboltable[i];
		if (!sp) {continue;}
		if (sp->category && strcmp(sp->category, "temp") == 0)
		{continue;}
		else
		{
			offset = sp->offset;
			offset += sp->size;
			break;
		}
	}

	int c = st->n_elems-1; // sanity safeguards
	for (int i = 1; i < st->size; i++)
	{
		if (c == 0) {break;}
		c--;
		symtab_entry* sp = st->symboltable[i];
		if (!sp) {continue;}
		if (sp->category && strcmp(sp->category, "temp") == 0)
		{continue;}
		// temporaries won't have an offset
		// (because this da stack we talkin about)
		// ain't no temporary shit on that stack dawg
		sp->offset = offset;
		offset += sp->size;
	}
	return;
}

// ==================================================================================================================================




// TODO
// works only when quad array is global
void backpatch(list* list, int label)
{
	if (!list) 
	{
		// list = make_list(label);
		return;
	}
	node* curr = list->head;
	while (curr)
	{
		char str[10];
		sprintf(str, "%d", label);
		quad_array[curr->val]->result = strdup(str);
		curr = curr->next;
	}
	return;
}

// dont strdup the returned string, it's already a pointer
char* int_to_str(int i)
{
    // largest int is 2^32 - 1 which is 10 digits,
    // sign comes seperately later, maybe add 1 for the null
	char* str = (char*) malloc(11 * sizeof(char));
	sprintf(str, "%d", i);
	return str;
}


//===================================================
expression * int2bool(expression *e)
{
	if (!e) {return NULL;}
	if (e->isbool == 0)
	{
		e->isbool = 1;
		e->truelist = make_list(quad_counter);
		e->falselist = make_list(quad_counter+1);
		char * temp = strdup(e->loc->name);
		strcat(temp, " != 0");

		printf("quad_counter value in int2bool: %i", quad_counter);
		quad_array[quad_counter++] = new_quad_binary(op_JUMP_CN, "", temp, "0");
		quad_array[quad_counter++] = new_quad_instr(op_JUMP, "");
		// printf("int2bool\n");
	}
	return e;
}





param_node * createNode_param(char * type, int has_ptr, char *id) 
{
    param_node *newNode = (param_node *)malloc(sizeof(param_node));

    newNode->data.type = strdup(type);
    newNode->data.has_ptr = has_ptr;
    newNode->data.id = strdup(id);
    newNode->next = NULL;
    return newNode;
}

void insertNode_param(param_node **head, char * type, int has_ptr, char *id) 
{
    param_node *newNode = createNode_param(type, has_ptr, id);

    if (*head == NULL) 
	{
        *head = newNode;
    } 
	else 
	{
        param_node *current = *head;
        while (current->next != NULL) {
            current = current->next;
        }
        current->next = newNode;
    }
}

void printList_param(param_node *head) 
{
    param_node *current = head;
    while (current != NULL) {
        printf("Type: %d, Has Pointer: %d, ID: %s\n", current->data.type, current->data.has_ptr, current->data.id);
        current = current->next;
    }
}

void freeList_param(param_node *head) 
{
    param_node *current = head;
    while (current != NULL) {
        param_node *next = current->next;
        free(current->data.id);
        free(current);
        current = next;
    }
}

void mergeLists_param(param_node **list1, param_node *list2) {
    if (*list1 == NULL) {
        *list1 = list2;
    } else {
        param_node *current = *list1;
        while (current->next != NULL) {
            current = current->next;
        }
        current->next = list2;
    }
}

//===================================================

// Global Functions: Following (or similar) global functions and more may be needed to implement the
// semantic actions:
// makelist(l)
// A function to create a new list containing only l, an index into the array of quad’s, and to
// return a pointer to the newly created list.

// merge(p1, p2)
// A function to concatenate two lists pointed to by p1 and p2 and to return a pointer to the
// concatenated list.

// backpatch(p, l)
// A function to insert l as the target label for each of the quad’s on the list pointed to by p.

// typecheck(E1, E2)
// A function to check if E1 & E2 have same types (that is, if <type of E1> = <type of E2>).
// If not, then to check if they have compatible types (that is, one can be converted to
// the other), to use an appropriate conversion function conv<type of E1>2<type of E2>(E) or
// conv<type of E2>2<type of E1>(E) and to make the necessary changes in the Symbol Table
// entries.
// If not, that is, they are of incompatible types, to throw an exception during translation.

// conv<type1>2<type2>(E)
// A function to converta an expression E from its current type type1 to target type type2, to
// adjust the attributes of E accordingly, and finally to generate additional codes, if needed.
// a
// : This function is called from typecheck(E1, E2). Thus, the conversion is possible.






// ==================================================================================================================================



int main()
{
    #if YYDEBUG
        extern int yydebug;
        yydebug = 1;
    #endif
    char table[] = "Global";
	char * global_parent = NULL;
    global_symtab = new_symtab(table, global_parent);
    current_symtab = global_symtab;
	yyparse();
	FILE * fp = fopen("trace.txt", "a");
	if (fp)
	{
		fprintf(fp, "===============================================\n"); // delimits the trace of every run of the code
	}

    print_symtab(global_symtab);
	// print_symtab_debug(global_symtab); 
	
	for (int i = 0; i < global_symtab->n_elems; i++)
	{
		symtab_entry* entry_ptr = global_symtab->symboltable[i];

		if (entry_ptr->nested_table)
		{
			print_symtab(entry_ptr->nested_table);
			// print_symtab_debug(entry_ptr->nested_table);
		}

	}
	print_quad_array(quad_array, quad_counter);
	fclose(fp);
    free(global_symtab);
}