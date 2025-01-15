#include <monitor/monitor.hpp>
#include <monitor/sdb.hpp>
#include <cpu/ftrace.hpp>
#include <cpu/difftest.hpp>
#include <cpu/cpu.hpp>

void init_disasm(const char *triple);
void init_difftest(char *ref_so_file, long img_size, int port);

static char *elf_file = NULL;
static char *img_file = NULL;
static char *log_file = NULL;
static char *diff_so_file = NULL;
static int difftest_port = 1234;

static void default_img() {
    // 初始化内存
    pmem_write(0x80000000, 0x00108093, 0xf);  // addi x1, x1, 1
    pmem_write(0x80000004, 0x00208093, 0xf);
    pmem_write(0x80000008, 0x00308093, 0xf);
    pmem_write(0x8000000c, 0x00408093, 0xf);
    pmem_write(0x80000010, 0x00508093, 0xf);
    pmem_write(0x80000014, 0x00100073, 0xf);
}

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    default_img();
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  if(fp==NULL) {
    printf("Can not open '%s'\n", img_file);
    assert(0);
  }

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"elf"      , required_argument, NULL, 'e'},
    {"log"      , required_argument, NULL, 'l'},\
    {"diff"     , required_argument, NULL, 'd'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhe:l:d:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'e': elf_file = optarg; break;
      case 'l': log_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-e,--elf=FILE           input ELF FILE for ftrace\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

  /* Parsing the ELF file */
  init_elf(elf_file);

  /* Open the log file. */
  init_log(log_file);

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();

  /* Initialize the CPU. */
  init_cpu(argc, argv);

  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);

  /* Initialize the simple debugger. */
  init_sdb();

  /* Initialize the disassemble */
  init_disasm("riscv32-pc-linux-gnu");

}