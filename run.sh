CURSES="-display curses"
SATA=""
NIC=""
CD="-cdrom build/xomb.iso --boot cd"

for arg in $@; do
	case $arg in
		-X) CURSES="";;
		--sata) SATA="-drive id=disk,file=/home/wolfwood/repos/xomb/disk0.raw,if=none -device ahci,id=ahci -device ide-drive,drive=disk,bus=ahci.0";;
		--nic) NIC="-net none -device e1000,vlan=0,mac=ab:cd:ef:01:02:03";;
	esac
done

qemu-system-x86_64 -enable-kvm $CURSES $SATA $CD $NIC

exit

#qemu-system-x86_64 -enable-kvm -device ahci,id=ahci0,bus=pci.0,multifunction=on,addr=0x4.0x0 -drive file=/home/wolfwood/repos/xomb/disk0.raw,if=none,id=drive-sata-disk0,format=raw -device ide-drive,bus=ahci0.0,drive=drive-sata-disk0,id=sata-disk0 -display curses -cdrom build/xomb.iso --boot cd
