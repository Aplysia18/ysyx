#include <cpu/cpu.hpp>
#include <cpu/decode.hpp>
#include <cpu/ftrace.hpp>
#include <isa/isa-def.hpp>
#include <cpu/difftest.hpp>
#include <common.hpp>

#if CONFIG_SOC==1
VysyxSoCFull* top;
#else
Vysyx_24110015* top;
#endif
VerilatedContext* contextp;
VerilatedFstC* tfp;

#if CONFIG_SOC==1
void nvboard_bind_all_pins(TOP_NAME* top);
#endif

#define RESET_CYCLE 20
CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint64_t cycles_num = 0;

// performance counters
uint64_t g_ifu_fetch = 0; // instruction fetch
uint64_t g_lsu_fetch = 0; // data fetch
typedef struct {
  uint64_t num;
  uint64_t cycles;
  uint64_t ifu;
  uint64_t idu;
  uint64_t lsu;
} inst_perf_t;
typedef struct {
  inst_perf_t compute;
  inst_perf_t load;
  inst_perf_t store;
  inst_perf_t branch;
  inst_perf_t jump;
  inst_perf_t fence;
  inst_perf_t zicsr;
  inst_perf_t ecall;
  inst_perf_t ebreak;
} inst_type_t;
inst_type_t g_inst_type = {
  .compute = {0, 0, 0, 0, 0},
  .load = {0, 0, 0, 0, 0},
  .store = {0, 0, 0, 0, 0},
  .branch = {0, 0, 0, 0, 0},
  .jump = {0, 0, 0, 0, 0},
  .fence = {0, 0, 0, 0, 0},
  .zicsr = {0, 0, 0, 0, 0},
  .ecall = {0, 0, 0, 0, 0},
  .ebreak = {0, 0, 0, 0, 0}
};
void ifu_fetch() {g_ifu_fetch++;}
void lsu_fetch() {g_lsu_fetch++;}
void icache_valid();
void icache_ready();
uint64_t ifu_state_cnt = 0; //wbu+ifu
uint64_t idu_state_cnt = 1; //idu+exu, tied to 1
uint64_t lsu_state_cnt = 0; 
void update_performance_counters(uint32_t inst);

void performance_log();

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);

static void single_cycle() {
#ifdef CONFIG_NVBOARD
  nvboard_update();
#endif

  top->clock = 0;
  top->eval();
  contextp->timeInc(1);
#ifdef CONFIG_FST_TRACE
#ifdef CONFIG_FST_TRACE_NUM
if(g_nr_guest_inst < CONFIG_FST_TRACE_NUM)
#endif
  tfp->dump(contextp->time());
#endif

  top->clock = 1;
  top->eval();
  contextp->timeInc(1);
#ifdef CONFIG_FST_TRACE
#ifdef CONFIG_FST_TRACE_NUM
if(g_nr_guest_inst < CONFIG_FST_TRACE_NUM)
#endif
  tfp->dump(contextp->time());
#endif
}

static void update_cpu_state() {
#if CONFIG_SOC==1
  cpu.pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu;
  for(int i = 0; i < 16; i++) cpu.gpr[i] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__idu__DOT__rf__DOT__rf[i];
  cpu.csr.mstatus = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mstatus;
  cpu.csr.mepc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mepc;
  cpu.csr.mcause = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mcause;
  cpu.csr.mtvec = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mtvec;
  cpu.csr.mvendorid = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_mvendorid;
  cpu.csr.marchid = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__dout_marchid;
#else 
  cpu.pc = top->rootp->ysyx_24110015__DOT__pc_ifu;
  for(int i = 0; i < 16; i++) cpu.gpr[i] = top->rootp->ysyx_24110015__DOT__idu__DOT__rf__DOT__rf[i];
  cpu.csr.mstatus = top->rootp->ysyx_24110015__DOT__dout_mstatus;
  cpu.csr.mepc = top->rootp->ysyx_24110015__DOT__dout_mepc;
  cpu.csr.mcause = top->rootp->ysyx_24110015__DOT__dout_mcause;
  cpu.csr.mtvec = top->rootp->ysyx_24110015__DOT__dout_mtvec;
  cpu.csr.mvendorid = top->rootp->ysyx_24110015__DOT__dout_mvendorid;
  cpu.csr.marchid = top->rootp->ysyx_24110015__DOT__dout_marchid;
#endif
}

