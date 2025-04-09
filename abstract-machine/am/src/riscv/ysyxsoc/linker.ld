ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
MEMORY {
  SRAM : ORIGIN = 0x0f000000, LENGTH = 0x2000 /*stack and heap 8KB*/
  MROM : ORIGIN = 0x20000000, LENGTH = 0x1000 /*code and read-only region 4KB*/
}

SECTIONS {
  . = ORIGIN(SRAM);
  .stack ALIGN(4) : { /*4KB*/
    _stack_top = .;
    . = _stack_top + 0x1000;
    _stack_pointer = .;
  } >SRAM

  .heap ALIGN(4) : {  /*2KB*/
    _heap_start = .;
    . = _heap_start + 0x800;
    _heap_end = .;
  } >SRAM
 

  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _pmem_start + _entry_offset;
  .text : {
    *(entry)
    *(.text*)
  } >MROM :text
  
  .rodata : {
    *(.rodata*)
  } >MROM
  
  .data : {
    _data_start = .;
    *(.data)
    _data_end = .;
  } > SRAM AT> MROM :data
  _data_size = _data_end-_data_start;
  _data_load_start = LOADADDR(.data);
  
  .bss (NOLOAD): {
	  _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > SRAM

  /* fot mem-test */
  /* .heap ALIGN(0x1000) : {
    _heap_start = ORIGIN(SRAM);
    . = _heap_start + 0x1000;
    _heap_end = .;
  } >SRAM

  .stack ALIGN(0x1000) : {
    _stack_top = .;
    . = _stack_top + 0x1000;
    _stack_pointer = .;
  } >SRAM */

  end = .;
  _end = .;
}
