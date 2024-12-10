// /***************************************************************************************
// * Copyright (c) 2014-2022 Zihao Yu, Nanjing University
// *
// * NEMU is licensed under Mulan PSL v2.
// * You can use this software according to the terms and conditions of the Mulan PSL v2.
// * You may obtain a copy of Mulan PSL v2 at:
// *          http://license.coscl.org.cn/MulanPSL2
// *
// * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// *
// * See the Mulan PSL v2 for more details.
// ***************************************************************************************/

#include <isa/reg.hpp>
#include <cpu/cpu.hpp>
#include <readline/readline.h>
#include <readline/history.h>
#include <monitor/sdb.hpp>
// #include <memory/vaddr.h>
// #include <common.h>

static int is_batch_mode = false;

// void init_regex();
// void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  return -1;
}

static int cmd_help(char *args);

static int cmd_si(char *args); 

static int cmd_info(char *args);

static int cmd_x(char *args);

// static int cmd_p(char *args);

// static int cmd_w(char *args);

// static int cmd_d(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NPC Simulation", cmd_q },
  { "si", "Execute N instructions using single step execution, N defaults to 1", cmd_si},
  { "info", "Print program states", cmd_info},
  { "x", "Examine memory", cmd_x},
  // { "p", "Print value of expression", cmd_p},
  // { "w", "Set watchpoint", cmd_w},
  // { "d", "Delete watchpoint", cmd_d},

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

static int cmd_si(char *args) {

  if(args==NULL){
    cpu_exec(1);
    return 0;
  }

  char *endptr;
  uint64_t n;

  unsigned long result = strtoul(args, &endptr, 10);

  if (*endptr != '\0') {
      printf("Invalid input si parameter!\n");
  } else {
      n = result;
      cpu_exec(n);
  }

  return 0;
}

static int cmd_info(char *args) {

  if (args == NULL) {
    printf("info r: Print registers\n");
    // printf("info w: Print watchpoints\n");
  } else if (strcmp(args, "r") == 0) {
    isa_reg_display();
  // } else if (strcmp(args, "w") == 0) {
  //   print_wp();
  } else {
    printf("Unknown info command '%s'\n", args);
  }
  return 0;
}

static int cmd_x(char *args) {

  char *arg = strtok(NULL, " ");
  if (arg == NULL) {
    printf("No length given! Please input \"x N EXPR\".\n");
    return 0;
  }

  char *endptr;
  uint64_t n = strtoul(arg, &endptr, 10);

  if (*endptr != '\0') {
    printf("Invalid input N parameter!\n");
    return 0;
  } 

  arg = strtok(NULL, " ");
  if (arg == NULL) {
    printf("No expression given! Please input \"x N EXPR\".\n");
    return 0;
  }

  bool success = true;
  printf("EXPR: %s\n", arg);
  uint32_t expr_result = expr(arg, &success);
  printf("EXPR_RESULT: %u\n", expr_result);

  uint32_t addr;

  if(success){
    addr = expr_result;
  }else{
    printf("Invalid expression!\n");
    return 0;
  }

  for (int i = 0; i < n; i++) {
    printf("0x%08x: ", addr);
    printf("0x%08x", paddr_read(addr));
    printf("\n");
    addr += 4;
  }

  return 0;
}

// static int cmd_p(char *args) {
//   if (args == NULL) {
//     printf("No expression given!\n");
//     return 0;
//   }

//   bool success = true;
//   uint32_t result = expr(args, &success);
//   if (success) {
//     printf("%u "FMT_WORD"\n", result, result);
//   } else {
//     printf("Invalid expression!\n");
//   }

//   return 0;
// }

// static int cmd_w(char *args) {
//   if(args == NULL){
//     printf("No expression given!\n");
//     return 0;
//   }
//   char *e = strtok(NULL, " ");
//   bool success;
//   uint32_t result = expr(e, &success);
//   if(success){
//     create_wp(e, result);
//   }else{
//     printf("Invalid expression!\n");
//   }

//   return 0;
// }

// static int cmd_d(char *args){
//   if(args == NULL){
//     printf("No watchpoint number given!\n");
//     return 0;
//   }
  
//   char *endptr;
//   uint64_t n = strtoul(args, &endptr, 10);

//   if(*endptr != '\0'){
//     printf("Invalid input N parameter!\n");
//     return 0;
//   }

//   delete_wp(n);

//   return 0;
// }

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  // init_wp_pool();
}
