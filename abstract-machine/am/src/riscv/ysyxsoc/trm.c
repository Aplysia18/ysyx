#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <riscv/riscv.h>

#define UART_BASE 0x10000000L
#define UART_TX   0
#define UART_LCR  3
#define UART_LSR 5
#define UART_DL_LSB 0
#define UART_DL_MSB 1

extern char _heap_start, _heap_end;
int main(const char *args);
void __attribute__((section(".ssbl"))) _ssbl();
void _trm_init();

#define SRAM_BEGIN 0x0f000000
#define SRAM_SIZE  0x00002000

Area heap = RANGE(&_heap_start, &_heap_end);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

extern char _ssbl_size[];
extern char _ssbl_start[];
extern char _ssbl_load_start[];
extern char _text_size[];
extern char _text_start[];
extern char _text_load_start[];
extern char _rodata_size[];
extern char _rodata_start[];
extern char _rodata_load_start[];
extern char _data_size[];
extern char _data_start[];
extern char _data_load_start[];
extern char _bss_size[];
extern char _bss_start[];
extern char _bss_load_start[];

void __attribute__((section(".fsbl"))) _fsbl() {
  // copy ssbl
  char *src = _ssbl_load_start;
  char *dst = _ssbl_start;
  while(src < _ssbl_load_start + (size_t)_ssbl_size){
    *dst = *src;
    src++;
    dst++;
  }

  //jump to _ssbl
  asm volatile (
    "la t0, %0\n"
    "jr t0\n"
    :
    : "i"(_ssbl)
    : "t0"
  );
}

void __attribute__((section(".ssbl"))) _ssbl(){
  // copy text
  char *src = _text_load_start;
  char *dst = _text_start;
  while(src < _text_load_start + (size_t)_text_size){
    *dst = *src;
    src++;
    dst++;
  }
  //copy rodata
  src = _rodata_load_start;
  dst = _rodata_start;
  while(src < _rodata_load_start + (size_t)_rodata_size){
    *dst = *src;
    src++;
    dst++;
  }
  // copy data
  src = _data_load_start;
  dst = _data_start;
  while(src < _data_load_start + (size_t)_data_size){
    *dst = *src;
    src++;
    dst++;
  }
  //bss set to 0
  dst = _bss_start;
  while(dst < _bss_start + (size_t)_bss_size){
    *dst = 0;
    dst++;
  }

  //jump to _trm_init
  asm volatile (
    "la t0, %0\n"
    "jr t0\n"
    :
    : "i"(_trm_init)
    : "t0"
  );
}

void uart_init() {
  // 1. Set the Line Control Register bit 7 to 1
  char lcr = *(volatile char *)(UART_BASE + UART_LCR);
  lcr |= 0x80;
  *(volatile char *)(UART_BASE + UART_LCR) = lcr;
  // 2. Set the Divisor Latch to control baud rate
  *(volatile char *)(UART_BASE + UART_DL_MSB) = 0x00;
  *(volatile char *)(UART_BASE + UART_DL_LSB) = 0x01;
  // 3. Set the Line Control Register bit 7 to 0
  lcr &= 0x7f;
  *(volatile char *)(UART_BASE + UART_LCR) = lcr;
}

void putch(char ch) {
  while(!(*(volatile char *)(UART_BASE + UART_LSR) & 0x20)) {
    // wait for the UART to be ready
  }
    *(volatile char *)(UART_BASE + UART_TX) = ch;
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  while (1);
}

void printid() {
  unsigned int mvendorid, marchid;

  asm volatile ("csrr %0, mvendorid" : "=r"(mvendorid)); // read mvendorid
  asm volatile ("csrr %0, marchid" : "=r"(marchid));     // read marchid

  // 输出 mvendorid
  putch('y'); putch('s'); putch('y'); putch('x'); putch(':'); putch(' '); putch('0'); putch('x');
  for (int i = 28; i >= 0; i -= 4) {
    putch("0123456789ABCDEF"[(mvendorid >> i) & 0xF]); // 按十六进制输出
  }
  putch('\n');

  // 输出 marchid
  putch('i'); putch('d'); putch(':'); putch(' '); putch('0'); putch('x');
  for (int i = 28; i >= 0; i -= 4) {
    putch("0123456789ABCDEF"[(marchid >> i) & 0xF]); // 按十六进制输出
  }
  putch('\n');
}

void _trm_init() {
  uart_init();
  printid();
  int ret = main(mainargs);
  halt(ret);
}
