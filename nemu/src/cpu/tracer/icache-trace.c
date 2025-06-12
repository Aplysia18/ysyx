#include <string.h>
#include <cpu/icache-trace.h>

#if defined(CONFIG_ICACHE_TRACE)
FILE *ict_fp = NULL;

void init_icache_trace(const char *ict_file) {
  if (ict_file != NULL) {
    FILE *fp = fopen(ict_file, "w");
    Assert(fp, "Can not open '%s'", ict_file);
    ict_fp = fp;
  }
  Log("Icache trace is written to %s", ict_file ? ict_file : "NULL");
}

void icache_trace_write(vaddr_t pc) {
  fprintf(ict_fp, "l " FMT_WORD "\n", pc);
}

#else
 
void init_icache_trace(const char *ict_file) {}
void icache_trace_write(vaddr_t pc) {}

#endif