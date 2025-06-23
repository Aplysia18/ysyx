#include <string.h>
#include <cpu/btrace.h>

#if defined(CONFIG_BTRACE)
FILE *bt_fp = NULL;

void init_btrace(const char *bt_file) {
  if (bt_file != NULL) {
    FILE *fp = fopen(bt_file, "w");
    Assert(fp, "Can not open '%s'", bt_file);
    bt_fp = fp;
  }
  Log("Btrace is written to %s", bt_file ? bt_file : "NULL");
}

void btrace_write(btrace_type type, vaddr_t pc, uint32_t inst, vaddr_t dnpc){
  if (bt_fp == NULL) return;

  switch (type) {
    case branch:
      fprintf(bt_fp, "branch " FMT_WORD " " FMT_WORD " " FMT_WORD "\n", pc, inst, dnpc);
      break;
    case jal:
      fprintf(bt_fp, "jal    " FMT_WORD " " FMT_WORD " " FMT_WORD "\n", pc, inst, dnpc);
      break;
    case jalr:
      fprintf(bt_fp, "jalr   " FMT_WORD " " FMT_WORD " " FMT_WORD "\n", pc, inst, dnpc);
      break;
    default:
      Assert(0, "Unknown btrace type: %d", type);
      break;
  }
}

#else
 
void init_btrace(const char *bt_file) {}
void btrace_write(btrace_type type, vaddr_t pc, uint32_t inst, vaddr_t dnpc) {}

#endif