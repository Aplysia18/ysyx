#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

// 辅助函数，用于格式化输出
static int vsnprintf_helper(void (*output_func)(char, void*, int), void *output_arg, const char *fmt, va_list args) {
  int i, j = 0;
  int num, len, num2;
  char num3[16];
  bool conver = false;
  bool zero_flag = false;
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
            num = va_arg(args, int);
            if (num < 0) {
              output_func('-', output_arg, j);
              j++;
              num = -num;
              width--;
            } 
            len = 0;
            num2 = num;
            while (num2) {
              num2 /= 10;
              len++;
            }
            if(num==0) len=1;
            if(zero_flag) {
              for(int k = len; k < width; k++) {
                output_func('0', output_arg, j);
                j++;
              }
            }
            for (int k = len - 1; k >= 0; k--) {
              if(k>=16) assert(0);
              num3[k] = num % 10 + '0';
              num /= 10;
            }
            for (int k = 0; k < len; k++) {
              output_func(num3[k], output_arg, j);
              j++;
            }
            width = 0;
            zero_flag = false;
            break;
          case 'x':
            conver = false;
            num = va_arg(args, uint64_t);
            len = 0;
            num2 = num;
            while (num2) {
              num2 /= 16;
              len++;
            }
            if(num==0) len=1;
            if(zero_flag) {
              for(int k = len; k < width; k++) {
                output_func('0', output_arg, j);
                j++;
              }
            }
            for (int k = len - 1; k >= 0; k--) {
              if(k>=16) assert(0);
              num3[k] = ((num % 16) < 10) ? num % 16 + '0' : num % 16 - 10 + 'a';
              num /= 16;
            }
            for (int k = 0; k < len; k++) {
              output_func(num3[k], output_arg, j);
              j++;
            }
            width = 0;
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
