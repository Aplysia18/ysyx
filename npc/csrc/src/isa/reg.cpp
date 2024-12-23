#include <isa/reg.hpp>

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5"
//   "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
//   "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
  for (int i = 0; i < 16; i++) {
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
 
  for(int i = 1; i <16; i++){
    if(strcmp(s, regs[i]) == 0){
      return gpr(i);
    }
  }

  *success = false;
  
  return 0;
}
