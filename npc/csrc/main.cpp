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
  if(!in_pmem(addr)) {
    printf("paddr_read: invalid address 0x%x\n", addr);
    assert(0);
  }else return pmem_read(addr);
}

void paddr_write(paddr_t addr, word_t data) {
  if(!in_pmem(addr)) {
    printf("paddr_write: invalid address 0x%x\n", addr);
    assert(0);
  }else return pmem_write(addr, data);
}

static void single_cycle(Vysyx_24110015_top* top, VerilatedContext* contextp, VerilatedVcdC* tfp) {
  top->clk = 1;
  top->eval();
  tfp->dump(contextp->time());
  contextp->timeInc(1);
  top->clk = 0;
  top->eval();
  tfp->dump(contextp->time());
  contextp->timeInc(1);
}

static void reset(Vysyx_24110015_top* top, VerilatedContext* contextp, VerilatedVcdC* tfp, int n){
  top->rst = 1;
  while(n--) single_cycle(top, contextp, tfp);
  top->rst = 0;
}

int main(int argc, char** argv) {

  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vysyx_24110015_top* top = new Vysyx_24110015_top{contextp};

  VerilatedVcdC* tfp = new VerilatedVcdC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("./build/simx.vcd");
  
  reset(top, contextp, tfp, 5);
  
  // 初始化内存
  paddr_write(0x80000000, 0x00008093);  // addi x1, x1, 1
  paddr_write(0x80000004, 0x00208093);
  paddr_write(0x80000008, 0x00308093);
  paddr_write(0x8000000c, 0x00408093);
  paddr_write(0x80000010, 0x00508093);

 for(int i=0; i<5 ; i++){
    top->inst = paddr_read(top->pc);
    printf("pc: %x, inst: %x\n", top->pc, top->inst);
    single_cycle(top, contextp, tfp);
  }

  tfp->close();
  delete top;

  return 0;
}
