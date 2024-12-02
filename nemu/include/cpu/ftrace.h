#ifndef __CPU_FTRACE_H__

#include <elf.h>

typedef struct {
  char name[32];
  Elf32_Addr start;
  Elf32_Word size;
} function_info;

extern function_info *functions;

void init_elf(const char *elf_file);

#endif