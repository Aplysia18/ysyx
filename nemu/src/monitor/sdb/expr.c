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
#include <memory/vaddr.h>
#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ, TK_NEQ, TK_AND,

  /* TODO: Add more token types */
  TK_HEX, TK_DEC, TK_REG, TK_DEREF,
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus
  {"-", '-'},           // sub
  {"\\*", '*'},         // mul
  {"/", '/'},           // div
  {"==", TK_EQ},        // equal
  {"!=", TK_NEQ},       // not equal
  {"&&", TK_AND},       // and
  {"\\(", '('},
  {"\\)", ')'},
  {"0x[0-9a-fA-F]+", TK_HEX},
  {"[0-9]+", TK_DEC},
  {"\\$[a-zA-Z0-9]+", TK_REG},
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[65535] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
        //     i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
          case '+': 
          case '-': 
          case '*': 
          case '/':
          case '(':
          case ')':
          case TK_EQ:
          case TK_NEQ:
          case TK_AND:
            tokens[nr_token].type = rules[i].token_type;
            nr_token ++;
            break;
          case TK_NOTYPE:
            break;
          case TK_HEX:
            tokens[nr_token].type = TK_HEX;
            if(substr_len-2>=sizeof(tokens[nr_token].str)){
              strncpy(tokens[nr_token].str, substr_start+2, sizeof(tokens[nr_token].str)-1);
              tokens[nr_token].str[sizeof(tokens[nr_token].str)-1] = '\0';
              printf("Warning: Token truncated: %s\n", tokens[nr_token].str);
            }else{
              strncpy(tokens[nr_token].str, substr_start+2, substr_len-2);
              tokens[nr_token].str[substr_len-2] = '\0';
            }
            nr_token ++;
            break;
          case TK_DEC:
            tokens[nr_token].type = TK_DEC;
            if(substr_len>=sizeof(tokens[nr_token].str)){
              strncpy(tokens[nr_token].str, substr_start, sizeof(tokens[nr_token].str)-1);
              tokens[nr_token].str[sizeof(tokens[nr_token].str)-1] = '\0';
              printf("Warning: Token truncated: %s\n", tokens[nr_token].str);
            }else{
              strncpy(tokens[nr_token].str, substr_start, substr_len);
              tokens[nr_token].str[substr_len] = '\0';
            }
            nr_token ++;
            break;
          case TK_REG:
            tokens[nr_token].type = TK_REG;
            if(substr_len-1>=sizeof(tokens[nr_token].str)){
              strncpy(tokens[nr_token].str, substr_start+1, sizeof(tokens[nr_token].str)-1);
              tokens[nr_token].str[sizeof(tokens[nr_token].str)-1] = '\0';
              printf("Warning: Token truncated: %s\n", tokens[nr_token].str);
            }else{
              strncpy(tokens[nr_token].str, substr_start+1, substr_len-1);
              tokens[nr_token].str[substr_len-1] = '\0';
            }
            nr_token ++;
            break;
          default: 
            break;
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  for(i = 0; i < nr_token; i++){
    if(tokens[i].type == '*' && (i == 0 || (tokens[i-1].type != TK_DEC && tokens[i-1].type != TK_HEX && tokens[i-1].type != TK_REG && tokens[i-1].type != ')'))){
      tokens[i].type = TK_DEREF;
    }
  }

  return true;
}

bool check_parentheses(int begin, int end, bool *success) {
  int diff = 0;
  int i;
  if(tokens[begin].type == '(' && tokens[end].type == ')') {
    for(i = begin; i<=end; i++){
      if(tokens[i].type == '(') diff ++;
      else if(tokens[i].type == ')') diff --;
      if(diff == 0) break;
    }
    if(i < end) {
      return false;
    }else if(diff == 0){
      return true;
    }
    else {
      printf("Error: Parentheses Mismatch!\n");
      *success = false;
      return false;
    }
  } else {
    return false;
  }
}

uint32_t eval(int begin, int end, bool *success) {

  uint32_t result = 0;
  int i;

  if(*success == false) return 0;

  if(end < begin){
    printf("Error: Wrong Expression!\n");
    *success = false;

  }else if (begin == end){
    if(tokens[begin].type == TK_DEC){
      for(i=0; i<strlen(tokens[begin].str); i++){
        result *= 10;
        result += tokens[begin].str[i] - '0';
      }
    }else if(tokens[begin].type == TK_HEX){
      for(i=0; i<strlen(tokens[begin].str); i++){
        result *= 16;
        if(tokens[begin].str[i]>='0'&&tokens[begin].str[i]<='9'){
          result += tokens[begin].str[i] - '0';
        }else if(tokens[begin].str[i]>='a'&&tokens[begin].str[i]<='f'){
          result += tokens[begin].str[i] - 'a' + 10;
        }else if(tokens[begin].str[i]>='A'&&tokens[begin].str[i]<='F'){
          result += tokens[begin].str[i] - 'A' + 10;
        }
      }
    }else if(tokens[begin].type == TK_REG){
      result = isa_reg_str2val(tokens[begin].str, success);
    }else{
      printf("Error: Wrong Expression!\n");
      *success = false;
    }

  }else if(check_parentheses(begin, end, success) == true){
    result = eval(begin + 1, end - 1, success);

  }else{
    int op = begin; // main operator position
    int parentheses = 0;
    int priority = 0;
    for(i = begin; i <= end ; i++ ) {
      // printf("%d type: %d\n", i, tokens[i].type);
      if(tokens[i].type == '(') {
        parentheses += 1;
      } else if(tokens[i].type == ')') {
        parentheses -= 1;
        if( parentheses < 0 ) {
          printf("Error: Parentheses Mismatch!\n");
          *success = false;
          break;
        }
      } else if(parentheses == 0){  // not in parentheses
        switch(tokens[i].type){
          case TK_DEC:
          case TK_HEX:
          case TK_REG:
            continue;
          case '+':
          case '-':
            if(priority <= 4){
              priority = 4;
              op = i;
            }
            break;
          case '*':
          case '/':
            if(priority <= 3){
              priority = 3;
              op = i;
            }
            break;
          case TK_EQ:
          case TK_NEQ:
            if(priority <= 7){
              priority = 7;
              op = i;
            }
            break;
          case TK_AND:
            if(priority <= 11){
              priority = 11;
              op = i;
            }
            break;
          case TK_DEREF:
            if(priority <= 2){
              priority = 2;
              op = i;
            }
            break;
          default:
            assert(0);
        }
      }
    }
    uint32_t val1, val2;

    switch (tokens[op].type){
      case '+': 
        val1 = eval(begin, op-1, success);
        val2 = eval(op + 1, end, success);
        result = val1 + val2; 
        break;
      case '-': 
        val1 = eval(begin, op-1, success);
        val2 = eval(op + 1, end, success);
        result = val1 - val2; 
        break;
      case '*': 
        val1 = eval(begin, op-1, success);
        val2 = eval(op + 1, end, success);
        result = val1 * val2; break;
      case '/':
        val1 = eval(begin, op-1, success);
        val2 = eval(op + 1, end, success);
        if(val2 == 0) {
          printf("Error: Divided By Zero!\n");
          *success = false;
        }else{
          result = val1 / val2;
        }
        break;
      case TK_EQ: 
        val1 = eval(begin, op-1, success);
        val2 = eval(op + 1, end, success);
        result = val1 == val2; 
        break;
      case TK_NEQ: 
        val1 = eval(begin, op-1, success);
        val2 = eval(op + 1, end, success);
        result = val1 != val2; 
        break;
      case TK_AND: 
        val1 = eval(begin, op-1, success);
        if(val1==0){
          result = 0;
          break;
        }
        val2 = eval(op + 1, end, success);
        result = val1 && val2; 
        break;
      case TK_DEREF:
        val1 = eval(op + 1, end, success);
        result = vaddr_read(val1, 4);
        break;
      default: assert(0);
    }
  }

  return result;
}


word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  *success = true;
  uint32_t result = eval(0, nr_token-1, success);

  return result;
}
