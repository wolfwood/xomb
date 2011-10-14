module user.c.c;

struct C{
	enum Errno{
		EOK = 0,
			EPERM = 1,		/* Not super-user */
			ENOENT = 2,	/* No such file or directory */
			ESRCH = 3,		/* No such process */
			EINTR = 4,		/* Interrupted system call */
			EIO = 5,		/* I/O error */
			ENXIO = 6,		/* No such device or address */
			E2BIG = 7,		/* Arg list too long */
			ENOEXEC = 8,	/* Exec format error */
			EBADF = 9,		/* Bad file number */
			ECHILD = 10,	/* No children */
			EAGAIN = 11,	/* No more processes */
			ENOMEM = 12,	/* Not enough core */
			EACCES = 13,	/* Permission denied */
			EFAULT = 14,	/* Bad address */
			ENOTBLK = 15,	/* Block device required */
			EBUSY = 16,	/* Mount device busy */
			EEXIST = 17,	/* File exists */
			EXDEV = 18,	/* Cross-device link */
			ENODEV = 19,	/* No such device */
			ENOTDIR = 20,	/* Not a directory */
			EISDIR = 21,	/* Is a directory */
			EINVAL = 22,	/* Invalid argument */
			ENFILE = 23,	/* Too many open files in system */
			EMFILE = 24,	/* Too many open files */
			ENOTTY = 25,	/* Not a typewriter */
			ETXTBSY = 26,	/* Text file busy */
			EFBIG = 27,	/* File too large */
			ENOSPC = 28,	/* No space left on device */
			ESPIPE = 29,	/* Illegal seek */
			EROFS = 30,	/* Read only file system */
			EMLINK = 31,	/* Too many links */
			EPIPE = 32,	/* Broken pipe */
			EDOM = 33,		/* Math arg out of domain of func */
			ERANGE = 34,	/* Math result not representable */
			ENOMSG = 35,	/* No message of desired type */
			EIDRM = 36,	/* Identifier removed */
/+
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define	ECHRNG 37	/* Channel number out of range */
#define	EL2NSYNC 38	/* Level 2 not synchronized */
#define	EL3HLT 39	/* Level 3 halted */
#define	EL3RST 40	/* Level 3 reset */
#define	ELNRNG 41	/* Link number out of range */
#define	EUNATCH 42	/* Protocol driver not attached */
#define	ENOCSI 43	/* No CSI structure available */
#define	EL2HLT 44	/* Level 2 halted */
#endif
#define	EDEADLK 45	/* Deadlock condition */
#define	ENOLCK 46	/* No record locks available */
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define EBADE 50	/* Invalid exchange */
#define EBADR 51	/* Invalid request descriptor */
#define EXFULL 52	/* Exchange full */
#define ENOANO 53	/* No anode */
#define EBADRQC 54	/* Invalid request code */
#define EBADSLT 55	/* Invalid slot */
#define EDEADLOCK 56	/* File locking deadlock error */
#define EBFONT 57	/* Bad font file fmt */
#endif
#define ENOSTR 60	/* Device not a stream */
#define ENODATA 61	/* No data (for no delay io) */
#define ETIME 62	/* Timer expired */
#define ENOSR 63	/* Out of streams resources */
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define ENONET 64	/* Machine is not on the network */
#define ENOPKG 65	/* Package not installed */
#define EREMOTE 66	/* The object is remote */
#endif
#define ENOLINK 67	/* The link has been severed */
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define EADV 68		/* Advertise error */
#define ESRMNT 69	/* Srmount error */
#define	ECOMM 70	/* Communication error on send */
#endif
#define EPROTO 71	/* Protocol error */
#define	EMULTIHOP 74	/* Multihop attempted */
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define	ELBIN 75	/* Inode is remote (not really error) */
#define	EDOTDOT 76	/* Cross mount point (not really error) */
#endif
#define EBADMSG 77	/* Trying to read unreadable message */
#define EFTYPE 79	/* Inappropriate file type or format */
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define ENOTUNIQ 80	/* Given log. name not unique */
#define EBADFD 81	/* f.d. invalid for this operation */
#define EREMCHG 82	/* Remote address changed */
#define ELIBACC 83	/* Can't access a needed shared lib */
#define ELIBBAD 84	/* Accessing a corrupted shared lib */
#define ELIBSCN 85	/* .lib section in a.out corrupted */
#define ELIBMAX 86	/* Attempting to link in too many libs */
#define ELIBEXEC 87	/* Attempting to exec a shared library */
#endif
+/
			ENOSYS = 88,	/* Function not implemented */
/+
#ifdef __CYGWIN__
#define ENMFILE 89      /* No more files */
#endif
#define ENOTEMPTY 90	/* Directory not empty */
#define ENAMETOOLONG 91	/* File or path name too long */
#define ELOOP 92	/* Too many symbolic links */
#define EOPNOTSUPP 95	/* Operation not supported on transport endpoint */
#define EPFNOSUPPORT 96 /* Protocol family not supported */
#define ECONNRESET 104  /* Connection reset by peer */
#define ENOBUFS 105	/* No buffer space available */
#define EAFNOSUPPORT 106 /* Address family not supported by protocol family */
#define EPROTOTYPE 107	/* Protocol wrong type for socket */
#define ENOTSOCK 108	/* Socket operation on non-socket */
#define ENOPROTOOPT 109	/* Protocol not available */
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define ESHUTDOWN 110	/* Can't send after socket shutdown */
#endif
#define ECONNREFUSED 111	/* Connection refused */
#define EADDRINUSE 112		/* Address already in use */
#define ECONNABORTED 113	/* Connection aborted */
#define ENETUNREACH 114		/* Network is unreachable */
#define ENETDOWN 115		/* Network interface is not configured */
#define ETIMEDOUT 116		/* Connection timed out */
#define EHOSTDOWN 117		/* Host is down */
#define EHOSTUNREACH 118	/* Host is unreachable */
#define EINPROGRESS 119		/* Connection already in progress */
#define EALREADY 120		/* Socket already connected */
#define EDESTADDRREQ 121	/* Destination address required */
#define EMSGSIZE 122		/* Message too long */
#define EPROTONOSUPPORT 123	/* Unknown protocol */
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define ESOCKTNOSUPPORT 124	/* Socket type not supported */
#endif
#define EADDRNOTAVAIL 125	/* Address not available */
#define ENETRESET 126
#define EISCONN 127		/* Socket is already connected */
#define ENOTCONN 128		/* Socket is not connected */
#define ETOOMANYREFS 129
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define EPROCLIM 130
#define EUSERS 131
#endif
#define EDQUOT 132
#define ESTALE 133
+/
			ENOTSUP = 134,		/* Not supported */
/+
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define ENOMEDIUM 135   /* No medium (in tape drive) */
#endif
#ifdef __CYGWIN__
#define ENOSHARE 136    /* No such host or network path */
#define ECASECLASH 137  /* Filename exists with different case */
#endif
#define EILSEQ 138
#define EOVERFLOW 139	/* Value too large for defined data type */
#define ECANCELED 140	/* Operation canceled */
#define ENOTRECOVERABLE 141	/* State not recoverable */
#define EOWNERDEAD 142	/* Previous owner died */
#ifdef __LINUX_ERRNO_EXTENSIONS__
#define ESTRPIPE 143	/* Streams pipe error */
#endif
#define EWOULDBLOCK EAGAIN	/* Operation would block */

#define __ELASTERROR 2000	/* Users can add values starting here */

+/
	}

