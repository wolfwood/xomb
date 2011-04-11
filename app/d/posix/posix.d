// a busybox style all-in-one for standard posix apps

module posix;

//memcpy
import mindrt.util;

import libos.console;
import libos.keyboard;
import libos.libdeepmajik.threadscheduler;
import libos.fs.minfs;

// exit
import user.syscall;
import user.environment;

void main(char[][] argv){
	if(argv.length < 1){
		exit(0);
	}

	MinFS.initialize();
	MessageInAbottle* bottle = MessageInAbottle.getMyBottle();

	int last_slash = 0;
	foreach(idx, chr; argv[0]) {
		if (chr == '/') {
			last_slash = idx+1;
		}
	}

	argv[0] = argv[0][last_slash..$];

	switch(argv[0]){
	case "cat":
		if(argv.length < 2){
			exit(1);
		}

		if(bottle.stdoutIsTTY){

			foreach(file; argv[1..$]){
				File f;

				if(file == "-"){
					f = bottle.stdin.ptr[0..oneGB];
				}else{
					f = MinFS.open(file, AccessMode.Read);
				}

				if (f is null){
					Console.putString("File ");
					Console.putString(file);
					Console.putString(" Does Not Exist!\n");

					continue;
				}

				ulong* size = cast(ulong*)f.ptr;
				char[] data = (cast(char*)f.ptr)[ulong.sizeof..(ulong.sizeof + *size)];

				Console.putString(data);
			}
		}else{
			ulong* stdoutlen = cast(ulong*)bottle.stdout.ptr;
			ubyte* ptr = cast(ubyte*)bottle.stdout.ptr + ulong.sizeof;

			*stdoutlen = 0;

			foreach(file; argv[1..$]){
				File f = MinFS.open(file, AccessMode.Read);
				if (f is null){
					// XXX: stderr
					//Console.putString("File ");
					//Console.putString(file);
					//Console.putString("Does Not Exist!\n");

					continue;
				}

				ulong* size = cast(ulong*)f.ptr;
				char[] data = (cast(char*)f.ptr)[ulong.sizeof..(ulong.sizeof + *size)];

				memcpy(ptr, data.ptr, *size);

				*stdoutlen += *size;
				ptr += *size;
			}

		}

		break;
	case "cp":
		if(argv.length != 3){
			Console.putString("Usage: cp src dest\n");
			exit(1);
		}

		File f = MinFS.open(argv[1], AccessMode.Read);
		if (f is null){
			Console.putString("File ");
			Console.putString(argv[1]);
			Console.putString(" Does Not Exist!\n");
			
			exit(1);
		}

		File g = MinFS.open(argv[2], AccessMode.Writable, true);
		if (g is null){
			Console.putString("File ");
			Console.putString(argv[2]);
			Console.putString(" Does Not Exist!\n");
			
			exit(1);
		}
		
		ulong* size = cast(ulong*)f.ptr;

		memcpy(g.ptr, f.ptr, *size + ulong.sizeof);

		break;
	case "echo":
		char[] space = " ", newline = "\n";

		if(bottle.stdoutIsTTY){
			foreach(str; argv[1..$]){
				Console.putString(str);
				Console.putString(space);
			}

			Console.putString(newline);
		}else{
			ulong* size = cast(ulong*)bottle.stdout.ptr;
			char* ptr = cast(char*)bottle.stdout.ptr + ulong.sizeof;

			foreach(str; argv[1..$]){
				memcpy(ptr, str.ptr, str.length);
				ptr += str.length;
				*size += str.length;

				memcpy(ptr, space.ptr, space.length);
				ptr += space.length;
				*size += space.length;
			}

				memcpy(ptr, newline.ptr, newline.length);
				*size += newline.length;
		}

		break;
	case "grep":


		break;
	case "less":
	case "more":


		break;
	case "ln":
	  if(argv.length < 3){
			Console.putString("Usage: ln file target\n");
			exit(1);
		}

		File f = MinFS.link(argv[1], argv[2]);

		if (f is null){
			Console.putString("target already exists!\n");
			//return(1);
		}
		
		//return(0);
		break;
	case "ls":
		uint idx;
	  if(argv.length < 2){
			Console.putString("Usage: ls dir\n");
			exit(1);
		}

		foreach(dir; argv[1..$]){
			Console.putString(dir);
			Console.putString(":\n");

			char[] str = MinFS.findPrefix(dir, idx);
			while(str !is null){
				Console.putString(str);
				Console.putString("\n");
				str = MinFS.findPrefix(dir, idx);
			}
		}
		break;

	case "clearpcm":
		pcmClearStats();
		break;
	case "printpcm":
		pcmPrintStats();
		break;
	default: 
		Console.putString("Posix: command '");
		foreach(str; argv){
			Console.putString(str);
			Console.putString(" ");
		}
		Console.putString("' not found\n");
		break;
	}

	//return 0;
}
