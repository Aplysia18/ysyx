#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

// 辅助函数：输出整数（包括正负数）
static void output_number(void (*output_func)(char, void*, int), void *output_arg, int *j, uint64_t num, int base, bool is_signed, bool zero_flag, int width) {
  char num3[22];
  int len = 0;
  uint64_t num2 = num;

  // 计算数字长度
  if (num == 0) {
    len = 1;
  } else {
    while (num2) {
      num2 /= base;
      len++;
    }
  }

  // 对负数进行处理
  if (is_signed && (int64_t)num < 0) {
    output_func('-', output_arg, (*j)++);
    num = (uint64_t)(-(int64_t)num); // 转为正数
    width--;
  }

  // 处理宽度
  if (zero_flag) {
    for (int k = len; k < width; k++) {
      output_func('0', output_arg, (*j)++);
    }
  }

  // 输出数字
  for (int k = len - 1; k >= 0; k--) {
    int digit = num % base;
    num3[k] = (digit < 10) ? digit + '0' : digit - 10 + 'a';
    num /= base;
  }
  for (int k = 0; k < len; k++) {
    output_func(num3[k], output_arg, (*j)++);
  }
}

// 辅助函数，用于格式化输出
static int vsnprintf_helper(void (*output_func)(char, void*, int), void *output_arg, const char *fmt, va_list args) {
  int i, j = 0;
  bool conver = false;
  bool zero_flag = false;
  bool l_flag = false;
  bool ll_flag = false;
  int width = 0;
  for (i = 0; fmt[i] != '\0'; i++) {
    if (conver) {
      if(fmt[i]>='0' && fmt[i]<='9') {
        if(fmt[i] == '0' && width == 0) {
          zero_flag = true;
        } else {
          width = width * 10 + fmt[i] - '0';
        }
      } else {
        switch (fmt[i]) {
          case 'l':
            if(l_flag) {
              ll_flag = true;
              l_flag = false;
            } else if(ll_flag) {
              assert(0);
            } else {
              l_flag = true;
            }
            break;
          case 's': 
            conver = false;
            char *str = va_arg(args, char*);
            while (*str) {
              output_func(*str++, output_arg, j);
              j++;
            }
            width = 0;  //TODO: width not implemented
            zero_flag = false;
            break;
          case 'c': 
            conver = false;
            char ch = va_arg(args, int);
            output_func(ch, output_arg, j);
            j++;
            width = 0;  //TODO: width not implemented
            zero_flag = false;
            break;
          case 'd': 
            conver = false;
            if(l_flag){
              output_number(output_func, output_arg, &j, va_arg(args, long), 10, true, zero_flag, width);
            }else if(ll_flag){
              output_number(output_func, output_arg, &j, va_arg(args, long long), 10, true, zero_flag, width);
            }else{
              output_number(output_func, output_arg, &j, va_arg(args, int), 10, true, zero_flag, width);
            }
            zero_flag = false;
            break;
          case 'u':
            conver = false;
            if(l_flag){
              output_number(output_func, output_arg, &j, va_arg(args, unsigned long), 10, false, zero_flag, width);
            }else if(ll_flag){
              output_number(output_func, output_arg, &j, va_arg(args, unsigned long long), 10, false, zero_flag, width);
            }else{
              output_number(output_func, output_arg, &j, va_arg(args, uint32_t), 10, false, zero_flag, width);
            }
            zero_flag = false;
            break;
          case 'x':
          case 'X':
            conver = false;
            if(l_flag){
              output_number(output_func, output_arg, &j, va_arg(args, unsigned long), 16, false, zero_flag, width);
            }else if(ll_flag){
              output_number(output_func, output_arg, &j, va_arg(args, unsigned long long), 16, false, zero_flag, width);
            }else{
              output_number(output_func, output_arg, &j, va_arg(args, uint32_t), 16, false, zero_flag, width);
            }
            zero_flag = false;
            break;
          case '%': 
            conver = false;
            output_func('%', output_arg, j);
            j++;
            width = 0;  //TODO: width not implemented
            zero_flag = false;
            break;
          default: {
            printf("Unhandled format specifier: %c\n", fmt[i]);
            assert(0);
          }
        }
      }
    } else if (fmt[i] == '%') {
      conver = true;
    } else {
      output_func(fmt[i], output_arg, j);
      j++;
    }
  }
  return j;
}

// 输出到控制台的函数
static void putch_wrapper(char ch, void *arg, int cnt) {
  putch(ch);
}

// 输出到字符串的函数
static void str_putch_wrapper(char ch, void *arg, int cnt) {
  char *str = (char *)arg;
  str[cnt] = ch;
}

int printf(const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int ret = vsnprintf_helper(putch_wrapper, NULL, fmt, args);
  va_end(args);
  return ret;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int ret = vsnprintf_helper(str_putch_wrapper, out, fmt, args);
  va_end(args);
  out[ret] = '\0';
  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
