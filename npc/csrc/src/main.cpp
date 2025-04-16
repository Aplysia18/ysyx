#include <monitor/monitor.hpp>
#include <monitor/sdb.hpp>
#include <cpu/cpu.hpp>

extern "C" void flash_read(int32_t addr, int32_t *data) { 
  if((addr>FLASH_BASE+FLASH_SIZE-4)||(addr<FLASH_BASE)||(addr%4!=0)) {
    printf("flash_read: invalid address 0x%x\n", addr);
    assert(0);
  }
  *data = *(int32_t *)flash_guest_to_host(addr);
}
extern "C" void mrom_read(int32_t addr, int32_t *data) 
{ 
  if((addr>MROM_BASE+MROM_SIZE-4)||(addr<MROM_BASE)||(addr%4!=0)) {
    printf("mrom_read: invalid address 0x%x\n", addr);
    assert(0);
  }
  *data = *(int32_t *)mrom_guest_to_host(addr);
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  init_monitor(argc, argv);

  sdb_mainloop();

  exit_cpu();

  return 0;
}
