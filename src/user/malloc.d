// malloc - dynamic memory allocation

// It is hard enough to remember my opinions, without also remembering my reasons for them!
//				-Friedrich Nietzsche

import user.syscall;
import user.basicio;
import user.constants;

struct header
{
	header *next;
	header *prev;
	header *nextFree; // only used by items in the freelist
	header *prevFree; // only used by items in the freelist
	long chunkSize;
}

ulong unusedSpace = 0;

header *allocHead = null;
header *allocTail = null;
header *freeHead	= null;
header *freeTail	= null;

// allocates requested memory
void* malloc(long size)
{
	header *cur = freeHead;

	// check the free list for available chunks
	while(cur !is null)
	{
		// free chunks have their size as negative
		if(-cur.chunkSize >= size)
		{
			// use entire chunk
			if(-cur.chunkSize - size <= header.sizeof)
			{
				if (cur is freeHead)
					freeHead = cur.next;
				if (cur is freeTail)
					freeTail = cur.prev;

				// remove from free list
				if (cur.prevFree !is null)
					cur.prevFree.nextFree = cur.nextFree;
				if (cur.nextFree !is null)
					cur.nextFree.prevFree = cur.prevFree;

				cur.chunkSize = -cur.chunkSize;

				return (cur + 1);	// return pointer to where chunk begins after header
			}
			else
			{
			    // create new chunk
				header *newHeader = cast(header*)(cast(ubyte*)(cur + 1) + size);

				// setup the header
				newHeader.chunkSize = cur.chunkSize + size + header.sizeof;
				newHeader.prev = cur;
				newHeader.next = cur.next;

				// add into list
				if(cur.next !is null)
					cur.next.prev = newHeader;

				cur.next = newHeader;

				// resize chunk
				cur.chunkSize = size;

				// add new chunk to free list
				newHeader.nextFree = cur.nextFree;
				newHeader.prevFree = cur.prevFree;

				if(cur is freeHead)
					freeHead = newHeader;
				if(cur is freeTail)
					freeTail = newHeader;

				// remove current chunk from free list
				if (cur.prevFree !is null)
					cur.prevFree.nextFree = newHeader;
				if (cur.nextFree !is null)
					cur.prevFree.nextFree = newHeader;

				// return the chunk
				return (cur + 1);
			}
		}

		cur = cur.next;
	}

	header* newHeader;
	if (allocTail is null)
	{
		newHeader = cast(header*)allocPage();
		unusedSpace += Kernel.PAGE_SIZE;
	}
	else
	{
		newHeader = allocTail;
	}

	while(unusedSpace < header.sizeof + size)
	{
		if(allocPage() == null)
			return null;

		unusedSpace += Kernel.PAGE_SIZE;
	}

	// setup the page
	newHeader.next = null;
	newHeader.prev = allocTail;
	newHeader.chunkSize = size;

	if (allocTail !is null)
		allocTail.next = newHeader;

	allocTail = newHeader;

	if(allocHead is null)
		allocHead = newHeader;

	// take it out of unused space
	unusedSpace -= size + header.sizeof;

	return (newHeader + 1);
}

// frees that was allocated
void free(void *pointer)
{
	header *freeHeader = (cast(header*)pointer) - 1;

	freeHeader.chunkSize = -freeHeader.chunkSize;

	// add to freelist
	if(freeHead !is null)
	{
		freeHeader.nextFree = freeHead.nextFree;
		freeHead.nextFree = freeHeader;
	}
	else
	{
		freeHeader.nextFree = freeHeader;
	}

	freeHeader.prevFree = freeHeader;
	freeHead = freeHeader;

	// merge blocks
	if(freeHeader.prev !is null && freeHeader.prev.chunkSize < 0)
	{
		freeHeader.prev.chunkSize = freeHeader.chunkSize + header.sizeof;
		freeHeader.prev.next = freeHeader.next;

		if(freeHeader.next !is null)
		{
			freeHeader.next.prev = freeHeader.prev;
		}

		freeHeader = freeHeader.prev;
	}

	if(freeHeader.next !is null && freeHeader.next.chunkSize > 0)
	{
		freeHeader.chunkSize = freeHeader.next.chunkSize + header.sizeof;

		if(freeHeader.next.next !is null)
		{
			freeHeader.next.next.prev = freeHeader;
		}

		freeHeader.next = freeHeader.next.next;
	}

	if (freeHeader.next is null)
	{
		// remove this from all lists
		if (freeHeader.nextFree !is null)
				freeHeader.nextFree.prevFree = freeHeader.prevFree;

		if (freeHeader.prevFree !is null)
				freeHeader.prevFree.nextFree = freeHeader.nextFree;

		if (freeHeader is freeHead)
		{
				freeHead = freeHeader.prevFree;
		}

		// remove from alloc list
		if (freeHeader.prev !is null)
				freeHeader.prev.next = null;

		allocTail = freeHeader.prev;

		// we have more unused space
		unusedSpace += (-freeHeader.chunkSize + header.sizeof);

		// free the pages if possible
		while(unusedSpace >= Kernel.PAGE_SIZE)
		{
				freePage();
				unusedSpace -= Kernel.PAGE_SIZE;
		}
	}
}
