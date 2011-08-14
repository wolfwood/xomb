/*
 * segment.d
 *
 * This module describes a segment of an executable.
 *
 */

module libos.elf.segment;

struct Segment {
	void* physAddress;
	void* virtAddress;

	ulong offset;

	ulong length;

	bool writeable;
	bool executable;
}
