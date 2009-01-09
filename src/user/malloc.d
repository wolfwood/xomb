// malloc - dynamic memory allocation

// It is hard enough to remember my opinions, without also remembering my reasons for them!
//        -Friedrich Nietzsche

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

header *allocHead = null;
header *allocTail = null;
header *freeHead  = null;
header *freeTail  = null;

// allocates requested memory
void *malloc(long size)
{
  header *cur = freeHead;

  // check the free list for available chunks
  while(cur !is null)
  {
    if(cur.chunkSize >= size)
    {
      // use entire chunk
      if(cur.chunkSize - size > header.sizeof)
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

        return (&cur + 1);  // return pointer to where chunk begins after header
      }
      else
      {
        // create new chunk
        header *newHeader = (cur) + 1 + size;

        // setup the header
        newHeader.chunkSize = cur.chunkSize - size - header.sizeof;
        newHeader.prev = cur;
        newHeader.next = cur.next;

        // add into list
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
        return (&cur + 1);
      }
    }

    cur = cur.next;
  }

  ulong unusedSpace = 0;

  // allocate a page
  header* newHeader = cast(header*)allocPage();
  unusedSpace += Kernel.PAGE_SIZE;

  if(newHeader is null)
    return null;      // failure to allocate a page

  while(unusedSpace < header.sizeof + size)
  {
    if(allocPage() == null)
      return null;

    unusedSpace += Kernel.PAGE_SIZE;
  }

  // setup the page
  newHeader.prev = allocTail;
  allocTail = newHeader;

  if(allocHead is null)
    allocHead = newHeader;

  return (&newHeader + 1);


}

// frees that was allocated
void free(void *pointer)
{
  header *freeHeader = (cast(header*)pointer) - 1;
  freeHeader.chunkSize = -freeHeader.chunkSize;

  // add to freelist
  if(freeHead is null)
  {
    freeHeader.nextFree = null;
  }
  else
  {
    freeHead.nextFree = freeHeader;
    freeHeader.nextFree = null;
  }

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

}
