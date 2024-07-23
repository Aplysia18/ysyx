#include "Vtop.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <nvboard.h>

void nvboard_bind_all_pins(TOP_NAME* top);

int main(int argc, char** argv) {

  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vtop* top = new Vtop{contextp};

  VerilatedFstC* tfp = new VerilatedFstC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("simx.fst");
  
  nvboard_bind_all_pins(top);
  nvboard_init();

  while(1){
    top->eval();
    nvboard_update();
  }

  nvboard_quit();

  return 0;
}
