//This is in charge of the HPET timer device
module kernel.arch.x86_64.hpet;

import kernel.core.error;
import kernel.core.util;
import kernel.arch.x86_64.vmem;
import kernel.core.regions;
import kernel.dev.vga;
import kernel.arch.x86_64.init;
import kernel.arch.x86_64.ioapic;
import kernel.arch.x86_64.lapic;
import kernel.arch.x86_64.mp;

// Make mpInformation 


template Tmaker(uint ID)
{
	const char[] Tmaker = ", \"T" ~ ID.stringof[0..$-1] ~ "_INT_STS\", 1";
}

//Maps to the individual timers
align(1) struct timerInfo {
	ulong configurationAndCap;
	ulong comparatorValue;
	ulong FSBInterrruptRoute;
	ulong reserved;
	
	mixin(Bitfield!(configurationAndCap, "Reserved1", 1, "INT_TYPE_CNF", 1, "INT_ENB_CNF", 1, "TYPE_CNF", 1, "PER_INT_CAP", 1, "SIZE_CAP", 1, "VAL_SET_CNF", 1, "Reserved2", 1, "MODE_CNF", 1, "INT_ROUTE_CNF", 5, "FSB_EN_CNF", 1, "FSB_INT_DEL_CAP", 1, "Reserved3", 16, "INT_ROUTE_CAP", 32));
}


//Maps to the memory that holds the configuration data for HPET
align(1) struct hpetConfig {
	ulong capabilitiesAndID;	// 0x00
	ulong reserved1;			// 0x08
	ulong configuration;		// 0x10
	ulong reserved2;			// 0x18
	ulong interruptStatus;		// 0x20
	ulong reserved3;			// 0x28
	ulong reserved4;			// 0x30
	ulong reserved5;			// 0x38
	ulong reserved6;			// 0x40
	ulong reserved7;			// 0x48
	ulong reserved8;			// 0x50
	ulong reserved9;			// 0x58
	ulong reserved10;			// 0x60
	ulong reserved11;			// 0x68
	ulong reserved12;			// 0x70
	ulong reserved13;			// 0x78
	ulong reserved14;			// 0x80
	ulong reserved15;			// 0x88
	ulong reserved16;			// 0x90
	ulong reserved17;			// 0x98
	ulong reserved18;			// 0xA0
	ulong reserved19;			// 0xA8
	ulong reserved20;			// 0xB0
	ulong reserved21;			// 0xB8
	ulong reserved22;			// 0xC0
	ulong reserved23;			// 0xC8
	ulong reserved24;			// 0xD0
	ulong reserved25;			// 0xD8
	ulong reserved26;			// 0xE0
	ulong reserved27;			// 0xE8
	ulong mainCounterValue;		// 0xF0
	ulong reserved28;
	timerInfo[32] timers;

	mixin(Bitfield!(capabilitiesAndID, "REV_ID", 8, "NUM_TIM_CAP", 5, "COUNT_SIZE_CAP", 1, "ReservedCap", 1, "LEG_RT_CAP", 1, "VENDOR_ID", 16,
	"COUNTER_CLOCK_PERIOD", 32));
	mixin(Bitfield!(configuration, "ENABLE_CNF", 1, "LEG_RT_CNF", 1, "Reserved1", 6, "ReservedNonOS", 8, "Reserved2", 48));
	mixin("mixin(Bitfield!(interruptStatus" ~ Reduce!(Cat, Map!(Tmaker, Range!(32))) ~ ", \"ReservedStatus\", 32));");
}

//Brings everything together for HPET
struct hpetDev {
	hpetConfig* config;
	ubyte* physHPETAddress = cast(ubyte*)0xFED00000;
	ubyte* virtHPETAddress;
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

		hpetDevice.virtHPETAddress = virtHPETAddy;

		kprintfln!("A")();
	
		// resolve the address to the configuration table
		hpetDevice.config = cast(hpetConfig*)virtHPETAddy;
		
		ulong configVal = hpetDevice.config.configuration;
		
		kprintfln!("B")();
		//kprintfln!("NUM_TIM_CAP = {}")(hpetDevice.config.NUM_TIM_CAP);

