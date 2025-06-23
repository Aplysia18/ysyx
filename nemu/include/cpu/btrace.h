#ifndef __CPU_BTRACE_H__
#define __CPU_BTRACE_H__

#include <common.h>

typedef enum btrace_type {
	branch, jal, jalr
} btrace_type;

void init_btrace(const char *bt_file);
void btrace_write(btrace_type type, vaddr_t pc, uint32_t inst, vaddr_t dnpc);

#endif