	enum Mode{
		_FOPEN =		(-1),	/* from sys/file.h, kernel use only */
			_FREAD =		0x0001,	/* read enabled */
			_FWRITE =		0x0002,	/* write enabled */
			_FAPPEND =	0x0008,	/* append (writes guaranteed at the end) */
			_FMARK =		0x0010,	/* internal; mark during gc() */
			_FDEFER =		0x0020,	/* internal; defer for next gc pass */
			_FASYNC =		0x0040,	/* signal pgrp when data ready */
			_FSHLOCK =	0x0080,	/* BSD flock() shared lock present */
			_FEXLOCK =	0x0100,	/* BSD flock() exclusive lock present */
			_FCREAT =		0x0200,	/* open with file create */
			_FTRUNC =		0x0400,	/* open with truncation */
			_FEXCL =		0x0800,	/* error on open if file exists */
			_FNBIO =		0x1000,	/* non blocking I/O (sys5 style) */
			_FSYNC =		0x2000,	/* do all writes synchronously */
			_FNONBLOCK =	0x4000,	/* non blocking I/O (POSIX style) */
			_FNDELAY =	_FNONBLOCK,	/* non blocking I/O (4.2 style) */
			_FNOCTTY =	0x8000,	/* don't assign a ctty on this open */

			/*
			 * Flag values for open(2) and fcntl(2)
			 * The kernel adds 1 to the open modes to turn it into some
			 * combination of FREAD and FWRITE.
			 */
			O_RDONLY =	0,		/* +1 == FREAD */
			O_WRONLY =	1,		/* +1 == FWRITE */
			O_RDWR =		2,		/* +1 == FREAD|FWRITE */
			O_APPEND =	_FAPPEND,
			O_CREAT =		_FCREAT,
			O_TRUNC =		_FTRUNC,
			O_EXCL =		_FEXCL,
			O_SYNC =		_FSYNC,
			/*	O_NDELAY	_FNDELAY 	set in include/fcntl.h */
			/*	O_NDELAY	_FNBIO 		set in include/fcntl.h */
			O_NONBLOCK =	_FNONBLOCK,
			O_NOCTTY =	_FNOCTTY,

