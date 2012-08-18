#include <stdio.h>
#include <stdlib.h>

unsigned int power (int number, int power);

int main (void) {
   unsigned int n = 10;
	unsigned int x = 3;
   unsigned int i = 0;
   unsigned int sum = 0;
   unsigned int result;
   unsigned int a[n];

   // let p(x) = (x * x^y) + ((x-1) * (x-1)^y) + ... + (1 * (1)^y) + 


   for (i = 0; i < n; i++) {
      a[i] = i; // stores an incrementing number into a[i]...
      result = power (x, i); // powers x^i, 3 to different levels
      sum += result * a[i]; // mulitplies the constant term of the polynomial 
                            // (e.g. i * 3^i)
   }
   printf ("SUM is [%d]\n", sum);
   return 0;
}


unsigned int power (int number, int power) {
   unsigned int i = 0;
   unsigned int num = 1;
   for (i = 0; i < power; i++) {
      num *= number;
   }
   return num;
}
