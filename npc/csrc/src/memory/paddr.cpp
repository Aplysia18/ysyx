#include "memory/paddr.hpp"
#include "common.hpp"
#include "cpu/cpu.hpp"
#include "cpu/difftest.hpp"
#include "utils.hpp"

extern bool abort_flag;

static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
static uint8_t mrom[MROM_SIZE] PG_ALIGN = {};
static uint8_t sram[SRAM_SIZE] PG_ALIGN = {};
static uint8_t flash[FLASH_SIZE] PG_ALIGN = {};
static uint8_t psram[PSRAM_SIZE] PG_ALIGN = {};
static uint8_t sdram[SDRAM_SIZE] PG_ALIGN = {};

static inline word_t host_read(void *addr, int len) {
  switch (len) {
    case 1: return *(uint8_t  *)addr;
    case 2: return *(uint16_t *)addr;
    case 4: return *(uint32_t *)addr;
    default: assert(0);
  }
}

static inline bool in_mrom(paddr_t addr) { return addr - MROM_BASE < MROM_SIZE; }
uint8_t* mrom_guest_to_host(paddr_t paddr) { return mrom + paddr - MROM_BASE; }
static word_t mrom_read(paddr_t addr, int len) {
  word_t ret = host_read(mrom_guest_to_host(addr), len);
  return ret;
}
static void mrom_write(paddr_t addr, int len, word_t data) {
  printf("can not write to mrom: address = " FMT_PADDR "\n", addr);
  abort_flag = 1;
}


static inline bool in_sram(paddr_t addr) { return addr - SRAM_BASE < SRAM_SIZE; }
uint8_t* sram_guest_to_host(paddr_t paddr) { return sram + paddr - SRAM_BASE; }
static word_t sram_read(paddr_t addr, int len) {
  word_t ret = host_read(sram_guest_to_host(addr), len);
  return ret;
}
static void sram_write(paddr_t addr, word_t data, char mask) {
  for(int i = 0; i < 4; i++) {
    if(mask & (1 << i)) {
      *(uint8_t*)sram_guest_to_host(addr + i) = (data >> (i * 8)) & 0xff;
    }
  }
}

static inline bool in_flash(paddr_t addr) { return addr - FLASH_BASE < FLASH_SIZE; }
uint8_t* flash_guest_to_host(paddr_t paddr) { return flash + paddr - FLASH_BASE; }
static word_t flash_read(paddr_t addr, int len) {
  word_t ret = host_read(flash_guest_to_host(addr), len);
  return ret;
}
static void flash_write(paddr_t addr, word_t data, char mask) {
  for(int i = 0; i < 4; i++) {
    if(mask & (1 << i)) {
      *(uint8_t*)flash_guest_to_host(addr + i) = (data >> (i * 8)) & 0xff;
    }
  }
}

static inline bool in_psram(paddr_t addr) { return addr - PSRAM_BASE < PSRAM_SIZE; }
uint8_t* psram_guest_to_host(paddr_t paddr) { return psram + paddr - PSRAM_BASE; }
static word_t psram_read(paddr_t addr, int len) {
  word_t ret = host_read(psram_guest_to_host(addr), len);
  return ret;
}
static void psram_write(paddr_t addr, word_t data, char mask) {
  for(int i = 0; i < 4; i++) {
    if(mask & (1 << i)) {
      *(uint8_t*)psram_guest_to_host(addr + i) = (data >> (i * 8)) & 0xff;
    }
  }
}

static inline bool in_sdram(paddr_t addr) { return addr - SDRAM_BASE < SDRAM_SIZE; }
uint8_t* sdram_guest_to_host(paddr_t paddr) { return sdram + paddr - SDRAM_BASE; }
static word_t sdram_read(paddr_t addr, int len) {
  word_t ret = host_read(sdram_guest_to_host(addr), len);
  return ret;
}
static void sdram_write(paddr_t addr, word_t data, char mask) {
  for(int i = 0; i < 4; i++) {
    if(mask & (1 << i)) {
      *(uint8_t*)sdram_guest_to_host(addr + i) = (data >> (i * 8)) & 0xff;
    }
  }
}

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static inline bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

