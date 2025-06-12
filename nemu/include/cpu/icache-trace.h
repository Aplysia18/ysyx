#ifndef __CPU_ICACHE_TRACE_H__
#define __CPU_ICACHE_TRACE_H__

#include <common.h>

void init_icache_trace(const char *ict_file);
void icache_trace_write(vaddr_t pc);

#endif // __CPU_ICACHE_TRACE_H__