static void reset(int n){
  top->reset = 1;
  while(n--) single_cycle();
  top->reset = 0;
  
  update_cpu_state();
}

uint8_t *cpu_state;

void init_cpu(int argc, char* argv[]) {

  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
#if CONFIG_SOC==1
  top = new VysyxSoCFull{contextp};
#else
  top = new Vysyx_24110015{contextp};
#endif
  #ifdef CONFIG_FST_TRACE
  tfp = new VerilatedFstC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("./build/simx.fst");
#endif
#ifdef CONFIG_NVBOARD
  nvboard_bind_all_pins(top);
  nvboard_init();
#endif
  // printf("init cpu\n");
  reset(RESET_CYCLE);
  //跳过reset后的idle状态
#if CONFIG_SOC==1
  cpu_state = &(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__controller__DOT__state);
#else
  cpu_state = &(top->rootp->ysyx_24110015__DOT__controller__DOT__state);
#endif
  do{
    single_cycle();
    // printf("state = %d\n", *cpu_state);
  }while(*cpu_state != 1);
  cycles_num++;
  int cnt = 0;
  ifu_state_cnt = 0;
  while(*cpu_state == 1){
    single_cycle();
    cycles_num++;
    ifu_state_cnt++;
    cnt++;
    if(cnt > 10000){
      printf("init cpu failed, state = %d\n", *cpu_state);
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
  g_inst_type.ebreak.num += 1;
  g_inst_type.ebreak.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
  g_inst_type.ebreak.ifu += ifu_state_cnt;
  g_inst_type.ebreak.idu += idu_state_cnt;
  g_inst_type.ebreak.lsu += lsu_state_cnt;
  g_nr_guest_inst += 1;

} 

static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {
    log_write("%s\n", _this->logbuf);
    difftest_step(_this->pc, dnpc);
    check_watchpoints();
}

static void execute_once(Decode *s){
#if CONFIG_SOC==1
  s->pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu;
  s->snpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu + 4;
#else
  s->pc = top->rootp->ysyx_24110015__DOT__pc_ifu;
  s->snpc = top->rootp->ysyx_24110015__DOT__pc_ifu + 4;
#endif
  // execute
  int cnt = 0;
  do{
    if(*cpu_state==3){
      #if CONFIG_SOC==1
      s->inst = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__inst;
      #else
      s->inst = top->rootp->ysyx_24110015__DOT__inst;
      #endif
      // printf("pc = 0x%08x, inst = 0x%08x\n", s->pc, s->inst);
    }
    // printf("state = %d\n", *cpu_state);
    single_cycle();
    cycles_num++;
    lsu_state_cnt++;
    cnt++;
    if(cnt > 10000){
      abort_flag = 1;
      break;
    }
    // printf("state = %d\n", *cpu_state);
  }while(*cpu_state != 1);
  lsu_state_cnt --;
  update_performance_counters(s->inst);
  cnt = 0;
  while(*cpu_state == 1){
    single_cycle();
    cycles_num++;
    ifu_state_cnt++;
    cnt++;
    if(cnt > 10000){
      abort_flag = 1;
      break;
    }
    // printf("state = %d\n", *cpu_state);
  }
#if CONFIG_SOC==1
  s->dnpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_ifu;
#else
  s->dnpc = top->rootp->ysyx_24110015__DOT__pc_ifu;
#endif
  update_cpu_state();

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
    // printf("before execute\n");
    // printf("pc = 0x%08x\n", s.pc);

    execute_once(&s);
    // printf("after execute\n");
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
      #if CONFIG_SOC==1
      int code = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__idu__DOT__rf__DOT__rf[10];
      #else
      int code = top->rootp->ysyx_24110015__DOT__idu__DOT__rf__DOT__rf[10];
      #endif
      if(code!=0) bad_trap_flag = 1;
      Log("npc: %s at pc = 0x%08x", (code == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED)), s.pc);
      double IPC = (double)g_nr_guest_inst / (cycles_num);
      Log("run cycles: %ld, instructions: %ld, IPC = %f", cycles_num, g_nr_guest_inst, IPC);
      performance_log();
      
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
#ifdef CONFIG_NVBOARD
  nvboard_quit();
#endif
  delete top;
  delete contextp;
  if(abort_flag || bad_trap_flag) assert(0);
}

uint64_t icache_access_num = 0;
uint64_t icache_hit_num = 0;
uint64_t icache_miss_num = 0;
uint64_t icache_access_cycles = 0;
uint64_t icache_miss_penalty_cycles = 0;
static uint64_t icache_valid_cycle = 0;
static uint64_t icache_ready_cycle = 0;
void icache_valid() {
  icache_valid_cycle = cycles_num;
  icache_access_num++;
}
void icache_ready(){
  icache_ready_cycle = cycles_num;
  icache_access_cycles++;
  if(icache_ready_cycle==icache_valid_cycle) {
    icache_hit_num++;
  }else{
    icache_miss_num++;
    icache_miss_penalty_cycles += (icache_ready_cycle - icache_valid_cycle);
  }
}

void update_performance_counters(uint32_t inst){
  uint32_t opcode = inst & 0x7f;
  switch(opcode) {
    case 0x37: // LUI
    case 0x17: // AUIPC
    case 0x13: // I-type
    case 0x33: // R-type
      g_inst_type.compute.num++;
      g_inst_type.compute.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
      g_inst_type.compute.ifu += ifu_state_cnt;
      g_inst_type.compute.idu += idu_state_cnt;
      g_inst_type.compute.lsu += lsu_state_cnt;
      break;
    case 0x6f: // JAL
    case 0x67: // JALR
      g_inst_type.jump.num++;
      g_inst_type.jump.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
      g_inst_type.jump.ifu += ifu_state_cnt;
      g_inst_type.jump.idu += idu_state_cnt;
      g_inst_type.jump.lsu += lsu_state_cnt;
      break;
    case 0x63: // B-type
      g_inst_type.branch.num++;
      g_inst_type.branch.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
      g_inst_type.branch.ifu += ifu_state_cnt;
      g_inst_type.branch.idu += idu_state_cnt;
      g_inst_type.branch.lsu += lsu_state_cnt;
      break;
    case 0x03: // Load
      g_inst_type.load.num++;
      g_inst_type.load.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
      g_inst_type.load.ifu += ifu_state_cnt;
      g_inst_type.load.idu += idu_state_cnt;
      g_inst_type.load.lsu += lsu_state_cnt;
      break;
    case 0x23: // Store
      g_inst_type.store.num++;
      g_inst_type.store.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
      g_inst_type.store.ifu += ifu_state_cnt;
      g_inst_type.store.idu += idu_state_cnt;
      g_inst_type.store.lsu += lsu_state_cnt;
      break;
    case 0x0f: // FENCE
      // FENCE, FENCE.I
      g_inst_type.fence.num++;
      g_inst_type.fence.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
      g_inst_type.fence.ifu += ifu_state_cnt;
      g_inst_type.fence.idu += idu_state_cnt;
      g_inst_type.fence.lsu += lsu_state_cnt;
      break;
    case 0x73: // System
      if (inst == 0x73) { // ECALL
        g_inst_type.ecall.num++;
        g_inst_type.ecall.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
        g_inst_type.ecall.ifu += ifu_state_cnt;
        g_inst_type.ecall.idu += idu_state_cnt;
        g_inst_type.ecall.lsu += lsu_state_cnt;
      } else if (inst == 0x00100073) { // EBREAK
        g_inst_type.ebreak.num++;
        g_inst_type.ebreak.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
        g_inst_type.ebreak.ifu += ifu_state_cnt;
        g_inst_type.ebreak.idu += idu_state_cnt;
        g_inst_type.ebreak.lsu += lsu_state_cnt;
      } else if (((inst>>12)&0x7)!=0) {
        g_inst_type.zicsr.num++; // ZICSR instructions
        g_inst_type.zicsr.cycles += ifu_state_cnt + idu_state_cnt + lsu_state_cnt;
        g_inst_type.zicsr.ifu += ifu_state_cnt;
        g_inst_type.zicsr.idu += idu_state_cnt;
        g_inst_type.zicsr.lsu += lsu_state_cnt;
      } else {
        Log("Unknown system instruction: %08x", inst);
        // assert(0);
        abort_flag = 1;
      }
      break;
    default:
      Log("Unknown instruction opcode: %02x", opcode);
      // assert(0);
      abort_flag = 1;
      break;
  }
  ifu_state_cnt = 0;
  lsu_state_cnt = 0;
}

void performance_log() {
  uint64_t ifu_cycles = g_inst_type.compute.ifu + g_inst_type.load.ifu + g_inst_type.store.ifu + g_inst_type.branch.ifu + g_inst_type.jump.ifu + g_inst_type.fence.ifu + g_inst_type.zicsr.ifu + g_inst_type.ecall.ifu + g_inst_type.ebreak.ifu;
  uint64_t idu_cycles = g_inst_type.compute.idu + g_inst_type.load.idu + g_inst_type.store.idu + g_inst_type.branch.idu + g_inst_type.jump.idu + g_inst_type.fence.idu + g_inst_type.zicsr.idu + g_inst_type.ecall.idu + g_inst_type.ebreak.idu;
  uint64_t lsu_cycles = g_inst_type.compute.lsu + g_inst_type.load.lsu + g_inst_type.store.lsu + g_inst_type.branch.lsu + g_inst_type.jump.lsu + g_inst_type.fence.lsu + g_inst_type.zicsr.lsu + g_inst_type.ecall.lsu + g_inst_type.ebreak.lsu;
  uint64_t total_cycles = ifu_cycles + idu_cycles + lsu_cycles;
  printf("Performance counters:\n");
  printf("  IFU fetch: %ld\n", g_ifu_fetch);
  printf("  LSU fetch: %ld\n", g_lsu_fetch);
  printf("  Cycles: total %ld, ifu %ld(%f%), idu %ld(%f%), lsu %ld(%f%)\n", total_cycles, ifu_cycles, (double)ifu_cycles/total_cycles*100, idu_cycles, (double)idu_cycles/total_cycles*100, lsu_cycles, (double)lsu_cycles/total_cycles*100);
  printf("  Compute: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.compute.num, 
      g_inst_type.compute.cycles, (double)g_inst_type.compute.cycles / g_inst_type.compute.num,
      g_inst_type.compute.ifu, (double)g_inst_type.compute.ifu / g_inst_type.compute.num,
      g_inst_type.compute.idu, (double)g_inst_type.compute.idu / g_inst_type.compute.num,
      g_inst_type.compute.lsu, (double)g_inst_type.compute.lsu / g_inst_type.compute.num);
  printf("  Load: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.load.num,
      g_inst_type.load.cycles, (double)g_inst_type.load.cycles / g_inst_type.load.num,
      g_inst_type.load.ifu, (double)g_inst_type.load.ifu / g_inst_type.load.num,
      g_inst_type.load.idu, (double)g_inst_type.load.idu / g_inst_type.load.num,
      g_inst_type.load.lsu, (double)g_inst_type.load.lsu / g_inst_type.load.num);
  printf("  Store: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.store.num,
      g_inst_type.store.cycles, (double)g_inst_type.store.cycles / g_inst_type.store.num,
      g_inst_type.store.ifu, (double)g_inst_type.store.ifu / g_inst_type.store.num,
      g_inst_type.store.idu, (double)g_inst_type.store.idu / g_inst_type.store.num,
      g_inst_type.store.lsu, (double)g_inst_type.store.lsu / g_inst_type.store.num);
  printf("  Branch: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.branch.num,
      g_inst_type.branch.cycles, (double)g_inst_type.branch.cycles / g_inst_type.branch.num,
      g_inst_type.branch.ifu, (double)g_inst_type.branch.ifu / g_inst_type.branch.num,
      g_inst_type.branch.idu, (double)g_inst_type.branch.idu / g_inst_type.branch.num,
      g_inst_type.branch.lsu, (double)g_inst_type.branch.lsu / g_inst_type.branch.num);
  printf("  Jump: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.jump.num,
      g_inst_type.jump.cycles, (double)g_inst_type.jump.cycles / g_inst_type.jump.num,
      g_inst_type.jump.ifu, (double)g_inst_type.jump.ifu / g_inst_type.jump.num,
      g_inst_type.jump.idu, (double)g_inst_type.jump.idu / g_inst_type.jump.num,
      g_inst_type.jump.lsu, (double)g_inst_type.jump.lsu / g_inst_type.jump.num);
  printf("  Fence: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.fence.num,
      g_inst_type.fence.cycles, (double)g_inst_type.fence.cycles / g_inst_type.fence.num,
      g_inst_type.fence.ifu, (double)g_inst_type.fence.ifu / g_inst_type.fence.num,
      g_inst_type.fence.idu, (double)g_inst_type.fence.idu / g_inst_type.fence.num,
      g_inst_type.fence.lsu, (double)g_inst_type.fence.lsu / g_inst_type.fence.num);
  printf("  ZICSR: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.zicsr.num,
      g_inst_type.zicsr.cycles, (double)g_inst_type.zicsr.cycles / g_inst_type.zicsr.num,
      g_inst_type.zicsr.ifu, (double)g_inst_type.zicsr.ifu / g_inst_type.zicsr.num,
      g_inst_type.zicsr.idu, (double)g_inst_type.zicsr.idu / g_inst_type.zicsr.num,
      g_inst_type.zicsr.lsu, (double)g_inst_type.zicsr.lsu / g_inst_type.zicsr.num);
  printf("  ECALL: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.ecall.num,
      g_inst_type.ecall.cycles, (double)g_inst_type.ecall.cycles / g_inst_type.ecall.num,
      g_inst_type.ecall.ifu, (double)g_inst_type.ecall.ifu / g_inst_type.ecall.num,
      g_inst_type.ecall.idu, (double)g_inst_type.ecall.idu / g_inst_type.ecall.num,
      g_inst_type.ecall.lsu, (double)g_inst_type.ecall.lsu / g_inst_type.ecall.num);
  printf("  EBREAK: num %ld, cycles(/inst) %ld(%f), ifu cycles %ld(%f), idu cycles %ld(%f), lsu cycles %ld(%f)\n", g_inst_type.ebreak.num,
      g_inst_type.ebreak.cycles, (double)g_inst_type.ebreak.cycles / g_inst_type.ebreak.num,
      g_inst_type.ebreak.ifu, (double)g_inst_type.ebreak.ifu / g_inst_type.ebreak.num,
      g_inst_type.ebreak.idu, (double)g_inst_type.ebreak.idu / g_inst_type.ebreak.num,
      g_inst_type.ebreak.lsu, (double)g_inst_type.ebreak.lsu / g_inst_type.ebreak.num);
  printf("  ICache: access %ld, hit %ld, miss %ld, hit rate %f, access cycles %ld, miss penalty cycles %ld, AMAT=%f\n",
      icache_access_num, icache_hit_num, icache_miss_num, (double)icache_hit_num/icache_access_num, icache_access_cycles, icache_miss_penalty_cycles, (double)icache_access_cycles/icache_access_num + (1- (double)icache_hit_num/icache_access_num) * ((double)icache_miss_penalty_cycles)/icache_miss_num);
}