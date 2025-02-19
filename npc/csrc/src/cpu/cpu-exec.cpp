#include <cpu/cpu.hpp>
#include <cpu/decode.hpp>
#include <cpu/ftrace.hpp>
#include <isa/isa-def.hpp>
#include <cpu/difftest.hpp>
#include <common.hpp>

Vysyx_24110015_top* top;
VerilatedContext* contextp;
VerilatedFstC* tfp;

CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint32_t npc_inst = 0;
static uint32_t npc_pc = 0;
static uint32_t npc_dnpc = 0;

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);

static void single_cycle() {
  top->clk = 1;
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
  top->clk = 0;
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

static void reset(int n){
  top->rst = 1;
  while(n--) single_cycle();
  top->rst = 0;
  cpu.pc = 0x80000000;
  for(int i = 0; i < 16; i++) cpu.gpr[i] = top->rootp->ysyx_24110015_top__DOT__rf__DOT__rf[i];
  cpu.csr.mstatus = top->rootp->ysyx_24110015_top__DOT__exu__DOT__dout_mstatus;
  cpu.csr.mepc = top->rootp->ysyx_24110015_top__DOT__exu__DOT__dout_mepc;
  cpu.csr.mcause = top->rootp->ysyx_24110015_top__DOT__exu__DOT__dout_mcause;
  cpu.csr.mtvec = top->rootp->ysyx_24110015_top__DOT__exu__DOT__dout_mtvec;
}

void init_cpu(int argc, char* argv[]) {

  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new Vysyx_24110015_top{contextp};

  tfp = new VerilatedFstC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("./build/simx.fst");
  
  reset(5);
  single_cycle();
}

bool abort_flag = 0;
bool bad_trap_flag = 0;

static bool end_flag = 0;

void npc_trap(){
  end_flag = 1;
} 

void get_inst(int inst){
  npc_inst = (uint32_t)inst;
}

void get_pc(int pc){
  npc_pc = (uint32_t)pc;
}

void get_dnpc(int dnpc){
  npc_dnpc = (uint32_t)dnpc;
}

bool difftest_skip_next = false;

static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {
    log_write("%s\n", _this->logbuf);
    difftest_step(_this->pc, dnpc);
    if(difftest_skip_next){
      difftest_skip_next = false;
      difftest_skip_ref();
    }
    check_watchpoints();
}

static void execute_once(Decode *s){
  s->inst = npc_inst;
  s->pc = npc_pc;
  s->snpc = npc_pc + 4;
  // execute
  single_cycle();
  // printf("single cycle, pc = 0x%08x\n", s->pc);
  
  s->dnpc = npc_pc;

  //update cpu state
  cpu.pc = npc_pc;
  for(int i = 0; i < 16; i++) {
    cpu.gpr[i] = top->rootp->ysyx_24110015_top__DOT__rf__DOT__rf[i];
  }
  cpu.csr.mstatus = top->rootp->ysyx_24110015_top__DOT__exu__DOT__dout_mstatus;
  cpu.csr.mepc = top->rootp->ysyx_24110015_top__DOT__exu__DOT__dout_mepc;
  cpu.csr.mcause = top->rootp->ysyx_24110015_top__DOT__exu__DOT__dout_mcause;
  cpu.csr.mtvec = top->rootp->ysyx_24110015_top__DOT__exu__DOT__dout_mtvec;

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
  if((s->inst&0xfff) == 0x0ef || (s->inst&0xfff) == 0x0e7){
    ftrace_call(npc_pc, npc_dnpc);
  }else if(s->inst == 0x00008067){
    ftrace_ret(npc_pc);
  }

}

void cpu_exec(uint64_t n) {

  if(end_flag) {
    printf("Simulation finished\n");
    return;
  }

  Decode s;
  while(n--) {

    execute_once(&s);
    g_nr_guest_inst ++;
    trace_and_difftest(&s, cpu.pc);

    if(abort_flag){
      end_flag = 1;
      Log("npc: %s at pc = 0x%08x\n", ANSI_FMT("ABORT", ANSI_FG_RED), s.pc);
      // assert(0);
      break;
    }

    if(end_flag) {
      int code = top->rootp->ysyx_24110015_top__DOT__rf__DOT__rf[10];
      if(code!=0) bad_trap_flag = 1;
      Log("npc: %s at pc = 0x%08x\n", (code == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED)), s.pc);
      
      // Log("ftrace:");
      // ftrace_log();
      
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
  if(abort_flag || bad_trap_flag) assert(0);
}