		// initialize the configuration to allow standard IOAPIC interrupts
		hpetDevice.config.LEG_RT_CNF = 1;
		//hpetDevice.config.ENABLE_CNF = 0;
		configVal &= ~(0x3);

		//kprintfln!("C")();
		hpetDevice.config.mainCounterValue = 0;
		//kprintfln!("D")();

		// resolve the array of timers
		//hpetDevice.timers = (cast(timerInfo*)virtHPETAddy+hpetConfig.sizeof)[0..hpetDevice.config.NUM_TIM_CAP];
	
		//printStruct(hpetDevice);
		//kprintfln!("E")();
		initTimer(0, 1000000);
		

		kprintfln!("timer counter: {} / {}")(hpetDevice.config.mainCounterValue, hpetDevice.config.timers[0].comparatorValue);

		//hpetDevice.config.ENABLE_CNF = 1;
		//hpetDevice.config |= 1;
		configVal |= 1;
		//kprintfln!("config: {}")(configVal);
		hpetDevice.config.configuration = configVal;
		//kprintfln!("config: {}")(hpetDevice.config.configuration);
	
		// XXX: enable keyboard interrupt

		//Cpu.reset();

		
		while(hpetDevice.config.mainCounterValue < hpetDevice.config.timers[0].comparatorValue)
		{
			kprintfln!("timer counter: {} / {}")(hpetDevice.config.mainCounterValue, hpetDevice.config.timers[0].comparatorValue);
		}
		kprintfln!("timer counter: {} / {}")(hpetDevice.config.mainCounterValue, hpetDevice.config.timers[0].comparatorValue);
	
