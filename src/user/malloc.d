//malloc - memory stuff

//It is hard enough to remember my opinions, without also remembering my reasons for them!
//        -Friedrich Nietzsche

import user.syscall;
import user.basicio;

struct chunk {
  size_t size;                //size of chunk
  chunk *next; //next in the list
  chunk *prev; //prev in the list
};

chunk *used_list = null;  //the list of allocated chunks
chunk *free_list = null;  //the list of freed chunks

//if you don't know what malloc does
//then you shouldn't be in my source code
void *malloc(size_t size) {
  chunk *c = free_list;

  //first we see if there's some free-d memory we can re-use
  while(c !is null) {
    echo("in while");
    if(size < c.size) { //if the size we want is less than the size of the chunk

      return cast(void *)1337;
    }
  }
  //since c is null, we need to get a new page
  //void *h = allocPage(); //not till we have it
  //set the used list to start at the beginning of the page
  used_list = cast(chunk *)allocate(size + chunk.sizeof);
  if(!used_list) { echo("failure"); return null; }
  //set up the struct
  print("%d", 15);
  //used_list.size = size;
  //used_list.next = null;
  //used_list.prev = null;
  echo("done with malloc");
  return cast(void *)(used_list + chunk.sizeof);
}

ubyte[9000] buffer; //fake pages 'nat
int buff_pos = 0;

void *allocate(size_t size) {
  echo("in allocate");
  return cast(void*)(buffer.ptr + buff_pos);
}

//see malloc's comment
void free(void *) {
  echo("in free");
}
