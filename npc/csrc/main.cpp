#include "Vysyx_24110015_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vysyx_24110015_top__Dpi.h"
#include "memory.hpp"

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

static bool end_flag = 0;

void npc_trap(){
  end_flag = 1;
} 

int main(int argc, char** argv) {
  if(argc >= 2) {
    printf("%s\n", argv[1]);
    return 0;
  }

  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vysyx_24110015_top* top = new Vysyx_24110015_top{contextp};

  VerilatedVcdC* tfp = new VerilatedVcdC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("./build/simx.vcd");
  
  reset(top, contextp, tfp, 5);

 while(1) {
    top->inst = paddr_read(top->pc);
    printf("pc: %x, inst: %x\n", top->pc, top->inst);
    single_cycle(top, contextp, tfp);
    if(end_flag) {
      printf("Simulation finished\n");
      break;
      }
  }

  tfp->close();
  delete top;

  return 0;
}
