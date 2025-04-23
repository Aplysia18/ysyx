#include <monitor/monitor.hpp>
#include <monitor/sdb.hpp>
#include <cpu/cpu.hpp>

extern "C" void flash_read(int32_t addr, int32_t *data) { 
  // if((addr>FLASH_SIZE-4)||(addr%4!=0)) {
  if(addr>FLASH_SIZE-4) {
    printf("flash_read: invalid address 0x%x\n", FLASH_BASE+addr);
    assert(0);
  }
  *data = *(int32_t *)flash_guest_to_host(FLASH_BASE+addr);
  // printf("flash_read: addr = 0x%x, data = 0x%x\n", addr, *data);
}
extern "C" void mrom_read(int32_t addr, int32_t *data) 
{ 
  if((addr>MROM_BASE+MROM_SIZE-4)||(addr<MROM_BASE)||(addr%4!=0)) {
    printf("mrom_read: invalid address 0x%x\n", addr);
    assert(0);
  }
  *data = *(int32_t *)mrom_guest_to_host(addr);
}

extern "C" void psram_read(int32_t addr, char *data) {
  if(addr>=PSRAM_SIZE) {
    printf("psram_read: invalid address 0x%x\n", PSRAM_BASE+addr);
    assert(0);
  }
  printf("psram_read: before addr = 0x%08x, data = 0x%08x\n", PSRAM_BASE+addr, *data);
  *data = *(char *)psram_guest_to_host(PSRAM_BASE+addr);
  printf("psram_read: after addr = 0x%08x, data = 0x%08x\n", PSRAM_BASE+addr, *data);
}

extern "C" void psram_write(int32_t addr, char data) {
  // printf("psram_write: addr = 0x%08x, data = 0x%02x\n", PSRAM_BASE + addr, data);
  if(addr>=PSRAM_SIZE) {
    printf("psram_write: invalid address 0x%x\n", PSRAM_BASE+addr);
    assert(0);
  }
  *(char *)psram_guest_to_host(PSRAM_BASE+addr) = data;
  // printf("psram_write: end\n");
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  init_monitor(argc, argv);

  sdb_mainloop();

  exit_cpu();

  return 0;
}
