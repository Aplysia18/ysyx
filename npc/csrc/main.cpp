#include "Vtop.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <nvboard.h>

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* top);

int main(int argc, char** argv) {
  nvboard_bind_all_pins(&dut);
  nvboard_init();

  while(1){
    nvboard_update();
  }

  nvboard_quit();

  return 0;
}
