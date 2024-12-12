#include <cpu/cpu.hpp>

Vysyx_24110015_top* top;
VerilatedContext* contextp;
VerilatedVcdC* tfp;

static void single_cycle() {
  top->clk = 1;
  top->eval();
  tfp->dump(contextp->time());
  contextp->timeInc(1);
  top->clk = 0;
  top->eval();
  tfp->dump(contextp->time());
  contextp->timeInc(1);
}

static void reset(int n){
  top->rst = 1;
  while(n--) single_cycle();
  top->rst = 0;
}

void init_cpu(int argc, char* argv[]) {

  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new Vysyx_24110015_top{contextp};

  tfp = new VerilatedVcdC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("./build/simx.vcd");
  
  reset(5);

}

static bool end_flag = 0;

void npc_trap(){
  int code = top->rootp->ysyx_24110015_top__DOT__rf__DOT__rf[10];
  Log("npc: %s at pc = 0x%08x\n", (code == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED)), top->pc);
  end_flag = 1;
} 

static void trace_and_difftest(){
    check_watchpoints();
}

void cpu_exec(uint64_t n) {
  if(end_flag) {
    printf("Simulation finished\n");
    return;
  }

  while(n--) {
    top->inst = paddr_read(top->pc);
    // printf("pc: %x, inst: %x\n", top->pc, top->inst);

    single_cycle();
    trace_and_difftest();
    if(end_flag) {
        printf("Simulation finished\n");
        break;
    }
    else if(sdb_stop){
        sdb_stop = false;
        break;
    }
  }
}

void exit_cpu() {
  tfp->close();
  delete top;
  delete contextp;
}