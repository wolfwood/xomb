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
	kprintfln!("Value of maxZ = {}")((((heapNode.sizeof * maxSize) + (vMem.PAGE_SIZE % (heapNode.sizeof * maxSize))) / vMem.PAGE_SIZE));
	//	for(int z = 0; z <= (((heapNode.sizeof * maxSize) +  (vMem.PAGE_SIZE % (heapNode.sizeof * maxSize))) / vMem.PAGE_SIZE); z++) {
	for(int z = 0; z <= (((heapNode.sizeof * maxSize) +  (vMem.PAGE_SIZE % (heapNode.sizeof * maxSize))) / vMem.PAGE_SIZE); z++) {
	  // Assume we're going to get contiguous space here
	  kprintfln!("Hit this inside stuff")();
	  if(vMem.getKernelPage(pageAddress) == ErrorVal.Fail) {
		return ErrorVal.Fail;
	  }
	  // If we're on the first iteration point start of heap to there
	  if(z == 0) {
		kprintfln!("Z was zero, lets assign addresses mofo!")();
		// Point our heap space to the start of the first page
		theHeap = (cast(heapNode!(payloadType)*)pageAddress) - 1;
		kprintfln!("pageAddress: {x} theHeap: {x}")(pageAddress, theHeap);
	  }   
	}

	// Initialize it
	//	theHeap.init;
    theHeap[1].payload = cast(payloadType)rootPayload;
	theHeap[1].priority = priority;

	kprintfln!("theHeap payload: {}, priority: {}")(theHeap[1].payload, theHeap[1].priority);

	// Increase the lastNode count
	kprintfln!("tail: {}")(tail);

	tail = 2;

	kprintfln!("tail: {}")(tail);

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
	  
	  heapNode!(payloadType) temp = theHeap[i / 2];
	  theHeap[i / 2] = theHeap[i];
	  theHeap[i] = temp;

	  i /= 2;
	}

	// Increment tail so we know the new real end
	tail += 1;

	return ErrorVal.Success;
  }

  heapNode!(payloadType) peek() {
	return theHeap[1];
  }

  int getSize() {
	return tail;
  }

  heapNode!(payloadType) pop() {
	// The return value of the function
	heapNode!(payloadType) returnValue = theHeap[1];
	// Where in the array the current "hole" exists at
	int holeIndex = 1;
	int newHoleIndex = 1;

	int leftChildIndex;
	int rightChildIndex;

	// While there exists a hole in our array
	while(holeIndex < tail) {
	  
	  // To make things cleaner
	  leftChildIndex = (2 * holeIndex);
	  rightChildIndex = (2 * holeIndex) + 1;

	  // If the new hole is out of our bounds...
	  if(leftChildIndex >= tail) {
		kprintfln!("Breaking because leftChild = {} is > tail = {}")(leftChildIndex, tail);
		break;	// We don't need to be in here, its out of our hands man! Its out of our hands!!!!!
	  }

	  
	  if(rightChildIndex >= tail) {
		// Move the last element to the hole
		theHeap[holeIndex] = theHeap[leftChildIndex];
		// Now make sure to set the new hole location
		holeIndex = leftChildIndex;
	  } else { // Lets do some swapin'
		if(theHeap[leftChildIndex].priority > theHeap[rightChildIndex].priority) {
		  newHoleIndex = leftChildIndex;
		} else {
		  newHoleIndex = rightChildIndex;
		}
		
		// Now make the move
		kprintfln!("theHeap[{}] = theHeap[{}]")(holeIndex, newHoleIndex);
		theHeap[holeIndex] = theHeap[newHoleIndex];
		holeIndex = newHoleIndex;
	  }
	}
	// Decrement the tail length 
	tail -= 1;
	
	return returnValue;
  }
  
  void debugHeap() {
	kprintfln!("debugging heap! tail: {}")(tail);
	for(int q = 1; q < tail; q++) {
	  kprintfln!("theHeap[{}] {\n     payload = {} \n     priority = {} \n }")(q, theHeap[q].payload, theHeap[q].priority);
	}
  }

}