			O_ACCMODE =	(O_RDONLY|O_WRONLY|O_RDWR),

/+
/*
 * Flags that work for fcntl(fd, F_SETFL, FXXXX)
 */
#define	FAPPEND		_FAPPEND
#define	FSYNC		_FSYNC
#define	FASYNC		_FASYNC
#define	FNBIO		_FNBIO
#define	FNONBIO		_FNONBLOCK	/* XXX fix to be NONBLOCK everywhere */
#define	FNDELAY		_FNDELAY

/*
 * Flags that are disallowed for fcntl's (FCNTLCANT);
 * used for opens, internal state, or locking.
 */
#define	FREAD		_FREAD
#define	FWRITE		_FWRITE
#define	FMARK		_FMARK
#define	FDEFER		_FDEFER
#define	FSHLOCK		_FSHLOCK
#define	FEXLOCK		_FEXLOCK

/*
 * The rest of the flags, used only for opens
 */
#define	FOPEN		_FOPEN
#define	FCREAT		_FCREAT
#define	FTRUNC		_FTRUNC
#define	FEXCL		_FEXCL
#define	FNOCTTY		_FNOCTTY

#endif	/* !_POSIX_SOURCE */

/* XXX close on exec request; must match UF_EXCLOSE in user.h */
#define	FD_CLOEXEC	1	/* posix */

/* fcntl(2) requests */
#define	F_DUPFD		0	/* Duplicate fildes */
#define	F_GETFD		1	/* Get fildes flags (close on exec) */
#define	F_SETFD		2	/* Set fildes flags (close on exec) */
#define	F_GETFL		3	/* Get file flags */
#define	F_SETFL		4	/* Set file flags */
#ifndef	_POSIX_SOURCE
#define	F_GETOWN 	5	/* Get owner - for ASYNC */
#define	F_SETOWN 	6	/* Set owner - for ASYNC */
#endif	/* !_POSIX_SOURCE */
#define	F_GETLK  	7	/* Get record-locking information */
#define	F_SETLK  	8	/* Set or Clear a record-lock (Non-Blocking) */
#define	F_SETLKW 	9	/* Set or Clear a record-lock (Blocking) */
#ifndef	_POSIX_SOURCE
#define	F_RGETLK 	10	/* Test a remote lock to see if it is blocked */
#define	F_RSETLK 	11	/* Set or unlock a remote lock */
#define	F_CNVT 		12	/* Convert a fhandle to an open fd */
#define	F_RSETLKW 	13	/* Set or Clear remote record-lock(Blocking) */
#endif	/* !_POSIX_SOURCE */
#ifdef __CYGWIN__
#define	F_DUPFD_CLOEXEC	14	/* As F_DUPFD, but set close-on-exec flag */
#endif

/* fcntl(2) flags (l_type field of flock structure) */
#define	F_RDLCK		1	/* read lock */
#define	F_WRLCK		2	/* write lock */
#define	F_UNLCK		3	/* remove lock(s) */
#ifndef	_POSIX_SOURCE
#define	F_UNLKSYS	4	/* remove remote locks for a given system */
#endif	/* !_POSIX_SOURCE */

#ifdef __CYGWIN__
/* Special descriptor value to denote the cwd in calls to openat(2) etc. */
#define AT_FDCWD -2

/* Flag values for faccessat2) et al. */
#define AT_EACCESS              1
#define AT_SYMLINK_NOFOLLOW     2
#define AT_SYMLINK_FOLLOW       4
#define AT_REMOVEDIR            8
#endif
+/
	}

