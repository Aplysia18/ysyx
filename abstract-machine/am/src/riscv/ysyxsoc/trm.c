#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <riscv/riscv.h>

#define UART_BASE 0x10000000L
#define UART_TX   0
#define UART_LCR  3
#define UART_DL_LSB 0
#define UART_DL_MSB 1

extern char _heap_start, _heap_end;
int main(const char *args);

#define SRAM_BEGIN 0x0f000000
#define SRAM_SIZE  0x00002000

Area heap = RANGE(&_heap_start, &_heap_end);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

extern char _data_size[];
extern char _data_start[];
extern char _data_load_start[];
void bootloader_copy_data(){
  if(_data_start == _data_load_start) return;
  memcpy(_data_start, _data_load_start, (size_t)_data_size);
}

void uart_init() {
  // 1. Set the Line Control Register bit 7 to 1
  char lcr = *(volatile char *)(UART_BASE + UART_LCR);
  lcr |= 0x80;
  *(volatile char *)(UART_BASE + UART_LCR) = lcr;
  // 2. Set the Divisor Latch to control baud rate
  *(volatile char *)(UART_BASE + UART_DL_MSB) = 0x11;
  *(volatile char *)(UART_BASE + UART_DL_LSB) = 0x01;
  // 3. Set the Line Control Register bit 7 to 0
  lcr &= 0x7f;
  *(volatile char *)(UART_BASE + UART_LCR) = lcr;
}

void putch(char ch) {
    *(volatile char *)(UART_BASE + UART_TX) = ch;
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  while (1);
}

void _trm_init() {
  bootloader_copy_data();
  uart_init();
  int ret = main(mainargs);
  halt(ret);
}
