#include <stdio.h>
const int n1 = 25;
const int n2 = 39;
int main() 
{
    int num1, num2, diff;
    num1 = n1;
    num2 = n2;
    diff = num1 - num2;

    if (num1 - num2 < 0)
    {
    diff = -diff;
    }

    printf("\nThe absoute difference is: %d", diff);

    return 0;
}