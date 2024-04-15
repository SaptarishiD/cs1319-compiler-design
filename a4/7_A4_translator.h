#ifndef __TRANSLATOR_H
#define __TRANSLATOR_H 

#include <stdbool.h>
//---------------------------------------------------------------
// # defines
#define NOT_APPLICABLE __UINT_LEAST32_MAX__-5
#define UNDEFINED_SIZE -1
#define UNDEFINED_INITIAL_VAL -2
#define UNKNOWN_OFFSET -3

#define DEFAULT_SYMTAB_SIZE 1000

#define QUAD_ARRAY_LEN 1000


extern struct _quad*  quad_array[];
extern int quad_counter;
//---------------------------------------------------------------
// # declarations and typedefs
struct _symtab_entry;
struct _symtab;
struct _int_arr;
struct _attributes;
struct _expression;
struct _node;
struct _list;
struct _quad;

enum _primitive_types;
enum _opcodetype;
enum _resize_option;

union _types_union;

typedef struct _symtab_entry symtab_entry;
typedef struct _symtab symtab;
typedef struct _int_arr int_array;
typedef struct _attributes attributes;
typedef struct _expression expression;
typedef struct _statement statement;


typedef struct _node node;
typedef struct _list list;
typedef struct _quad quad;

typedef enum _primitive_types primitive_types;
typedef enum _opcodetype opcodetype;
typedef enum _resize_option resize_option;

typedef union _types_union types_union;

//---------------------------------------------------------------
// # structs and enums

struct _symtab_entry
{
    char*    name;
    char*    type;           // int, char, void, ptr etc
    char*    category;      // global local param temp etc
    char*    initial_val;  
    int      size;
    int      offset;
    symtab*  nested_table;
    int      isptr;
};


struct _symtab
{
    int             size;
    int             n_elems;
    int             is_global;
    char*           name;   // name of the ST
    char*           parent; // parent of the ST
    symtab_entry**  symboltable;
} ;

struct _int_arr {
    int size;
    int n_elems;
    int* list;
} ;

//-----------

struct _attributes {
    // TODO
	char* type;
	int   intval;
	char  charval;
	list* truelist;
	list* falselist;
	list* nextlist;
};


struct _expression {
    symtab_entry*   loc;
	char*           type;                
	int             intval;
	char*           charval; 
    char*           strval;  // careful about the *
	list*           truelist;
	list*           falselist;
	list*           nextlist;
    int             isbool;
    int             isarray;
    symtab_entry*   array_base;
    int             arr_len;
    int             arr_elem_size;
    char *          elem_access;
} ;
//-----------

struct _statement {
    list * nextlist;
};



// Define the linked list node structure for param (this was unused)
typedef struct _param_node {
    struct _param {
    char * type;
    int has_ptr;
    char * id;
    }data;
    struct _param_node *next;
} param_node;



struct _param_node *createNode_param(char * type, int has_ptr, char *id);
void insertNode_param(struct _param_node **head, char * type, int has_ptr, char *id);
void printList_param(struct _param_node *head);
void freeList_param(struct _param_node *head);
void mergeLists_param(struct _param_node **list1, struct _param_node *list2);



//-----------

struct _node
{
    int val;
    struct _node *next;
    struct _node *prev;
} ;

struct _list
{
    node* head;
    node* tail;
    int count;
} ;



// Primitive Data Types
enum _primitive_types {
    /* all our allowed primitive types go here */
    type_INT,
    type_CHAR,
    type_VOID,
} ;

union _types_union {
    int intval;
    char charval;                 // yytext is a string tho so how to deal with that maybe this should be a char * but then malloc stuff?? can just strcpy
    char* strval;
} ;


// Types for the OPCODE
enum _opcodetype {
    op_NONE = 0, // Used for initialising an empty quad

    op_PLUS = 1,
    op_MINUS,
    op_MULT,
    op_DIV,
    op_MOD,

    op_UMINUS,
    op_UPLUS,
    op_UAND,        // y = &x
    op_UNOT,        // y = !x
    op_USTAR,       // y = *x

