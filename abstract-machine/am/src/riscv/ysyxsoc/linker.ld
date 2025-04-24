ENTRY(_start)
/* PHDRS { text PT_LOAD; data PT_LOAD; } */
MEMORY {
  SRAM : ORIGIN = 0x0f000000, LENGTH = 0x2000 /*stack and heap 8KB*/
  MROM : ORIGIN = 0x20000000, LENGTH = 0x1000 /*code and read-only region 4KB*/
  FLASH : ORIGIN = 0x30000000, LENGTH = 0x10000000 /*flash region 64KB*/
  PSRAM : ORIGIN = 0x80000000, LENGTH = 0x400000 /*psram region, 4MB*/
}

SECTIONS {
  . = ORIGIN(SRAM);
  .stack ALIGN(4) : { /*8KB*/
    _stack_top = .;
    . = _stack_top + 0x2000;
    _stack_pointer = .;
  } >SRAM 

  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _pmem_start + _entry_offset;
  .text : {
    *(entry)
    *(.text*)
  } >FLASH
  
  .rodata : {
    *(.rodata*)
  } >FLASH
  
  .data : {
    _data_start = .;
    *(.data*)
    *(.sdata*)
    _data_end = .;
  } > PSRAM AT> FLASH
  _data_size = _data_end-_data_start;
  _data_load_start = LOADADDR(.data);
  
  .bss : {
	  _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = .;
  } > PSRAM AT> FLASH
  _bss_size = _bss_end-_bss_start;
  _bss_load_start = LOADADDR(.bss);

  .heap ALIGN(4) : {  /*1MB*/
    _heap_start = .;
    . = _heap_start + 0x100000;
    _heap_end = .;
  } >PSRAM

  end = .;
  _end = .;
}
