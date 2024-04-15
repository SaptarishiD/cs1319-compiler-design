// Add two numbers
int main()
{
    int x = 2;
    int y = 3;
    int z;
    z = x + y;
    printInt(x);
    printStr("+");
    printInt(y);
    printStr(" = ");
    printInt(z);
    return 0;
}

// Add two numbers from input
int main()
{
    int x;
    int y;
    int z;
    readInt(&x);
    readInt(&y);
    z = x + y;
    printInt(x);
    printStr("+");
    printInt(y);
    printStr(" = ");
    printInt(z);
    return 0;
}

// Swap two numbers
void swap(int *, int *);
int main()
{
    int x;
    int y;
    readInt(&x);
    readInt(&y);
    printStr("Before swap:\n");
    printStr("x = ");
    printInt(x);
    printStr(" y = ");
    printInt(y);
    swap(&x, &y);
    printStr("\nAfter swap:\n");
    printStr("x = ");
    printInt(x);
    printStr(" y = ");
    printInt(y);
    return 0;
}
void swap(int *p, int *q)
{
    int t;
    t = *p;
    *p = *q;
    *q = t;
    return;
}

// Find factorial by iteration
int main()
{
    int n;
    int i = 0;
    int r = 1;
    readInt(&n);
    for (i = 1; i <= n; i = i + 1)
        r = r * i;
    printInt(n);
    printStr("! = ");
    printInt(r);
    return 0;
}

// Find max of n numbers using array
int main()
{
    int n;
    int a[10];
    int m;
    int i;
    readInt(&n);
    for (i = 0; i < n; i = i + 1)
    {
        readInt(&m);
        a[i] = m;
    }
    m = a[0];
    for (i = 1; i < n; i = i + 1)
    {
        if (a[i] > m)
            m = a[i];
    }
    printStr("Max of: ");
    printInt(a[0]);
    for (i = 1; i < n; i = i + 1)
    {
    }
    printStr(", ");
    printInt(a[i]);
}
printStr(": = ");
printInt(m);
return 0;

// Find factorial by recursion
int factorial(int n)
{
    if (n == 0)
        return 1;
    else
        return n * factorial(n - 1);
}
int main()
{
    int n = 5;
    int r;
    r = factorial(n);
    printInt(n);
    printStr("! = ");
    printInt(r);
    return 0;
}

// Find fibonacci by co-recursion
int f_odd(int);
int f_even(int);
int fibonacci(int n)
{
    return (n % 2 == 0) ? f_even(n) : f_odd(n);
}
int f_odd(int n)
{
    return (n == 1) ? 1 : f_even(n - 1) + f_odd(n - 2);
}
int f_even(int n)
{
    return (n == 0) ? 0 : f_odd(n - 1) + f_even(n - 2);
}
int main()
{
    int n = 10;
    int r;
    r = fibonacci(n);
    printStr("fibo(");
    printInt(n);
    printStr(") = ");
    printInt(r);
    return 0;
}

// Forward declarations
void swap(int *p, int *q);
void readArray(int size);
void printArray(int size);
void bubbleSort(int n);

int arr[20]; // Global array
// Driver program to test above functions
int main()
{
    int n;
    printStr("Input array size: \n");
    readInt(&n);
    printStr("Input array elements: \n");
    readArray(n);
    printStr("Input array: \n");
    printArray(n);
    bubbleSort(n);
    printStr("Sorted array: \n");
    printArray(n);
    return 0;
}
void swap(int *p, int *q)
{ /* Swap two numbers */
    int t = *p;
    *p = *q;
    *q = t;
}
void readArray(int size)
{ /* Function to read an array */
    int i;
    for (i = 0; i < size; i = i + 1)
    {
        printStr("Input next element\n");
        readInt(&arr[i]);
    }
}
void printArray(int size)
{ /* Function to print an array */
    int i;
    for (i = 0; i < size; i = i + 1)
    {
        printInt(arr[i]);
        printStr(" ");
    }
    printStr("\n");
}
void bubbleSort(int n)
{ /* A function to implement bubble sort */
    int i;
    int j;
    for (i = 0; i < n - 1; i = i + 1)
        // Last i elements are already in place
        for (j = 0; j < n - i - 1; j = j + 1)
            if (arr[j] > arr[j + 1])
                swap(&arr[j], &arr[j + 1]);

    int arr[10]; // Sorted array to search
    // A recursive binary search function. It returns location of x // in given array arr[l..r] is present, otherwise -1
    int binarySearch(int l, int r, int x)
    {
        if (r >= l)
        {
            int mid = l + (r - l) / 2;
            // If the element is present at the middle itself
            if (arr[mid] == x)
                return mid;
            // If element is smaller than mid, then it can only be present in left subarray
            if (arr[mid] > x)
        }

        return binarySearch(l, mid - 1, x);
        // Else the element can only be present in right subarray
        return binarySearch(mid + 1, r, x);
    }
    // We reach here when element is not present in array
    return -1;
}

int main()
{
    int n = 5; // Number of elements arr[0] = 2;
    arr[1] = 3;
    arr[2] = 4;
    arr[3] = 10;
    arr[4] = 40;

    int x = 10; // Key to search
    int result = binarySearch(0, n - 1, x);
    if (result == -1)
        printStr("Element is not present in array");
    else
    {
        printStr("Element is present at index ");
        printInt(result);
    }
    return 0;
}

/* The above test cases are taken from the assignment pdf */
/* Our Test Cases Begin here ==========================================================================*/

char* s = "asdfjaslkjdfsda"; // String Literal, Punctuator, whitespace
b = 43281940; // Identifier and Numeric Constants
int allowed = 009032412;

int mewmew = +2814234;
int negativemew = -4812304;

// c = 00012312313 /* ; // Well-functioning Single line comment

// string literal 
char* abc = "asfldsjf // asdfasdkjfs";     

// The closing */ of a multiline comments is detected as punctuator since the corresponding /* is inside string
// The corresponding string is correctly detected as a string literal
char* xyz = "this should not be a comment /* " */;

// Comments undetected in a multibyte character
char xz = 'a//'
char newlineescape = '\a\a\a\n';
char quotes = '\"'; 
char ca = 'keyoard smash //a'; 

printStr("\"");
printStr("\"\a\a\n");
printStr("\"\'\n");
printStr(//)
printStr(/* commented*/)
char no = '\\\"\''
char ba = 'keyoard smash /*a';  
str = smth */

"x//y" // string-literal
// */ // comment
x=y/**//z; // x = y / z;

x=y//**/z
+ p; // x = y + p;


char not_newline = 'abc\n'


/* this will be commented*/ but this wont since not greedy in this case */

/* this should be commented */

/* and this as well **

* ffklsfjdjfj 
* yes this line as well 
 */

/* but if we do this /* trying out an mlc
* line 1 
* line 2 
* shows that multi line comments aren't nested
*/

// Again these will be punctuators
*/ -> this line wont be commented out 

// /* this ---- will be commented
*/ not this either 

char xz = 'a/*'  
this shouldnt be commented either
*/

int not_allowed1 = -04234;
int not_allowed2 = +04234;

char not_newline = 'abc
\n'

/* Other invalid things which our code can handle but we have put them
in a comment since invalids terminate the lexer

"multiline string
"

'multichar const
'




*/

