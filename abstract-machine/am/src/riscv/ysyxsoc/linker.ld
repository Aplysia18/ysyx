ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
MEMORY {
  MROM : ORIGIN = 0x20000000, LENGTH = 0x1000 /*code and read-only region*/
  SRAM : ORIGIN = 0x0f000000, LENGTH = 0x2000 /*stack and heap*/
}

SECTIONS {
  
  /* .stack ALIGN(0x1000) : {
    _stack_top = ORIGIN(SRAM);
    . = _stack_top + 0x1000;
    _stack_pointer = .;
  } >SRAM

  end = .;
  _end = .;

  .heap ALIGN(0x1000) : {
    _heap_start = .;
  } >SRAM */
 

  /* fot mem-test */
  .heap ALIGN(0x1000) : {
    _heap_start = ORIGIN(SRAM);
    . = _heap_start + 0x1000;
    _heap_end = .;
  } >SRAM

  .stack ALIGN(0x1000) : {
    _stack_top = .;
    . = _stack_top + 0x1000;
    _stack_pointer = .;
  } >SRAM


  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _pmem_start + _entry_offset;
  .text : {
    *(entry)
    *(.text*)
  } >MROM :text

  etext = .;
  _etext = .;
  
  .rodata : {
    *(.rodata*)
  } >MROM
  
  .data : {
    *(.data)
  } >MROM :data
  
  edata = .;
  _data = .;
  
  .bss : {
	  _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } >MROM
}
