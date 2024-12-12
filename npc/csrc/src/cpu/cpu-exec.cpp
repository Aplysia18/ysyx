#include <cpu/cpu.hpp>
#include <cpu/decode.hpp>
#include <cpu/ftrace.hpp>

Vysyx_24110015_top* top;
VerilatedContext* contextp;
VerilatedVcdC* tfp;

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);

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

static void trace_and_difftest(Decode *_this){
    log_write("%s\n", _this->logbuf);
    check_watchpoints();
}

static void execute_once(Decode *s, vaddr_t pc){

  top->inst = paddr_read(top->pc);

  s->pc = pc;
  s->snpc = pc + 4;
  s->inst = top->inst;

  // execute
  single_cycle();

  //itrace
  char *p = s->logbuf;
  p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":", s->pc);
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&s->inst;
  for (i = ilen - 1; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", inst[i]);
  }
  int ilen_max = 4;
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

  disassemble(p, s->logbuf + sizeof(s->logbuf) - p, s->pc, (uint8_t *)&s->inst, ilen);

  //ftrace
  if(s->inst&0xfff == 0x0ef || s->inst&0xfff == 0x0e7){
    printf("!!!");
    ftrace_call(pc, top->pc);
  }else if(s->inst == 0x00008067){
    ftrace_ret(pc);
  }

}

void cpu_exec(uint64_t n) {

  if(end_flag) {
    printf("Simulation finished\n");
    return;
  }

  Decode s;
  
  while(n--) {

    execute_once(&s, top->pc);

    trace_and_difftest(&s);


    if(end_flag) {
        Log("ftrace:");
        ftrace_log();
        printf("Simulation finished\n");
        break;
    }
    else if(sdb_stop){  //watchpoint stop the sdb
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