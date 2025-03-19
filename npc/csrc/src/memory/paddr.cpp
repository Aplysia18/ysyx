#include "memory/paddr.hpp"
#include "common.hpp"
#include "cpu/cpu.hpp"
#include "cpu/difftest.hpp"
#include "utils.hpp"

extern bool abort_flag;

static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static inline bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

int pmem_read(int raddr) {
  if(!in_pmem(raddr)) {
#ifdef CONFIG_RTC_MMIO
  static uint64_t us = get_time();
  // printf("pmem_read: addr = " FMT_PADDR ", rfata = " FMT_PADDR "\n", raddr, us);
  if((raddr == CONFIG_RTC_MMIO) || (raddr == CONFIG_RTC_MMIO + 4)) {
    difftest_skip_ref();
    return 0; 
    // if(raddr == CONFIG_RTC_MMIO + 4){
    //   us = get_time();
    //   return us >> 32;
    // } else {
    //   return us & 0xffffffff;
    // }
  }
#endif
    printf("pmem_read: invalid address 0x%x\n", raddr);
    // assert(0);
    abort_flag = 1;
    return 0;
  }
  // if(raddr & 0x3) {
  //   printf("pmem_read: unaligned address 0x%x\n", raddr);
  //   assert(0);
  // }
  // int ret = *(int*)guest_to_host(raddr & ~0x3u);
  int ret = *(int*)guest_to_host(raddr);
#ifdef CONFIG_MTRACE
  // printf("pmem_read: addr = " FMT_PADDR ", rfata = " FMT_PADDR "\n", raddr & ~0x3u, ret);
  printf("pmem_read: addr = " FMT_PADDR ", rfata = " FMT_PADDR "\n", raddr, ret);
#endif
  return ret;
}

void pmem_write(int waddr, int wdata, char wmask) {
  if(!in_pmem(waddr)) {
#ifdef CONFIG_SERIAL_MMIO
  if(waddr == CONFIG_SERIAL_MMIO) {
    // printf("%c", wdata&0xff);
    difftest_skip_ref();
    // printf("waddr = " FMT_PADDR ", wdata = " FMT_WORD ", wmask = %d\n", waddr, wdata, wmask);
    // printf("%c", wdata&0xff);
    // putchar(wdata&0xf);
    return;
  }
#endif
#ifdef CONFIG_RTC_MMIO
  if(waddr == CONFIG_RTC_MMIO || waddr == CONFIG_RTC_MMIO + 4) {
    difftest_skip_ref();
    return;
  }
#endif
    printf("pmem_write: invalid address 0x%x\n", waddr);
    // assert(0);
    abort_flag = 1;
    return;
  }
  // if(waddr & 0x3) {
  //   printf("pmem_write: unaligned address 0x%x\n", waddr);
  //   assert(0);
  // }
#ifdef CONFIG_MTRACE
  printf("pmem_write: addr = " FMT_PADDR ", data = " FMT_WORD ", mask = 0x%x\n", waddr, wdata, wmask);
#endif
  // int waddr_aligned = waddr & ~0x3u;
  for(int i = 0; i < 4; i++) {
    if(wmask & (1 << i)) {
      // *(uint8_t*)guest_to_host(waddr_aligned + i) = (wdata >> (i * 8)) & 0xff;
      *(uint8_t*)guest_to_host(waddr + i) = (wdata >> (i * 8)) & 0xff;
    }
  }
}