	alias ushort dev_t;
	alias ushort ino_t;
	alias ushort nlink_t;
	alias ushort uid_t;
	alias ushort gid_t;
	alias long off_t;
	alias ulong time_t;

	struct stat{
  dev_t         st_dev = 0;
  ino_t         st_ino;
  mode_t        st_mode;
  nlink_t       st_nlink = 1;
  uid_t         st_uid;
  gid_t         st_gid;
  dev_t         st_rdev = 0;
  off_t         st_size;
  time_t        st_atime;
  long          st_spare1;
  time_t        st_mtime;
  long          st_spare2;
  time_t        st_ctime;
  long          st_spare3;
  long          st_blksize = 4096;
  long          st_blocks;
  long[2] st_spare4;
	}

	enum mode_t : uint{
		_IFMT =  0170000, /* type of file */
			_IFDIR =  0040000, /* directory */
			_IFCHR =  0020000, /* character special */
			_IFBLK =  0060000, /* block special */
			_IFREG =  0100000, /* regular */
			_IFLNK =  0120000, /* symbolic link */
			_IFSOCK = 0140000, /* socket */
			_IFIFO =  0010000, /* fifo */

			S_BLKSIZE =  4096, /* size of a block */

			S_ISUID =         0004000, /* set user id on execution */
			S_ISGID =         0002000, /* set group id on execution */
			S_ISVTX =         0001000, /* save swapped text even after use */
/+
#ifndef _POSIX_SOURCE
#define S_IREAD         0000400 /* read permission, owner */
#define S_IWRITE        0000200 /* write permission, owner */
#define S_IEXEC         0000100 /* execute/search permission, owner */
#define S_ENFMT         0002000 /* enforcement-mode locking */
#endif  /* !_POSIX_SOURCE */
+/
			S_IFMT =          _IFMT,
			S_IFDIR =         _IFDIR,
			S_IFCHR =         _IFCHR,
			S_IFBLK =         _IFBLK,
			S_IFREG =         _IFREG,
			S_IFLNK =         _IFLNK,
			S_IFSOCK =        _IFSOCK,
			S_IFIFO =         _IFIFO,

			S_IRUSR = 0000400, /* read permission, owner */
			S_IWUSR = 0000200, /* write permission, owner */
			S_IXUSR = 0000100, /* execute/search permission, owner */
			S_IRWXU =         (S_IRUSR | S_IWUSR | S_IXUSR),
			S_IRGRP = 0000040, /* read permission, group */
			S_IWGRP = 0000020, /* write permission, grougroup */
			S_IXGRP = 0000010, /* execute/search permission, group */
			S_IRWXG =         (S_IRGRP | S_IWGRP | S_IXGRP),
			S_IROTH = 0000004, /* read permission, other */
			S_IWOTH = 0000002, /* write permission, other */
			S_IXOTH = 0000001, /* execute/search permission, other */
			S_IRWXO =         (S_IROTH | S_IWOTH | S_IXOTH),

			ACCESSPERMS = (S_IRWXU | S_IRWXG | S_IRWXO), /* 0777 */
			ALLPERMS = (S_ISUID | S_ISGID | S_ISVTX | S_IRWXU | S_IRWXG | S_IRWXO), /* 07777 */

		}

/+
#define F_OK    0
#define R_OK    4
#define W_OK    2
#define X_OK    1
+/
	enum Whence{
		SEEK_SET =        0,
			SEEK_CUR =        1,
			SEEK_END =        2,
			}


	static assert(stat.sizeof == 104);
}