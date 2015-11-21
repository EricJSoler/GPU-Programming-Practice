/*
First attempt at a parallel version of merge sort
Eric Soler 11/2015
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include "gputimer.h"

#define ARRAY_SIZE 100000

void print_array(int *array, int size)
{
    printf("{ ");
    for (int i = 0; i < size; i++){ 
		printf("%d ", array[i]); 
		if(i == 50) 
			printf("\n");
	}
    printf("}\n");
}

__global__ void merge(int* a,int blockSize,int arraySize){
	int s1;
	int s2; 
	int end;
	int start;
	int mid;
	start = blockSize*2*(blockIdx.x * blockDim.x + threadIdx.x);
	s1 = start;
	s2 = s1 + blockSize;
	end = s2 + blockSize;
	mid = s1 + blockSize;

	if((s2 < arraySize))
	{
		if(end > arraySize)
			end = arraySize;
	
		if(mid > arraySize)
			mid = arraySize;
	
		int* tA = new int[end - start];
		int counter = 0;

		while(counter < end - start)
		{
			if(s1 < mid && s2 < end)
			{
				if(a[s1] <= a[s2])
					tA[counter++] = a[s1++];
				else
					tA[counter++] = a[s2++];
			}
			else if(s1 < mid)
			{
				tA[counter++] = a[s1++];
			}
			else if(s2 < end)
			{
				tA[counter++] = a[s2++];
			}
			else
			{
				tA[counter++] = -66;
			}
		}
		
		for(int i = 0, j = start; i < end - start; i++, j++)
		{
			a[j] = tA[i];
		}
		delete [] tA;
	}
}

int main(int argc,char **argv)
{   
    GpuTimer timer;
	srand(time(NULL));
    // declare and allocate host memory
    int h_array[ARRAY_SIZE];
    const int ARRAY_BYTES = ARRAY_SIZE * sizeof(int);
	for(int i = 0; i < ARRAY_SIZE; i++)
	{
		h_array[i] =  rand()%10;
	}
	//print_array(h_array, ARRAY_SIZE);
    // declare, allocate, and zero out GPU memory
    int * d_array;
    cudaMalloc((void **) &d_array, ARRAY_BYTES);
    cudaMemset((void *) d_array, 0, ARRAY_BYTES); 
	cudaMemcpy(d_array, h_array, ARRAY_BYTES, cudaMemcpyHostToDevice);
    
	int numOfThreads;
	int blockWidth = 1000;
	int subArraySize;
	double x = log(ARRAY_SIZE) / log(2);
	timer.Start();
	int numberOfBlocks;
	for(int i = 0; i < x; i++)
	{
		subArraySize = pow(2,i);
		numOfThreads = ceil(ARRAY_SIZE/(subArraySize * 2.0));
		numberOfBlocks = ceil(numOfThreads/((float)blockWidth));
		merge<<<numberOfBlocks, ceil(numOfThreads/((float)numberOfBlocks))
				>>>(d_array, subArraySize, ARRAY_SIZE);
		cudaDeviceSynchronize();
	}
    timer.Stop();
    cudaMemcpy(h_array, d_array, ARRAY_BYTES, cudaMemcpyDeviceToHost);
    print_array(h_array, ARRAY_SIZE);
    printf("Time elapsed = %g ms\n", timer.Elapsed());
    cudaFree(d_array);
    return 0;
}