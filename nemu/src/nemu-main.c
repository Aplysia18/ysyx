/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <common.h>
#include "monitor/sdb/sdb.h"

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif

  /* Start engine. */
  engine_start();

//   return is_exit_status_bad();

  /*---test expr---*/

  // FILE *fp = fopen("/home/lty/ysyx/ysyx-workbench/nemu/tools/gen-expr/input", "r");
  // assert(fp != NULL);
  
  // char *line = NULL;
  // size_t len = 0;

  // bool success;
  // uint32_t real_result, eval_result;

  // int i = 0;
  // char *real_result_str; 
  // char *expression;

  // while(getline(&line, &len, fp) != -1){
  //   i++;

  //   /* extract the first token as the result */
  //   real_result_str = strtok(line, " ");
  //   if (real_result_str == NULL) { 
  //     printf("%d: \n",i);
  //     printf("Wrong Input!\n");
  //     continue; 
  //   }
  //   real_result = 0;
  //   for(int j=0; j<strlen(real_result_str); j++){
  //     real_result *= 10;
  //     real_result += real_result_str[j] - '0';
  //   }

  //   /* treat the remaining string as the expression */
  //   expression = line + strlen(real_result_str) + 1;
  //   expression = strtok(expression, "\n");
    
  //   eval_result = expr(expression, &success);
  //   if(success == false){
  //     printf("%d: \n",i);
  //     printf("Fail!\n");
  //     continue;
  //   }

  //   if(real_result != eval_result) {
  //     printf("%d: \n",i);
  //     printf("Not Equal! real_result = %u, eval_result = %u.\n", real_result, eval_result);
  //   }else{
  //     // printf("Equal! result = %u.\n", eval_result);
  //   }
    
  // }

  // free(line);
  // fclose(fp);
}
