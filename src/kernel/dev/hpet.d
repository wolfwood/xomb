//This is in charge of the HPET timer device
module kernel.dev.hpet;

import kernel.error;
import kernel.core.util;
import kernel.mem.vmem;
import kernel.mem.regions;
import kernel.dev.vga;
import kernel.dev.ioapic;

template Tmaker(uint ID)
{
	const char[] Tmaker = ", \"T" ~ ID.stringof[0..$-1] ~ "_INT_STS\", 1";
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
	
	mixin(Bitfield!(configurationAndCap, "Reserved1", 1, "INT_TYPE_CNF", 1, "INT_ENB_CNF", 1, "TYPE_CNF", 1, "PER_INT_CAP", 1, "SIZE_CAP", 1, "VAL_SET_CNF", 1, "Reserved2", 1, "MODE_CNF", 1, "INT_ROUTE_CNF", 5, "FSB_EN_CNF", 1, "FSB_INT_DEL_CAP", 1, "Reserved3", 16, "INT_ROUTE_CAP", 32));
}

//Brings everything together for HPET
struct hpetDev {
	hpetConfig* config;
	timerInfo[] timers;
	ubyte* physHPETAddress = cast(ubyte*)0xFED00000;
}

private hpetDev hpetDevice;

struct HPET
{
	static:

	//initialize out HPET timer
	ErrorVal init()
	{
		// get the virtual address of the HPET within the BIOS device map region
		ubyte* virtHPETAddy = global_mem_regions.device_maps.virtual_start + (hpetDevice.physHPETAddress - global_mem_regions.device_maps.physical_start);
		if(virtHPETAddy > (global_mem_regions.device_maps.virtual_start + global_mem_regions.device_maps.length))
		{
			// map in the region then
			if (vMem.mapRange(hpetDevice.physHPETAddress, hpetConfig.sizeof + (32 * timerInfo.sizeof), virtHPETAddy)
					!= ErrorVal.Success)
			{
				return ErrorVal.Fail;
			}
		}
	
		// resolve the address to the configuration table
		hpetDevice.config = cast(hpetConfig*)virtHPETAddy;
		
		kprintfln!("NUM_TIM_CAP = {}")(hpetDevice.config.NUM_TIM_CAP);

		// initialize the configuration to allow standard IOAPIC interrupts
		hpetDevice.config.LEG_RT_CNF = 0;
		hpetDevice.config.ENABLE_CNF = 1;

		// resolve the array of timers
		hpetDevice.timers = (cast(timerInfo*)virtHPETAddy+hpetConfig.sizeof)[0..hpetDevice.config.NUM_TIM_CAP];
	
		//printStruct(hpetDevice);

		initTimer(0, 1000000);
	
		return ErrorVal.Success;
	}
	
	// the function to start and equip a non-periodic timer
	void initTimer(uint index, ulong nanoSecondInterval)
	{
		// update to femptoseconds
		nanoSecondInterval *= 1000000;

		// write 0 to reserved
		hpetDevice.timers[index].Reserved1 = 0;
		hpetDevice.timers[index].Reserved2 = 0;
		hpetDevice.timers[index].Reserved3 = 0;

		// we want a 64-bit timer
		hpetDevice.timers[index].MODE_CNF = 0;
		hpetDevice.timers[index].SIZE_CAP = 1;

		// we want a non-periodic timer
		hpetDevice.timers[index].TYPE_CNF = 0;
		
		// we want edge-triggered interrupts
		hpetDevice.timers[index].INT_TYPE_CNF = 0;
		
		// we want to route to interrupt 'index'
		hpetDevice.timers[index].INT_ROUTE_CNF = index;
		
		// get the main counter
		ulong curcounter = hpetDevice.config.mainCounterValue;

		// update to the new value
		// overflow of main counter will not matter
		curcounter += (nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD);
		
		kprintfln!("counter updates by = {} for {}ns")(nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD, nanoSecondInterval / 1000000);

		// tell IOAPIC of our plans
		//IOAPIC.setRedirectionTableEntry(0, );

		// we now want to enable the timer interrupt
		hpetDevice.timers[index].INT_ENB_CNF = 1;
	}

	// the function to reset a timer that has been initialized when it has already fired
	void resetTimer(uint index, ulong nanoSecondInterval)
	{
		// update to femptoseconds
		nanoSecondInterval *= 1000000;

		// halt timer
		hpetDevice.timers[index].INT_ENB_CNF = 0;
		
		// get the main counter
		ulong curcounter = hpetDevice.config.mainCounterValue;

		// update to the new value
		// overflow of main counter will not matter
		curcounter += (nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD);

		// we now want to enable the timer interrupt
		hpetDevice.timers[index].INT_ENB_CNF = 1;
	}

}