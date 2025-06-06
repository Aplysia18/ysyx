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
#include "local-include/reg.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    printf("%-10s 0x%-10x %-10u\n", regs[i], gpr(i), gpr(i));
  }
}

word_t isa_reg_str2val(const char *s, bool *success) {
  if (strcmp(s, "pc") == 0) {
    return cpu.pc;
  }

  if (strcmp(s,"0" )== 0 || strcmp(s,"zero") == 0){
    return 0;
  }
 
  for(int i = 1; i <MUXDEF(CONFIG_RVE, 16, 32); i++){
    if(strcmp(s, regs[i]) == 0){
      return gpr(i);
    }
  }

  *success = false;
  
  return 0;
}

word_t *csr_reg(word_t idx){
  switch(idx&0xfff){
    case 0x300: return &cpu.csr.mstatus;
    case 0x305: return &cpu.csr.mtvec;
    case 0x341: return &cpu.csr.mepc;
    case 0x342: return &cpu.csr.mcause;
    case 0xf11: return &cpu.csr.mvendorid;
    case 0xf12: return &cpu.csr.marchid;
    default: Assert(0, "csr idx not found"); return NULL;
  }
}