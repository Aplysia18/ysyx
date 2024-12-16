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
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (direction == DIFFTEST_TO_REF) {
    printf("%02x\n",paddr_read(addr, 1));
    for (size_t i = 0; i < n; i++) {
      paddr_write(addr+i, 1, *((uint8_t*)buf+i));
      printf("%02x\n",paddr_read(addr, 1));
    }
  } else {
    assert(0);
  }
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  if (direction == DIFFTEST_TO_REF){
    for (size_t i = 0; i < RISCV_GPR_NUM; i++) {
      cpu.gpr[i] = dut.gpr[i];
    }
    cpu.pc = dut.pc;
    printf("dut pc: %08x\n", dut.pc);
    printf("pc: %08x\n", cpu.pc);
  } else {
    for (size_t i = 0; i < RISCV_GPR_NUM; i++) {
      dut_r.gpr[i] = cpu.gpr[i];
    }
    dut_r->pc = cpu.pc;
  }
}

__EXPORT void difftest_exec(uint64_t n) {
  printf("difftest exec\n");
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
