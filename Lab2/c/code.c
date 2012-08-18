int partition (int * array, int p, int r) { 
	int pivot, i, j, tmp;
    pivot = array[p];
	i = p;
    j = r + 1;  
    while (1) { 
    	do i++; 
        while (array[i] <= pivot && i <= r);
   		do j--; 
   		while (array[j] > pivot);
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

int main (void) {    
	quicksort(test, 0, 9);
	return 0;
}