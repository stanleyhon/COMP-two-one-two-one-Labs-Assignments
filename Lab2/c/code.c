#include <stdio.h>
#include <stdlib.h>

int partition (int * array, int p, int r) {
  
  printf("p=%d, r=%d\n",p,r);

  int pivot, i, j, tmp;
  pivot = array[p];
  i = p;
  j = r + 1;
  
  while (1) {   

    i++;
    while(array[i] <= pivot && i <= r){
      i++;
    }
    
    j--;
    while(array[j] > pivot){
      j--;
    }

    if (i >= j) {
      break;
    }

    /* swap array[i] and array[j] */
    tmp = array[i];
    array[i] = array[j];
    array[j] = tmp;
  } 

  /* swap array[p] and array[j] */
  tmp = array[p];
  array[p] = array[j];
  array[j]=tmp;
  
  return j;
}

void quicksort (int * array, int p, int r) {
  int q;

  if (p < r) {
    q = partition (array, p, r);
    quicksort(array, p, q-1);
    quicksort(array, q+1, r);
  }
}


int test[10] = {100, 209, -725, -200, 500, 301, 60, -400,100, 80};

void printShit(void){
  
  int i = 0;
  while( i < 10 ){
    printf("%d ",test[i]);
    i++;
  }

  printf("\n");

}


int main (void) {

  printShit();

  partition(test,0,9);
  printShit();
  //quicksort(test, 0, 9);
  
  return EXIT_SUCCESS;	
}
