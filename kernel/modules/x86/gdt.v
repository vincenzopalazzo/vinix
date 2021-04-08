module x86

[packed]
struct GDTPointer {
	size    u16
	address voidptr
}

[packed]
struct GDTEntry {
	limit       u16
	base_low16  u16
	base_mid8   byte
	access      byte
	granularity byte
	base_high8  byte
}

// FIXME: Using this 2 globals as const will generate a runtime dependency on
// vinit, which we cannot call since vinit depends on malloc and other utilities
// not available in freestanding.
__global ( kernel_code_seg = u16(0x08))

__global ( kernel_data_seg = u16(0x10))

__global ( gdt_pointer GDTPointer )

__global ( gdt_entries [5]GDTEntry )

pub fn gdt_init() {
	// Initialize all the GDT entries.
	// Null descriptor.
	gdt_entries[0] = GDTEntry{
		limit: 0
		base_low16: 0
		base_mid8: 0
		access: 0
		granularity: 0
		base_high8: 0
	}

	// Kernel 64 bit code.
	gdt_entries[1] = GDTEntry{
		limit: 0
		base_low16: 0
		base_mid8: 0
		access: 0b10011010
		granularity: 0b00100000
		base_high8: 0
	}

	// Kernel 64 bit data.
	gdt_entries[2] = GDTEntry{
		limit: 0
		base_low16: 0
		base_mid8: 0
		access: 0b10010010
		granularity: 0b00000000
		base_high8: 0
	}

	// User 64 bit data.
	gdt_entries[3] = GDTEntry{
		limit: 0
		base_low16: 0
		base_mid8: 0
		access: 0b11110010
		granularity: 0
		base_high8: 0
	}

	// User 64 bit code.
	gdt_entries[4] = GDTEntry{
		limit: 0
		base_low16: 0
		base_mid8: 0
		access: 0b11111010
		granularity: 0b00100000
		base_high8: 0
	}

	// Set the GDT pointer for load.
	gdt_pointer = GDTPointer{
		size: u16(sizeof(GDTPointer) * 5 - 1)
		address: &gdt_entries
	}

	// Random ASM vomit.
	asm amd64 {
		lgdt [ptr]
		push cseg
		lea rax, [rip + reentry]
		push rax
		.short 0xcb48 // V does not have REX.W + retf, this is the opcode.
		reentry:
		mov ds, dseg
		mov es, dseg
		mov fs, dseg
		mov gs, dseg
		mov ss, dseg
		; ; r (&gdt_pointer) as ptr
		  rm (kernel_code_seg) as cseg
		  rm (kernel_data_seg) as dseg
		; memory
	}
}