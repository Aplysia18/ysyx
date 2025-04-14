#include <cpu/cpu.hpp>
#include <cpu/decode.hpp>
#include <cpu/ftrace.hpp>
#include <isa/isa-def.hpp>
#include <cpu/difftest.hpp>
#include <common.hpp>

VysyxSoCFull* top;
VerilatedContext* contextp;
VerilatedFstC* tfp;

CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
// static uint32_t npc_inst = 0;
// static uint32_t npc_pc = 0;
static uint64_t cycles_num = 0;

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);

static void single_cycle() {
  top->clock = 1;
  top->eval();
  contextp->timeInc(1);
#ifdef CONFIG_FST_TRACE
  tfp->dump(contextp->time());
#endif
  top->clock = 0;
  top->eval();
  contextp->timeInc(1);
#ifdef CONFIG_FST_TRACE
  tfp->dump(contextp->time());
#endif
  cycles_num++;
}

static void reset(int n){
  top->reset = 1;
  while(n--) single_cycle();
  top->reset = 0;
  cpu.pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu;
  for(int i = 0; i < 16; i++) cpu.gpr[i] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__idu__DOT__rf__DOT__rf[i];
  cpu.csr.mstatus = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mstatus;
  cpu.csr.mepc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mepc;
  cpu.csr.mcause = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mcause;
  cpu.csr.mtvec = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mtvec;
}

void init_cpu(int argc, char* argv[]) {

  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new VysyxSoCFull{contextp};
#ifdef CONFIG_FST_TRACE
  tfp = new VerilatedFstC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("./build/simx.fst");
#endif
  // printf("init cpu\n");
  reset(20);
  //跳过第一个周期的ifu
  do{
    single_cycle();
    // printf("state = %d\n", top->rootp->ysyx_24110015_top__DOT__controller__DOT__state);
  }while(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state != 1);
  int cnt = 0;
  while(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state == 1){
    single_cycle();
    cnt++;
    if(cnt > 20){
      abort_flag = 1;
      break;
    }
    // printf("state = %d\n", top->rootp->ysyx_24110015_top__DOT__controller__DOT__state);
  }
  // printf("init cpu done\n");
}

bool abort_flag = 0;
bool bad_trap_flag = 0;

static bool end_flag = 0;

void npc_trap(){
  // printf("npc trap\n");
  end_flag = 1;
} 

static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {
    log_write("%s\n", _this->logbuf);
    difftest_step(_this->pc, dnpc);
    check_watchpoints();
}

static void execute_once(Decode *s){
  s->pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu;
  s->snpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu + 4;
  // execute
  int cnt = 0;
  do{
    if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state==3){
      s->inst = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__inst;
      // printf("inst = 0x%08x\n", s->inst);
    }
    // printf("state = %d\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state);
    single_cycle();
    cnt++;
    if(cnt > 20){
      abort_flag = 1;
      break;
    }
    // printf("state = %d\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state);
  }while(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state != 1);
  cnt = 0;
  while(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state == 1){
    single_cycle();
    cnt++;
    if(cnt > 20){
      abort_flag = 1;
      break;
    }
    // printf("state = %d\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state);
  }
  
  s->dnpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu;

  //update cpu state
  cpu.pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu;
  for(int i = 0; i < 16; i++) {
    cpu.gpr[i] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__idu__DOT__rf__DOT__rf[i];
  }
  cpu.csr.mstatus = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mstatus;
  cpu.csr.mepc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mepc;
  cpu.csr.mcause = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mcause;
  cpu.csr.mtvec = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mtvec;

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
    ftrace_call(s->pc, s->dnpc);
  }else if(s->inst == 0x00008067){
    ftrace_ret(s->pc);
  }

}

void cpu_exec(uint64_t n) {

  if(end_flag) {
    printf("Simulation finished\n");
    return;
  }

  Decode s;
  while(n--) {
    if(abort_flag){
      end_flag = 1;
      break;
    }

    execute_once(&s);
    g_nr_guest_inst ++;
    
    trace_and_difftest(&s, cpu.pc);
    
    // if(g_nr_guest_inst >= 5000){
    //   abort_flag = 1;
    // }

    if(abort_flag){
      end_flag = 1;
      Log("npc: %s at pc = 0x%08x\n", ANSI_FMT("ABORT", ANSI_FG_RED), s.pc);
      // assert(0);
      break;
    }

    if(end_flag) {
      int code = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__idu__DOT__rf__DOT__rf[10];
      if(code!=0) bad_trap_flag = 1;
      Log("npc: %s at pc = 0x%08x\n", (code == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED)), s.pc);
      Log("run cycles: %ld\n", cycles_num);
      
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
#ifdef CONFIG_FST_TRACE
  tfp->close();
#endif
  delete top;
  delete contextp;
  if(abort_flag || bad_trap_flag) assert(0);
}