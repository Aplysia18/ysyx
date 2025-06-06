/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

#if defined(CONFIG_TARGET_SHARE)
static inline bool in_mrom(paddr_t addr) { return addr - CONFIG_MROM_BASE < CONFIG_MROM_SIZE; }
static uint8_t mrom[CONFIG_MROM_SIZE] PG_ALIGN = {};
uint8_t* mrom_guest_to_host(paddr_t paddr) { return mrom + paddr - CONFIG_MROM_BASE; }
static word_t mrom_read(paddr_t addr, int len) {
  word_t ret = host_read(mrom_guest_to_host(addr), len);
  return ret;
}
static void mrom_write(paddr_t addr, int len, word_t data) {
  panic("can not write to mrom: address = " FMT_PADDR ", pc = " FMT_WORD, addr, cpu.pc);
}
void mrom_write_init(paddr_t addr, int len, word_t data) {
  host_write(mrom_guest_to_host(addr), len, data);
}

static inline bool in_sram(paddr_t addr) { return addr - CONFIG_SRAM_BASE < CONFIG_SRAM_SIZE; }
static uint8_t sram[CONFIG_SRAM_SIZE] PG_ALIGN = {};
uint8_t* sram_guest_to_host(paddr_t paddr) { return sram + paddr - CONFIG_SRAM_BASE; }
static word_t sram_read(paddr_t addr, int len) {
  word_t ret = host_read(sram_guest_to_host(addr), len);
  return ret;
}
static void sram_write(paddr_t addr, int len, word_t data) {
  host_write(sram_guest_to_host(addr), len, data);
}

static inline bool in_flash(paddr_t addr) { return addr - CONFIG_FLASH_BASE < CONFIG_FLASH_SIZE; }
static uint8_t flash[CONFIG_FLASH_SIZE] PG_ALIGN = {};
uint8_t* flash_guest_to_host(paddr_t paddr) { return flash + paddr - CONFIG_FLASH_BASE; }
static word_t flash_read(paddr_t addr, int len) {
  word_t ret = host_read(flash_guest_to_host(addr), len);
  return ret;
}
static void flash_write(paddr_t addr, int len, word_t data) {
  host_write(flash_guest_to_host(addr), len, data);
}

static inline bool in_psram(paddr_t addr) { return addr - CONFIG_PSRAM_BASE < CONFIG_PSRAM_SIZE; }
static uint8_t psram[CONFIG_PSRAM_SIZE] PG_ALIGN = {};
uint8_t* psram_guest_to_host(paddr_t paddr) { return psram + paddr - CONFIG_PSRAM_BASE; }
static word_t psram_read(paddr_t addr, int len) {
  word_t ret = host_read(psram_guest_to_host(addr), len);
  return ret;
}
static void psram_write(paddr_t addr, int len, word_t data) {
  host_write(psram_guest_to_host(addr), len, data);
}

static inline bool in_sdram(paddr_t addr) { return addr - CONFIG_SDRAM_BASE < CONFIG_SDRAM_SIZE; }
static uint8_t sdram[CONFIG_SDRAM_SIZE] PG_ALIGN = {};
uint8_t* sdram_guest_to_host(paddr_t paddr) { return sdram + paddr - CONFIG_SDRAM_BASE; }
static word_t sdram_read(paddr_t addr, int len) {
  word_t ret = host_read(sdram_guest_to_host(addr), len);
  return ret;
}
static void sdram_write(paddr_t addr, int len, word_t data) {
  host_write(sdram_guest_to_host(addr), len, data);
}

#endif

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

#if !defined(CONFIG_TARGET_SHARE)
static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}
#endif

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
#if defined(CONFIG_TARGET_SHARE)
  // printf("size of mrom: %ld\n", sizeof(mrom));
  IFDEF(CONFIG_MEM_RANDOM, memset(mrom, rand(), CONFIG_MROM_SIZE));
  Log("flash area [" FMT_PADDR ", " FMT_PADDR "]", (paddr_t)CONFIG_FLASH_BASE, (paddr_t)(CONFIG_FLASH_BASE + CONFIG_FLASH_SIZE - 1));
  Log("psram area [" FMT_PADDR ", " FMT_PADDR "]", (paddr_t)CONFIG_PSRAM_BASE, (paddr_t)(CONFIG_PSRAM_BASE + CONFIG_PSRAM_SIZE - 1));
  Log("sdram area [" FMT_PADDR ", " FMT_PADDR "]", (paddr_t)CONFIG_SDRAM_BASE, (paddr_t)(CONFIG_SDRAM_BASE + CONFIG_SDRAM_SIZE - 1));
#else
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
#endif
}

word_t paddr_read(paddr_t addr, int len) {
#ifdef CONFIG_MTRACE
  printf("paddr_read: addr = " FMT_PADDR ", len = %d\n", addr, len);
#endif
#ifdef CONFIG_TARGET_SHARE
  if (likely(in_mrom(addr))&&likely(in_mrom(addr+len-1))) return mrom_read(addr, len);
  if (likely(in_sram(addr))&&likely(in_sram(addr+len-1))) return sram_read(addr, len);
  if (likely(in_flash(addr))&&likely(in_flash(addr+len-1))) return flash_read(addr, len);
  if (likely(in_psram(addr))&&likely(in_psram(addr+len-1))) return psram_read(addr, len);
  if (likely(in_sdram(addr))&&likely(in_sdram(addr+len-1))) return sdram_read(addr, len);
#else
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
#endif
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
#ifdef CONFIG_MTRACE
  printf("paddr_write: addr = " FMT_PADDR ", len = %d, data = " FMT_WORD "\n", addr, len, data);
#endif
#ifdef CONFIG_TARGET_SHARE
  if (likely(in_mrom(addr))&&likely(in_mrom(addr+len-1))) { mrom_write(addr, len, data); return; }
  if (likely(in_sram(addr))&&likely(in_sram(addr+len-1))) { sram_write(addr, len, data); return; }
  if (likely(in_flash(addr))&&likely(in_flash(addr+len-1))) { flash_write(addr, len, data); return; }
  if (likely(in_psram(addr))&&likely(in_psram(addr+len-1))) { psram_write(addr, len, data); return; }
  if (likely(in_sdram(addr))&&likely(in_sdram(addr+len-1))) { sdram_write(addr, len, data); return; }
#else
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
#endif
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
