#ifndef __CPU_FTRACE_H__
#define __CPU_FTRACE_H__

#include <elf.h>

typedef struct {
  char name[32];
  Elf32_Addr start;
  Elf32_Word size;
} function_info;

extern function_info *functions;

void init_elf(const char *elf_file);
void ftrace_log();
void ftrace_call(vaddr_t pc, vaddr_t next_pc);
void ftrace_ret(vaddr_t pc);

#endif