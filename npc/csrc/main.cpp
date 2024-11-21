#include "Vysyx_24110015_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#define CONFIG_MSIZE 0x8000000
#define CONFIG_MBASE 0x80000000
#define PG_ALIGN __attribute((aligned(4096)))

typedef uint32_t paddr_t;
typedef uint32_t word_t;

static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr) {
  word_t ret = *guest_to_host(addr);
  return ret;
}

static void pmem_write(paddr_t addr, word_t data) {
  *guest_to_host(addr) = data;
}

int main(int argc, char** argv) {

  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vysyx_24110015_top* top = new Vysyx_24110015_top{contextp};

  VerilatedVcdC* tfp = new VerilatedVcdC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("./build/simx.vcd");
  
  // 初始化内存
  pmem_write(0x80000000, 0x00108093);
  pmem_write(0x80000004, 0x00208093);
  pmem_write(0x80000008, 0x00308093);
  pmem_write(0x8000000c, 0x00408093);
  pmem_write(0x80000010, 0x00508093);

 for(int i=0; i<5 ; i++){
    contextp->timeInc(1);
    top->inst = pmem_read(top->pc);
    top->eval();
    tfp->dump(contextp->time());
  }

  // nvboard_quit();
  tfp->close();
  delete top;

  return 0;
}
