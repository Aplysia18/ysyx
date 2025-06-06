/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  size_t gpr_num = sizeof(ref_r->gpr) / sizeof(ref_r->gpr[0]);
  for (size_t i = 0; i < gpr_num; i++) {
    if (ref_r->gpr[i] != cpu.gpr[i]) {
      Log("reg[%s] is different after executing instruction at pc = " FMT_WORD
          ", right = " FMT_WORD ", wrong = " FMT_WORD ", diff = " FMT_WORD,
          reg_name(i), pc, ref_r->gpr[i], cpu.gpr[i], ref_r->gpr[i] ^ cpu.gpr[i]);
      return false;
    }
  }

  if (ref_r->pc != cpu.pc) {
    Log("pc is different after executing instruction at pc = " FMT_WORD
        ", right = " FMT_WORD ", wrong = " FMT_WORD,
        pc, ref_r->pc, cpu.pc);
    for (size_t i = 0; i < gpr_num; i++) {
      Log("reg[%s] at pc = " FMT_WORD ", right = " FMT_WORD ", wrong = " FMT_WORD ", diff = " FMT_WORD,
          reg_name(i), pc, ref_r->gpr[i], cpu.gpr[i], ref_r->gpr[i] ^ cpu.gpr[i]);
    }
    return false;
  }
  

  return true;
}

void isa_difftest_attach() {
}
