#include "memory/paddr.hpp"
#include "common.hpp"

static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static inline bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

static word_t pmem_read(paddr_t addr) {
  word_t ret = *(uint32_t*)guest_to_host(addr);
  return ret;
}

static void pmem_write(paddr_t addr, word_t data) {
  *(uint32_t*)guest_to_host(addr) = data;
}

word_t paddr_read(paddr_t addr) {
// #ifdef CONFIG_MTRACE
  printf("paddr_read: addr = " FMT_PADDR "\n", addr);
// #endif
  if(!in_pmem(addr)) {
    printf("paddr_read: invalid address 0x%x\n", addr);
    assert(0);
  }else return pmem_read(addr);
}

void paddr_write(paddr_t addr, word_t data) {
#ifdef CONFIG_MTRACE
  printf("paddr_write: addr = " FMT_PADDR ", data = " FMT_WORD "\n", addr, data);
#endif
  if(!in_pmem(addr)) {
    printf("paddr_write: invalid address 0x%x\n", addr);
    assert(0);
  }else return pmem_write(addr, data);
}