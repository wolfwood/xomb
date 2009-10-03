/* 
 * segment.d
 *
 * This module describes a segment of an executable.
 *
 */

module kernel.system.segment;

struct Segment {
	void* physAddress;
	void* virtAddress;

	ulong offset;

	ulong length;

	bool writeable;
	bool executable;
}
