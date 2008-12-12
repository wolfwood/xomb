
module kernel.util.queue;

// Woo includes
import kernel.dev.vga;
import kernel.arch.x86_64.vmem;
import kernel.core.error;				// for return values


// Templated queue for great code beauty.

template circleQueue(cellType, int maxLength) {

  // Create the queue
  cellType* theQueue;
  // Keep capacity so we can use a circular array
  int head = 0;
  int tail = 0;
  int length = 0;

  ErrorVal init() {
	
	kprintfln!("celltype.sizeof = {}, mod = {}")(cellType.sizeof, (((cellType.sizeof * maxLength) +  (vMem.PAGE_SIZE % (cellType.sizeof * maxLength))) / vMem.PAGE_SIZE));
	void* pageAddress;
	
	
	// Figure out how many pages we need to allocate
	for(int z = 0; z < (((cellType.sizeof * maxLength) +  (vMem.PAGE_SIZE % (cellType.sizeof * maxLength))) / vMem.PAGE_SIZE); z++) {
	  // Assume we're going to get contiguous space here
	  if(vMem.getKernelPage(pageAddress) == ErrorVal.Fail) {
		return ErrorVal.Fail;
	  }
	  // If we're on the first iteration point start of queue to there
	  if(z == 0) {
		kprintfln!("shit guys, fire our shit")();
		theQueue = cast(cellType*) pageAddress;
	  }
	}    
	return ErrorVal.Success;
  }
  
  // Take the next in line
  cellType pop() {
	// Make sure the array ins't empty
	if(length == 0) {
	  return null;
	}
	
	int temp = head;
	// If head will be max length then wrap around
	if(head + 1 == maxLength) {
	  head = 0;
	} else {
	  head += 1;
	}
	// Decrease the length by 1
	length -= 1;
	
	return theQueue[temp];
  }



  cellType peek() {
	if(length == 0) {
	  return null;
	}

	return theQueue[head];
  }
  
  ErrorVal push(cellType newEntry) {
	// Make sure we're not at capacity
	if(length == maxLength) {
	  return ErrorVal.Fail;
	}
	
	// Add the new entry and move the tail
	theQueue[tail] = newEntry;
	
	// Increase the length
	length += 1;

	// If we're at the end, wrap around
	if(tail + 1 == maxLength) {
	  tail = 0;
	} else {
	  tail += 1;
	}
   
	return ErrorVal.Success;
  }

}