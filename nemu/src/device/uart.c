#include <utils.h>
#include <device/map.h>

#define UART_TX   0
#define UART_LCR  3
#define UART_LSR 5
#define UART_DL_LSB 0
#define UART_DL_MSB 1

static uint8_t *uart_base = NULL;

static void uart_putc(char ch) {
  MUXDEF(CONFIG_TARGET_AM, putch(ch), putc(ch, stderr));
}

static void uart_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 1);
  switch (offset) {
    /* We bind the serial port with the host stderr in NEMU. */
    case UART_TX:
      if (is_write&&~(uart_base[UART_LCR]&0x80)) uart_putc(uart_base[0]);
      else panic("do not support read");
      break;
    case UART_DL_MSB:
      if(!is_write) panic("do not support read");
      break;
    case UART_LCR: 
      break;
    case UART_LSR:
      if(is_write) panic("do not support write");
      break;

    default: panic("do not support offset = %d", offset);
  }
}

void init_uart() {
  uart_base = new_space(8);
  uart_base[UART_LSR] = 0x20; // Transmitter is ready
#ifdef CONFIG_HAS_PORT_IO
  
#else
  add_mmio_map("uart", CONFIG_UART_MMIO, uart_base, 8, uart_io_handler);
#endif

}