int pmem_read(int raddr) {
#ifdef CONFIG_MTRACE
  printf("pmem_read: addr = " FMT_PADDR "\n", raddr);
#endif
  // if(raddr & 0x3) {
  //   printf("pmem_read: unaligned address 0x%x\n", raddr);
  //   abort_flag = 1;
  //   return 0;
  // }
  if(in_mrom(raddr)) {
    return mrom_read(raddr, 4);
  }
  if(in_sram(raddr)) {
    return sram_read(raddr, 4);
  }
  if(in_flash(raddr)) {
    return flash_read(raddr, 4);
  }
  if(in_psram(raddr)) {
    return psram_read(raddr, 4);
  }
  if(in_sdram(raddr)) {
    return sdram_read(raddr, 4);
  }
#ifdef CONFIG_CLINT
  if((raddr >= CONFIG_CLINT) && (raddr < CONFIG_CLINT + CONFIG_CLINT_SIZE)) {
    difftest_skip_ref();
    return 0;
  }
#endif
#ifdef CONFIG_UART
  if((raddr >= CONFIG_UART) && (raddr < CONFIG_UART + CONFIG_UART_SIZE)) {
    difftest_skip_ref();
    return 0;
  }
#endif
#ifdef CONFIG_GPIO
  if((raddr >= CONFIG_GPIO) && (raddr < CONFIG_GPIO + CONFIG_GPIO_SIZE)) {
    difftest_skip_ref();
    return 0;
  }
#endif
#ifdef CONFIG_SPI_MASTER
  if((raddr >= CONFIG_SPI_MASTER) && (raddr < CONFIG_SPI_MASTER + CONFIG_SPI_MASTER_SIZE)) {
    difftest_skip_ref();
    return 0;
  }
#endif
  #ifdef CONFIG_RTC_MMIO
  static uint64_t us = get_time();
  if((raddr == CONFIG_RTC_MMIO) || (raddr == CONFIG_RTC_MMIO + 4)) {
    difftest_skip_ref();
    return 0; 
  }
#endif
  printf("pmem_read: invalid address 0x%x\n", raddr);
  abort_flag = 1;
  return 0;

}

void pmem_write(int waddr, int wdata, char wmask) {
#ifdef CONFIG_MTRACE
  printf("pmem_write: addr = " FMT_PADDR ", data = " FMT_WORD ", mask = 0x%x\n", waddr, wdata, wmask);
#endif
  if(in_sram(waddr)) {
    // printf("in sram begin\n");
    // sram_write(waddr, 4, wdata);
    // printf("in sram done\n");
    return;
  }
  if(in_flash(waddr)) {
    // flash_write(waddr, wdata, wmask);
    return;
  }
  if(in_psram(waddr)) {
    // psram_write(waddr, wdata, wmask);
    return;
  }
  if(in_sdram(waddr)) {
    // sdram_write(waddr, wdata, wmask);
    return;
  }

#ifdef CONFIG_SERIAL_MMIO
  if(waddr == CONFIG_SERIAL_MMIO) {
    difftest_skip_ref();
    return;
  }
#endif
#ifdef CONFIG_RTC_MMIO
  if(waddr == CONFIG_RTC_MMIO || waddr == CONFIG_RTC_MMIO + 4) {
    difftest_skip_ref();
    return;
  }
#endif
#ifdef CONFIG_CLINT
  if((waddr >= CONFIG_CLINT) && (waddr < CONFIG_CLINT + CONFIG_CLINT_SIZE)) {
    difftest_skip_ref();
    return;
  }
#endif
#ifdef CONFIG_UART
  if((waddr >= CONFIG_UART) && (waddr < CONFIG_UART + CONFIG_UART_SIZE)) {
    difftest_skip_ref();
    return;
  }
#endif
#ifdef CONFIG_GPIO
  if((waddr >= CONFIG_GPIO) && (waddr < CONFIG_GPIO + CONFIG_GPIO_SIZE)) {
    difftest_skip_ref();
    return;
  }
#endif
#ifdef CONFIG_SPI_MASTER
  if((waddr >= CONFIG_SPI_MASTER) && (waddr < CONFIG_SPI_MASTER + CONFIG_SPI_MASTER_SIZE)) {
    difftest_skip_ref();
    return;
  }
#endif
  printf("pmem_write: invalid address 0x%x\n", waddr);
  abort_flag = 1;
  return;
  // if(waddr & 0x3) {
  //   printf("pmem_write: unaligned address 0x%x\n", waddr);
  //   abort_flag = 1;
  // }
  // for(int i = 0; i < 4; i++) {
  //   if(wmask & (1 << i)) {
  //     *(uint8_t*)guest_to_host(waddr + i) = (wdata >> (i * 8)) & 0xff;
  //   }
  // }
  // printf("pmem end\n");
}