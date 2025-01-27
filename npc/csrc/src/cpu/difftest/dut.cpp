#include <dlfcn.h>

#include <isa/reg.hpp>
#include <isa/isa-def.hpp>
#include <cpu/cpu.hpp>
#include <memory/paddr.hpp>
#include <utils.hpp>
#include <difftest-def.hpp>
#include <cpu/difftest.hpp>
#include <common.hpp>

ref_difftest_memcpy_t ref_difftest_memcpy = NULL;
ref_difftest_regcpy_t ref_difftest_regcpy = NULL;
ref_difftest_exec_t ref_difftest_exec = NULL;
ref_difftest_raise_intr_t ref_difftest_raise_intr = NULL;
ref_difftest_init_t ref_difftest_init = NULL;

#ifdef CONFIG_DIFFTEST

static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;

// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
void difftest_skip_ref() {
  is_skip_ref = true;
  // If such an instruction is one of the instruction packing in QEMU
  // (see below), we end the process of catching up with QEMU's pc to
  // keep the consistent behavior in our best.
  // Note that this is still not perfect: if the packed instructions
  // already write some memory, and the incoming instruction in NEMU
  // will load that memory, we will encounter false negative. But such
  // situation is infrequent.
  skip_dut_nr_inst = 0;
}

// this is used to deal with instruction packing in QEMU.
// Sometimes letting QEMU step once will execute multiple instructions.
// We should skip checking until NEMU's pc catches up with QEMU's pc.
// The semantic is
//   Let REF run `nr_ref` instructions first.
//   We expect that DUT will catch up with REF within `nr_dut` instructions.
void difftest_skip_dut(int nr_ref, int nr_dut) {
  skip_dut_nr_inst += nr_dut;

  while (nr_ref -- > 0) {
    ref_difftest_exec(1);
  }
}

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (ref_difftest_memcpy_t)dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (ref_difftest_regcpy_t)dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (ref_difftest_exec_t)dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (ref_difftest_raise_intr_t)dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  ref_difftest_init = (ref_difftest_init_t)dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  size_t gpr_num = sizeof(ref_r->gpr) / sizeof(ref_r->gpr[0]);
  // printf("ref.pc: 0x%08x, nemu.pc: 0x%08x\n", ref_r->pc, cpu.pc);
  // printf("gpr[a4]: npc: 0x%08x, nemu: %08x\n", cpu.gpr[14], ref_r->gpr[14]);
  // printf("gpr[a5]: npc: 0x%08x, nemu: %08x\n", cpu.gpr[15], ref_r->gpr[15]);
  for (size_t i = 0; i < gpr_num; i++) {
    if (ref_r->gpr[i] != cpu.gpr[i]) {
      Log("reg[%s] is different after executing instruction at pc = " FMT_WORD
          ", right = " FMT_WORD ", wrong = " FMT_WORD ", diff = " FMT_WORD,
          reg_name(i), pc, ref_r->gpr[i], cpu.gpr[i], ref_r->gpr[i] ^ cpu.gpr[i]);
      // for(int j = 0; j < 16; j++) {
      //   printf("ref gpr[%s]: 0x%08x\n", reg_name(j), ref_r->gpr[j]);
      // }
      return false;
    }
    
  }

  if (ref_r->pc != cpu.pc) {
    Log("pc is different after executing instruction at pc = " FMT_WORD
        ", right = " FMT_WORD ", wrong = " FMT_WORD,
        pc, ref_r->pc, cpu.pc);
    return false;
  }
  

  return true;
}

extern bool abort_flag;

static void checkregs(CPU_state *ref, vaddr_t pc) {
  if (!isa_difftest_checkregs(ref, pc)) {
    abort_flag = true;
    isa_reg_display();
  }
}

void difftest_step(vaddr_t pc, vaddr_t npc) {
  CPU_state ref_r;

  if (skip_dut_nr_inst > 0) {
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    if (ref_r.pc == npc) {
      skip_dut_nr_inst = 0;
      checkregs(&ref_r, npc);
      return;
    }
    skip_dut_nr_inst --;
    if (skip_dut_nr_inst == 0)
      printf("can not catch up with ref.pc = " FMT_WORD " at pc = " FMT_WORD, ref_r.pc, pc);
      assert(0);
    return;
  }

  if (is_skip_ref) {
    printf("skip ref, pc = 0x%08x, npc = 0x%08x\n", pc, npc);
    // to skip the checking of an instruction, just copy the reg state to reference design
    ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    is_skip_ref = false;
    return;
  }
  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
  checkregs(&ref_r, pc);
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif