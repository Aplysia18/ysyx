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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char out[65536] = {};
static char buf[131072] = {};
static char code_buf[131072 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

uint32_t choose(uint32_t n) {
  if(n==0) return 0;
  return rand()%n;
}

int gen_num(int maxlen, int* start, int* start_u) {

  int len;
  if(maxlen<=10){
    len = choose(maxlen) + 1;
  }else{
    len = choose(10) + 1;
  }
   
  int i = 0;
  if(len==10){
    buf[*start_u] = '0' + choose(3) + 1;
    out[*start] = buf[*start_u];
  }else{
    buf[*start_u] = '0' + choose(9) + 1;
    out[*start] = buf[*start_u];
  }
  *start += 1;
  *start_u += 1;
  
  for(i = 1; i < len; i++) {
    buf[*start_u] = '0' + choose(10);
    out[*start] = buf[*start_u];
    *start += 1;
    *start_u += 1;
  }
  buf[*start_u] = 'u';
  *start_u += 1;
  return len;
}

int gen_num_hex(int maxlen, int* start, int* start_u) {

  int len;
  if(maxlen<=10){
    len = choose(maxlen-2) + 1;
  }else{
    len = choose(8) + 1;
  }

  buf[*start_u] = '0';
  *start_u += 1;
  out[*start] = '0';
  *start += 1;
  buf[*start_u] = 'x';
  *start_u += 1;
  out[*start] = 'x';
  *start += 1;
   
  for(int i = 0; i < len; i++) {
    if(choose(16)<10){
      buf[*start_u] = '0' + choose(10);
      out[*start] = buf[*start_u];
      *start += 1;
      *start_u += 1;
    }else{
      buf[*start_u] = 'a' + choose(6);
      out[*start] = buf[*start_u];
      *start += 1;
      *start_u += 1;
    }
    
  }
  buf[*start_u] = 'u';
  *start_u += 1;
  return len+2;
}

char gen_rand_op() {
  switch(choose(4)){
    case 0: return '+';
    case 1: return '-';
    case 2: return '*';
    default: return '/';
  }
}

static int gen_rand_expr(int maxlen, int* start, int* start_u) {
  int len = 0, len1, len2, i = 0;

  if(maxlen<3) return gen_num(maxlen, start, start_u);

  switch(choose(3)){
    case 0: 
      for(i=0; i<maxlen-1; i++){  // 随机在数字前插入空格
        if(choose(2)){
          buf[*start_u] = ' ';
          *start_u += 1;
          out[*start] = ' ';
          *start += 1;
          len += 1;
        }else{
          break;
        }
      }
      switch(choose(2)){
        case 0: 
          len += gen_num(maxlen-len, start, start_u);
          break;
        default: 
          if(maxlen-len>=3){
            len += gen_num_hex(maxlen-len, start, start_u);
          }else{
            len += gen_num(maxlen-len, start, start_u);
          }
          break;
      }
      
      for(i=0; i<maxlen-len; i++){  // 随机在数字后插入空格
        if(choose(2)){
          buf[*start_u] = ' ';
          *start_u += 1;
          out[*start] = ' ';
          *start += 1;
          len += 1;
        }else{
          break;
        }
      }
      break;
    case 1: 
      buf[*start_u] = '('; 
      *start_u += 1;
      out[*start] = '(';
      *start += 1;
      len = gen_rand_expr(maxlen - 2, start, start_u); 
      buf[*start_u] = ')';
      *start_u += 1;
      out[*start] = ')';
      *start += 1;
      len += 2;
      break;
    default: 
      len1 = gen_rand_expr(maxlen-2, start, start_u);
      buf[*start_u] = gen_rand_op();
      out[*start] = buf[*start_u];
      *start_u += 1;
      *start += 1;
      len2 = gen_rand_expr(maxlen-len1-1, start, start_u);
      len = len1 + 1 + len2;
      
  }
  return len;
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  // int len;
  int start = 0;
  int start_u = 0;
  for (i = 0; i < loop; i ++) {
    start = start_u = 0;
    
    gen_rand_expr(65535, &start, &start_u);
    buf[start_u] = '\0';
    out[start] = '\0';
    // printf("iteration %d: length of expression is %d\n", i, len);

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc -Wall -Werror -Wno-error=overflow -Wno-overflow /tmp/.code.c -o /tmp/.expr"); // 将警告视为错误，发生divide by 0时返回非0值
    if (ret != 0) {
      i --;
      continue;
    }

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);
    // printf("%u %s\n", result, buf);
    printf("%u %s\n", result, out);
  }
  return 0;
}
