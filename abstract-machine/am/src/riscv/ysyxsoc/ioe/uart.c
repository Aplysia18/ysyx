#include <am.h>
#include <riscv/riscv.h>

#define UART_BASE 0x10000000L
#define UART_TX   0
#define UART_LCR  3
#define UART_LSR 5

void __am_uart_rx(AM_UART_RX_T *rx) {
  uint8_t ch = inb(UART_BASE);
  uint8_t lsr = *(volatile char *)(UART_BASE + UART_LSR);
  if (ch == 0 || ((lsr&0x1)==0)) {
    rx->data = 0xff;
  }else {
    rx->data = ch;
  }
  return;

}

