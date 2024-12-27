#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int i, j = 0;
  bool conver = false;
  for(i=0; fmt[i]!='\0'; i++) {
    if(conver){
      switch(fmt[i]){
        case 's':
          conver = false;
          char *str = va_arg(args, char*);
          while(*str){
            putch(*str++);
          }
          break;
        case 'd':
          conver = false;
          int num = va_arg(args, int);
          if(num < 0){
            putch('-');
            num = -num;
          }else if(num == 0){
            putch('0');
            break;
          }
          int len = 0;
          int num2 = num;
          while(num2){
            num2 /= 10;
            len++;
          }
          char num3[11];
          for(int k = len-1; k >= 0; k--){
            num3[k] = num % 10 + '0';
            num /= 10;
          }
          for(int k = 0; k < len; k++){
            putch(num3[k]);
          }
          break;
        case '%':
          conver = false;
          putch('%');
          break;
        default:
          assert(0);
      }
    }else if(fmt[i] == '%'){
      conver = true;
    }else{
      putch(fmt[i]);
    }
  }
  va_end(args);
  return j;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int i, j = 0;
  bool conver = false;
  for(i=0; fmt[i]!='\0'; i++) {
    if(conver){
      switch(fmt[i]){
        case 's':
          conver = false;
          char *str = va_arg(args, char*);
          while(*str){
            out[j++] = *str++;
          }
          break;
        case 'd':
          conver = false;
          int num = va_arg(args, int);
          if(num < 0){
            out[j++] = '-';
            num = -num;
          }else if(num == 0){
            out[j++] = '0';
            break;
          }
          int len = 0;
          int num2 = num;
          while(num2){
            num2 /= 10;
            len++;
          }
          char num3[11];
          for(int k = len-1; k >= 0; k--){
            num3[k] = num % 10 + '0';
            num /= 10;
          }
          for(int k = 0; k < len; k++){
            out[j++] = num3[k];
          }
          break;
        case '%':
          conver = false;
          out[j++] = '%';
          break;
        default:
          assert(0);
      }
    }else if(fmt[i] == '%'){
      conver = true;
    }else{
      out[j++] = fmt[i];
    }
  }
  va_end(args);
  out[j] = '\0';
  return j;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