		return ErrorVal.Success;
	}
	
	// the function to start and equip a non-periodic timer
	void initTimer(uint index, ulong nanoSecondInterval)
	{
		ulong* hpetTimerReg = cast(ulong*)( hpetDevice.virtHPETAddress + 0x100 + (0x20 * index));

		//disable!
		//hpetDevice.config.timers[index].INT_ENB_CNF = 0;
		volatile *hpetTimerReg &= ~0x4UL;
		
		// update to femptoseconds
		nanoSecondInterval *= 1000000;

		ulong timerVal;

		// write 0 to reservei
		//hpetDevice.timers[index].Reserved1 = 0;
		//hpetDevice.timers[index].Reserved2 = 0;
		//hpetDevice.timers[index].Reserved3 = 0;

		// we want a 64-bit timer

		uint ROUTE_CAP = (*hpetTimerReg) >> 32UL;
		//kprintfln!("1")();
		//kprintfln!("POSSIBLE: {x}")(hpetDevice.config.timers[index].INT_ROUTE_CAP);
		//kprintfln!("PSSOIBLE: {x}")(ROUTE_CAP);

		uint routingInterrupt = 0;
		while (!((1 << routingInterrupt) & ROUTE_CAP) && routingInterrupt < 32)
		{
			routingInterrupt++;
		}

		if (routingInterrupt >= 32) { return; }

		//kprintfln!("route int: {}")(routingInterrupt);

		// tell IOAPIC of our plans
		// So the idea here is that we're going to put 'er in
		// to physical mode here and send the apic ID of the first
		// local apic.  Just to test...  we should probably fix this later.
		//kprintfln!("HPET LocalAPICID Destination Field: {}")(MP.mpInformation.processors[0].localAPICID);
		
		//kprintfln!("3")();
		IOAPIC.setRedirectionTableEntry(10, LocalAPIC.getLocalAPICId(),
					IOAPICInterruptType.Unmasked, IOAPICTriggerMode.EdgeTriggered, 
					IOAPICInputPinPolarity.HighActive, IOAPICDestinationMode.Physical,
					IOAPICDeliveryMode.NonMaskedInterrupt, 35 );
		IOAPIC.setRedirectionTableEntry(8, LocalAPIC.getLocalAPICId(),
						IOAPICInterruptType.Unmasked, IOAPICTriggerMode.EdgeTriggered, 
						IOAPICInputPinPolarity.HighActive, IOAPICDestinationMode.Physical,
						IOAPICDeliveryMode.NonMaskedInterrupt, 35 );
		IOAPIC.setRedirectionTableEntry(routingInterrupt, LocalAPIC.getLocalAPICId(),
						IOAPICInterruptType.Unmasked, IOAPICTriggerMode.LevelTriggered, 
						IOAPICInputPinPolarity.HighActive, IOAPICDestinationMode.Physical,
						IOAPICDeliveryMode.ExtINT, 35 );
		IOAPIC.setRedirectionTableEntry(1, LocalAPIC.getLocalAPICId(),
						IOAPICInterruptType.Unmasked, IOAPICTriggerMode.EdgeTriggered, 
						IOAPICInputPinPolarity.HighActive, IOAPICDestinationMode.Physical,
						IOAPICDeliveryMode.NonMaskedInterrupt, 35 );


	//IOAPIC.printTableEntry(routingInterrupt);



		//if (hpetDevice.config.timers[index].SIZE_CAP == 0)
		//{/
		//	kprintfln!("Computer does not support 64 bit HPET.")();
		//}
		//kprintfln!("2")();
		//hpetDevice.config.timers[index].MODE_CNF = 0;
		volatile *hpetTimerReg &= ~(1UL << 8UL);
		//kprintfln!("3")();
		//hpetDevice.config.timers[index].FSB_EN_CNF = 0;
		volatile *hpetTimerReg &= ~(1UL << 14UL);
		//kprintfln!("4")();
		// we want a non-periodic timer (one-shot!)
		//hpetDevice.config.timers[index].TYPE_CNF = 0;
		volatile *hpetTimerReg &= ~(1UL << 3UL);
		//kprintfln!("5")();
	
		// we want edge-triggered interrupts
		// do we?  Brian says no, and set it to level
		// Wilkie says it makes this crash.
		//hpetDevice.config.timers[index].INT_TYPE_CNF = 1;
		timerVal |= (1 << 1);
		//kprintfln!("6")();
		
		// we want to route to interrupt 'index + 1'
		//hpetDevice.config.timers[index].INT_ROUTE_CNF = routingInterrupt; //index + 1
		volatile *hpetTimerReg |= (cast(ulong)routingInterrupt << 9UL);
		timerVal |= (1 << 9);
		//kprintfln!("7")();

		// TODO: change this to a debug
		//kprintfln!("counter updates by = {} for {}ns")(nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD, nanoSecondInterval / 1000000);

				// enable timer interrupts
		//timerVal |= (1 << 2);

		//enable!
		//hpetDevice.config.timers[index].INT_ENB_CNF = 1;
		
		//kprintfln!("4")();
	
		// get the main counter
		ulong curcounter = hpetDevice.config.mainCounterValue;

		// update to the new value
		// overflow of main counter will not matter
		ulong factor = (nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD);
		kprintfln!("factor: {}")(factor);
		curcounter += factor;
	
		//kprintfln!("5")();
		//hpetDevice.config.timers[index].comparatorValue = hpetDevice.config.mainCounterValue + factor;
		ulong* hpetTimerCounter = cast(ulong*)(hpetDevice.virtHPETAddress + 0x108 + (0x20 * index));
		volatile *hpetTimerCounter = 7000000;

		//kprintfln!("6")();
		// we now want to enable the timer
		//hpetDevice.config.timers[index].configurationAndCap = timerVal;
		
		//volatile *hpetTimerReg |= 0x2;
		volatile *hpetTimerReg |= 0x4;
		

	}

	// the function to reset a timer that has been initialized when it has already fired
	void resetTimer(uint index, ulong nanoSecondInterval)
	{
		// update to femptoseconds
		nanoSecondInterval *= 1000000;

		// halt timer
		hpetDevice.config.timers[index].INT_ENB_CNF = 0;
		
		// get the main counter
		ulong curcounter = hpetDevice.config.mainCounterValue;

		// update to the new value
		// overflow of main counter will not matter
		curcounter += (nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD);

		// we now want to enable the timer interrupt
		hpetDevice.config.timers[index].INT_ENB_CNF = 1;
	}

}
