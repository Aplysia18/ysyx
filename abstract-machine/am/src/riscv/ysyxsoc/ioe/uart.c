#include <am.h>
#include <riscv/riscv.h>

void __am_uart_rx(AM_UART_RX_T *rx) {
  uint8_t ch = inb(0x10000000);
  if (ch == 0) {
    rx->data = 0xff;
  }else {
    rx->data = ch;
  }
  return;

}

