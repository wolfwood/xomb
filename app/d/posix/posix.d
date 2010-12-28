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

	foreach(str; argv){
		Console.putString(str);
		Console.putString("\n");
	}

	MinFS.initialize();
	MessageInAbottle* bottle = MessageInAbottle.getMyBottle();

	switch(argv[0]){
	case "cat":
		if(argv.length < 1){
			exit(1);
		}

		if(bottle.stdoutIsTTY){

			foreach(file; argv[1..$]){
				File f = MinFS.open(file, cast(AccessMode)0);
				if (f is null){
					continue;
				}

				ulong* size = cast(ulong*)f.ptr;
				char[] data = (cast(char*)f.ptr)[ulong.sizeof..(ulong.sizeof + *size)];

				Console.putString(data);
			}
		}else{
			ulong* stdoutlen = cast(ulong*)bottle.stdout.ptr;
			ubyte* ptr = bottle.stdout.ptr + ulong.sizeof;

			*stdoutlen = 0;

			foreach(file; argv[1..$]){
				File f = MinFS.open(file, cast(AccessMode)0);
				if (f is null){
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


		break;
	case "echo":
		

		break;
	case "grep":


		break;
	case "less":
	case "more":


		break;
	default: 
		Console.putString("Posix: command not found\n");
		//return 1;
	}

	//return 0;
}