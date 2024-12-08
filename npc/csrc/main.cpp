#include "Vysyx_24110015_top.h"
#include "Vysyx_24110015_top___024root.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vysyx_24110015_top__Dpi.h"
#include "monitor.hpp"
#include "utils.hpp"

Vysyx_24110015_top* top;

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
  int code = top->rootp->ysyx_24110015_top__DOT__rf__DOT__rf[10];
  printf("npc: %s a pc = 0x%08d\n", (code == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED)), top->pc);
  end_flag = 1;
} 

int main(int argc, char** argv) {

  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new Vysyx_24110015_top{contextp};

  VerilatedVcdC* tfp = new VerilatedVcdC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("./build/simx.vcd");
  
  reset(top, contextp, tfp, 5);

  init_monitor(argc, argv);

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
