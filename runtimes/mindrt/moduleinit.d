module mindrt.moduleinit;

struct ModuleReference {
	ModuleReference* next;
	ModuleInfo mod;
}

extern(C) ModuleReference* _Dmodule_ref;

uint _moduleinfo_dtors_i;

extern(C) void _moduleCtor() {
}

extern(C) void _moduleDtor() {
}

extern(C) void _moduleUnitTests() {
}

extern(C) void _moduleIndependentCtors() {
}
