ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
MEMORY {
  SRAM : ORIGIN = 0x0f000000, LENGTH = 0x2000 /*stack and heap 8KB*/
  MROM : ORIGIN = 0x20000000, LENGTH = 0x1000 /*code and read-only region 4KB*/
  FLASH : ORIGIN = 0x30000000, LENGTH = 0x10000000 /*flash region 64KB*/
  PSRAM : ORIGIN = 0x80000000, LENGTH = 0x400000 /*psram region, 4MB*/
}

SECTIONS {
  . = ORIGIN(SRAM);
  .stack ALIGN(4) : { /*6KB*/
    _stack_top = .;
    . = _stack_top + 0x1800;
    _stack_pointer = .;
  } > SRAM 

  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _pmem_start + _entry_offset;

  .entry :{
    *(entry)
  } > FLASH

  .fsbl : {
    _fsbl_start = .;
    *(.fsbl*)
    _fsbl_end = .;
  } > FLASH

  .ssbl : {
    _ssbl_start = .;
    *(.ssbl*)
    _ssbl_end = .;
  } > SRAM AT> FLASH
  _ssbl_size = _ssbl_end-_ssbl_start;
  _ssbl_load_start = LOADADDR(.ssbl);

  .text : {
    _text_start = .;
    *(.text*)
    _text_end = .;
  } > PSRAM AT> FLASH
  _text_size = _text_end-_text_start;
  _text_load_start = LOADADDR(.text);
  
  .rodata : {
    _rodata_start = .;
    *(.rodata*)
    *(.srodata*)
    _rodata_end = .;
  } > PSRAM AT> FLASH
  _rodata_size = _rodata_end-_rodata_start;
  _rodata_load_start = LOADADDR(.rodata);
  
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

SECTIONS {
  .data.extra : {
    _data_extra_start = .;
    /* section information for finsh shell */
    __fsymtab_start = .;
    KEEP(*(FSymTab))
    __fsymtab_end = .;
    . = ALIGN(8);
    __vsymtab_start = .;
    KEEP(*(VSymTab))
    __vsymtab_end = .;
    . = ALIGN(8);

    /* section information for initial. */
    . = ALIGN(8);
    __rt_init_start = .;
    KEEP(*(SORT(.rti_fn*)))
    __rt_init_end = .;
    . = ALIGN(8);

    __rt_utest_tc_tab_start = .;
    KEEP(*(UtestTcTab))
    __rt_utest_tc_tab_end = .;

    . = ALIGN(8);
    __am_apps_data_start = .;
    *(__am_apps.data*)
    *(__am_apps.sdata*)
    __am_apps_data_end = .;
    . = ALIGN(8);
    _data_extra_end = .;
  }> PSRAM AT> FLASH : data
  _data_extra_size = _data_extra_end-_data_extra_start;
  _data_extra_load_start = LOADADDR(.data.extra);
} 
INSERT BEFORE .data;

SECTIONS {
  .bss.extra : {
    _bss_extra_start = .;
    . = ALIGN(8);
    __am_apps_bss_start = .;
    *(__am_apps.bss*)
    *(__am_apps.sbss*)
    *(__am_apps.scommon*)
    __am_apps_bss_end = .;
    . = ALIGN(8);
    _bss_extra_end = .;
  }> PSRAM AT> FLASH
  _bss_extra_size = _bss_extra_end-_bss_extra_start;
  _bss_extra_load_start = LOADADDR(.bss.extra);
}
INSERT BEFORE .bss;