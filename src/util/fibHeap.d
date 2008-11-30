// Templated fibbonacci heap to implement all sorts of crazy schemes


module util.arrayHeap;


import kernel.core.error;
import kernel.arch.x86_64.vmem;

// Will take two parameters:
// nodeType = the type of the node's payload
// nodeType* payloadPtr = a pointer to the data structure that is the payload of this node
// int maxsize = the maximum size of the heap (should be known since this is a kernel data structure)
template arrayHeap(nodeType, int maxSize) {
  
  // The heap
  nodeType[maxSize] theHeap;
  // Tail of the heap so we know where to append to
  int tail = 0;
  
  struct heapNode {	
	// First payload
	nodeType* payload;
	// Priority of the current node
	double priority = 0;
  }
  
  void* pageAddress;
  
  // Init our arrayHeap
  ErrorVal init(nodeType* rootPayload, double priority) {
	// Figure out how many pages we need to allocate
	kprintfln!("Value of maxZ = {}")((((sizeOf(heapNode) * maxSize) + (vMem.PAGE_SIZE % (sizeOf(heapNode) * maxSize))) / vMem.PAGE_SIZE));
	for(int z = 0; z <= (((sizeOf(heapNode) * maxSize) + 
						  (vMem.PAGE_SIZE % (sizeOf(heapNode) * maxSize))) / vMem.PAGE_SIZE); z++) {
	  
	  // Assume we're going to get contiguous space here
	  if(vMem.getKernelPage(pageAddress) == ErrorVal.Fail) {
		return ErrorVal.Fail;
	  }
	}
	// If we're on the first iteration point start of heap to there
	if(z == 0) {
	  // Point our heap space to the start of the first page
	  theHeap = cast(nodeType*)pageAddress;
	}   
	// Initialize it
	theHeap.init;
	theHeap[0].payLoad = rootPayload;
	theHeap[0].priority = priority;

	// Increase the lastNode count
	tail++;

	return ErrorVal.Success;
	
  }
  
  ErrorVal insert(nodeType* payload, double priority){ 
	// Add the node to the array
	theHeap[tail].payload = payload;
	theheap[tail].priority = priority;

	// Now we need to recalculate the positions of the elements
	int i = tail;
	while(i > 1) {
	  if(theHeap[i / 2] >= theHeap[i]) {
		break;
	  }
	  
	  swap(theHeap[i / 2], theHeap[i]);
	}
  }

  heapNode pop() {
	// The return value of the function
	heapNode returnValue = theHeap[0];
	// Where in the array the current "hole" exists at
	int holeIndex = 0;
	int newHoleIndex = 0;

	// While there exists a hole in our array
	while(holeIndex < tail) {
	  // If the hole is out of our bounds...
	  if((2 * holeIndex) > tail) {
		break;	// We don't need to be in here, its out of our hands man! Its out of our hands!!!!!
	  }

	  if(((2 * holeIndex) + 1) > tail) {
		// Move the hole to the end of the array
		theHeap[holeIndex] = theHeap[holeIndex * 2];
		// Now make sure to set the new hole location
		holeIndex = holeIndex * 2;
	  } else { // Lets do some swapin'
		// First figure out what our hole index is
		if(theHeap[2 * holeIndex] > theHeap[((2 * holeIndex) + 1)]) {
		  newHoleIndex = 2 * holeIndex;
		} else {
		  newHoleIndex = ((2 * holeIndex) + 1);
		}
		
		// Now make the move
		theHeap[holeIndex] = theHeap[newHoleIndex];
		holeIndex = newHoleIndex;
	  }
	}

	// Decrement the tail length 
	tail -= 1;
	
	return returnValue;
  }
  
  private void swap(heapNode a, heapNode b) {
	heapNode temp = a;
	heapNode a = b;
	heapNode b = temp;
  }

  void debugHeap() {
	for(int q = 0; q < tail; q++) {
	  kpritfln!("theHeap[{}] {\n\t payload = {} \n\t priority = {} \n }")(q, theHeap[q].payload, theHeap[q].priority);
	}
  }

}