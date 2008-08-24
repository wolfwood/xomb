//This is in charge of the HPET timer device
module kernel.dev.hpet;

import kernel.error;
import kernel.core.util;
import kernel.mem.vmem;
import kernel.mem.vmem_structs;
import kernel.dev.vga;

template Tmaker(uint ID)
{
	const char[] Tmaker = ", \"T" ~ ID.stringof ~ "_INT_STS\", 1";
}

//Maps to the memory that holds the configuration data for HPET
align(1) struct hpetConfig {
	ulong capabilitiesAndID;
	ulong reserved1;
	ulong configuration;
	ulong reserved2;
	ulong interruptStatus;
	ulong reserved3;
	ulong mainCounterValue;
	ulong reserved4;

	mixin(Bitfield!(capabilitiesAndID, "REV_ID", 8, "NUM_TIM_CAP", 5, "COUNT_SIZE_CAP", 1, "ReservedCap", 1, "LEG_RT_CAP", 1, "VENDOR_ID", 16,
	"COUNTER_CLOCK_PERIOD", 32));
	mixin(Bitfield!(configuration, "ENABLE_CNF", 1, "LEG_RT_CNF", 1, "Reserved1", 6, "ReservedNonOS", 8, "Reserved2", 48));
//	mixin(Bitfield!(interruptStatus, "T0_INT_STS", 1, "T1_INT_STS", 1, "T2_INT_STS", 1, "T3_INT_STS", 1, "T4_INT_STS", 1, "T5_INT_STS", 1, "T6_INT_STS", 1, "T7_INT_STS", 1, "T8_INT_STS", 1, "T9_INT_STS", 1, "T10_INT_STS", 1, "T11_INT_STS", 1, "T12_INT_STS", 1, "T13_INT_STS", 1, "T14_INT_STS", 1, "T15_INT_STS", 1, "T16_INT_STS", 1, "T17_INT_STS", 1, "T18_INT_STS", 1, "T19_INT_STS", 1, "T20_INT_STS", 1, "T21_INT_STS", 1, "T22_INT_STS", 1, "T23_INT_STS", 1, "T24_INT_STS", 1, "T25_INT_STS", 1, "T26_INT_STS", 1, "T27_INT_STS", 1, "T28_INT_STS", 1, "T28_INT_STS", 1, "T30_INT_STS", 1, "T31_INT_STS", 1, "Reserved", 32));
	mixin("mixin(Bitfield!(interruptStatus" ~ Reduce!(Cat, Map!(Tmaker, Range!(32))) ~ ", \"ReservedStatus\", 32));");
}

//Maps to the individual timers
align(1) struct timerInfo {
	ulong configurationAndCap;
	ulong comparatorValue;
	ulong FSBInterrruptRoute;
	ulong reserved;
}

//Brings everything together for HPET
struct hpetDev {
	hpetConfig* config;
	timerInfo*[32] timers;
	ubyte* physHPETAddress = cast(ubyte*)0xFED00000;
}

private hpetDev hpetDevice;

//initialize out HPET timer
ErrorVal init()
{
	if (vMem.mapRange(global_mem_regions.device_maps.physical_start, global_mem_regions.device_maps.length + ( 32 * timerInfo.sizeof ), global_mem_regions.device_maps.virtual_start )
			!= ErrorVal.Success)
	{
		return ErrorVal.Fail;
	}

	ubyte* virtHPETAddy = global_mem_regions.device_maps.virtual_start + (hpetDevice.physHPETAddress - global_mem_regions.device_maps.physical_start);
	if(virtHPETAddy > (global_mem_regions.device_maps.virtual_start + global_mem_regions.device_maps.length))
	{
		return ErrorVal.Fail;
	}

	hpetDevice.config = cast(hpetConfig*)virtHPETAddy;

	for(uint i = 0; i < hpetDevice.config.NUM_TIM_CAP; i++)
	{
		hpetDevice.timers[i] = cast(timerInfo*)virtHPETAddy+hpetConfig.sizeof;
	}

	printStruct(hpetDevice);

	return ErrorVal.Success;
}
