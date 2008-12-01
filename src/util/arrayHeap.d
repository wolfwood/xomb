// Templated fibbonacci heap to implement all sorts of crazy schemes


module util.arrayHeap;


import kernel.core.error;
import kernel.core.util;
import kernel.arch.x86_64.vmem;
import kernel.dev.vga;


struct heapNode(payloadType) {
  payloadType payload;
  int priority;
}


// Will take two parameters:
// nodeType = the type of the node's payload
// nodeType* payloadPtr = a pointer to the data structure that is the payload of this node
// int maxsize = the maximum size of the heap (should be known since this is a kernel data structure)
template arrayHeap(payloadType, int maxSize) {
      
  // The heap
  heapNode!(payloadType)* theHeap;

  void* pageAddress;


  // Tail of the heap so we know where to append to
  int tail = 1;

  // Init our arrayHeap
  void init(payloadType rootPayload, int priority) {
	// Figure out how many pages we need to allocate
	//kprintfln!("Value of maxZ = {}")((((heapNode.sizeof * maxSize) + (vMem.PAGE_SIZE % (heapNode.sizeof * maxSize))) / vMem.PAGE_SIZE));
	//	for(int z = 0; z <= (((heapNode.sizeof * maxSize) +  (vMem.PAGE_SIZE % (heapNode.sizeof * maxSize))) / vMem.PAGE_SIZE); z++) {
	for(int z = 0; z <= (((heapNode.sizeof * maxSize) +  (vMem.PAGE_SIZE % (heapNode.sizeof * maxSize))) / vMem.PAGE_SIZE); z++) {
	  // Assume we're going to get contiguous space here
	  //kprintfln!("Hit this inside stuff")();
	  if(vMem.getKernelPage(pageAddress) == ErrorVal.Fail) {
		return ErrorVal.Fail;
	  }
	  // If we're on the first iteration point start of heap to there
	  if(z == 0) {
		//kprintfln!("Z was zero, lets assign addresses mofo!")();
		// Point our heap space to the start of the first page
		theHeap = (cast(heapNode!(payloadType)*)pageAddress) - 1;
		//kprintfln!("pageAddress: {x} theHeap: {x}")(pageAddress, theHeap);
	  }   
	}

	// Initialize it
	//	theHeap.init;
    theHeap[1].payload = cast(payloadType)rootPayload;
	theHeap[1].priority = priority;

	//kprintfln!("theHeap payload: {}, priority: {}")(theHeap[1].payload, theHeap[1].priority);

	// Increase the lastNode count
	//kprintfln!("tail: {}")(tail);

	tail = 2;

	//kprintfln!("tail: {}")(tail);

  }
  
  ErrorVal insert(payloadType payload, int priority){ 
	if(tail == maxSize + 1) {
	  return ErrorVal.Fail;
	}
	// Add the node to the array
	theHeap[tail].payload = cast(payloadType)payload;
	theHeap[tail].priority = priority;
	
	// Now we need to recalculate the positions of the elements
	int i = tail;
	while(i > 1) {
	  if(theHeap[i / 2].priority >= theHeap[i].priority) {
		break;
	  }
	  
	  swap((i/2), i);
	  
	  i /= 2;
	}
	// Increment tail so we know the new real end
	tail += 1;

	return ErrorVal.Success;
  }

  void swap(int indexA, int indexB) {
	heapNode!(payloadType) temp = theHeap[indexA];
	theHeap[indexA] = theHeap[indexB];
	theHeap[indexB] = temp;
  }

  heapNode!(payloadType) peek() {
	return theHeap[1];
  }

  int getSize() {
	return tail - 1;
  }

  heapNode!(payloadType) pop() {
	// The return value of the function
	heapNode!(payloadType) returnValue = theHeap[1];
	
	// Set the new root to be last node
	theHeap[1] = theHeap[tail  - 1];
	tail -= 1;

	int currentIndex = 1;

	int leftChildIndex = 2 * currentIndex;
	int rightChildIndex = 2 * currentIndex + 1;
	
	// Ensure that there is at least a left child
	while(leftChildIndex < tail) {
	  // If there is also a right child
	  if(rightChildIndex < tail) {
		// If the left side is greater than the right side
		if(theHeap[leftChildIndex].priority > theHeap[rightChildIndex].priority) {
		  // Swap the left child and the current node
		  swap(currentIndex, leftChildIndex);
		  // Update our current index
		  currentIndex = leftChildIndex;
		} else {
		  // If the right side is greater swap it for our current node
		  swap(currentIndex, rightChildIndex);
		  // Update the current index
		  currentIndex = rightChildIndex;
		}

		// If there wasn't a right index then we need to just swap the left
	  } else {
		swap(currentIndex, leftChildIndex);
		// Update the current index
		currentIndex = leftChildIndex;
	  }
	  
	  // Update both the left and right child variables
	  leftChildIndex = 2 * currentIndex;
	  rightChildIndex = 2 * currentIndex + 1;
	}

	// Return the root node
	return returnValue;
  }

  void debugHeap() {
	kprintfln!("debugging heap! tail: {}")(tail);
	for(int q = 1; q < tail; q++) {
	  kprintfln!("theHeap[{}] {\n     payload = {} \n     priority = {} \n }")(q, theHeap[q].payload, theHeap[q].priority);
	}
  }

}
