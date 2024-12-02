#ifndef __CPU_FTRACE_H__

typedef struct {
  char name[32];
  uintptr_t start;
  uintptr_t end;
} function_info;

void init_elf(const char *elf_file);

#endif