    op_ResSTAR,     // *x = y
    op_ResAND,      // &x = y

    // op_RELOP,       // relation op: <, >, <=, >=, ==, !=
    op_LESS,        // y = x < z
    op_GREATER,     // y = x > z
    op_LESSEQ,      // y = x <= z
    op_GREATEREQ,   // y = x >= z
    op_EQUAL,       // y = x == z
    op_NOTEQUAL,    // y = x != z

    op_LOGICAL_AND, // y = x && z
    op_LOGICAL_OR,  // y = x || z

    op_COPY,        // Assignment
    op_JUMP_CN,     // Conditional Jump (incl. value/comparison/control flow based)
    op_JUMP,        // Unconditional Jump
    op_PARAM,       // for setting param x1,
    op_CALL,        // y = call p, N

    op_COPY_IND,    // x = y[z]
    op_ASSIGN_IND,  // x[z] = y
    op_RET
} ;

struct _quad
{
    // Fill in the 4 fields
    opcodetype op;
    char       *result;
    char       *arg1;
    char       *arg2;
};

enum _resize_option {
	INCREASE = 1,
	DECREASE = 2
} ;

//---------------------------------------------------------------
// # globals
extern symtab* current_symtab; // Keep tab of which symbol table is to be used for current scope // without mentioning struct was giving some error
extern symtab* global_symtab;


extern quad*  quad_array[];
extern int quad_counter;

// QUAD ARRAY WILL BE A GLOBAL ARRAY
// extern quad** quad_array;
extern quad*  quad_array[];
extern int quad_counter;

extern const unsigned int size_of_char;
extern const unsigned int size_of_int;
extern const unsigned int size_of_pointer;


//---------------------------------------------------------------
// # functions

// Symbol Table
symtab_entry*   new_entry(); // imp
void            free_entry(symtab_entry* sp);
//---
symtab*         new_symtab(char* name, char* parent_name); // imp
void            resize_symtab(symtab* st, resize_option opt);
void            insert_entry(symtab* st, symtab_entry* entry);
symtab_entry*   search_symtab(symtab* st, char* entry_name);
void            free_symtab(symtab* stab);
//---
symtab_entry*   symlookup(symtab* st, char *s); // imp
symtab_entry*   gentemp(symtab* symboltable);   // imp
void            print_symtab(symtab* symbol_table); // imp
void            print_symtab_debug(symtab* symbol_table); // imp
//---

void            update_entry(symtab_entry* sp, char* type, char* category, int size, int offset, symtab* nested_table);

// Expressions
expression*     init_expression();
void            free_expression(expression* e);

// Statements
statement*     init_statement();

// Labels and backpatching
void            insert(list* l, int val);
list*           make_list(int val);
list*           merge_lists(list* l1, list* l2);
list*           duplicate_list(list *l);
void            free_list(list* l);
void            print_list(list* l);
list*           genList();
//---
void            backpatch(list* list, int label);
//---


// Quads
quad*           new_quad_binary(opcodetype op1, char *result, char *arg1, char* arg2);
quad*           new_quad_unary (opcodetype op1, char *result, char *arg);
quad*           new_quad_instr(opcodetype op, char* result);
void            print_quad     (quad* q, int index);
const char*     print_opcode(opcodetype op);
void            init_quad_array(quad** quad_array, int quad_array_size);
void            print_quad_array(quad** quad_array, int quad_array_size);

// types and conversions
void            typecheck(expression* e1, expression* e2); // TODO : ensure

// convert int to string
char*           int_to_str(int i);


// Arrays
void            print_array(int_array* a);
void printrule(char *s);
//---------------------------------------------------------------

expression * int2bool(expression *e);
void printLinkedList(node* HEAD);


// arg expr list



typedef struct _arg_expr_list {
    struct _symtab_entry * loc;
    char * type;
    struct _arg_expr_list *next;
} arg_expr_list;



arg_expr_list*           make_list_arg(symtab_entry *entry, char * type);
arg_expr_list*           merge_lists_arg(arg_expr_list* l1, arg_expr_list* l2);
int count_LL_elements_arg(arg_expr_list* l);



#endif