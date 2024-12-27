#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t len = 0;
  while(s[len] != '\0'){
    len++;
  }
  return len;
}

char *strcpy(char *dst, const char *src) {
  size_t i;
  for(i=0; src[i]!='\0'; i++){
    dst[i] = src[i];
  }
  dst[i] = '\0';
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  panic("Not implemented");
}

char *strcat(char *dst, const char *src) {
  size_t dst_len = strlen(dst);
  size_t i;
  for(i=0; src[i]!='\0'; i++){
    dst[dst_len+i] = src[i];
  }
  dst[dst_len+i] = '\0';
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  size_t i;
  for(i=0; s1[i]!='\0' || s2[i]!='\0'; i++){
    if(s1[i] != s2[i]){
      return s1[i] - s2[i];
    }
  }
  return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  panic("Not implemented");
}

void *memset(void *s, int c, size_t n) {
  size_t i;
  char *xs = s;
  for(i=0; i<n; i++){
    xs[i] = c;
  }
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  panic("Not implemented");
}

void *memcpy(void *out, const void *in, size_t n) {
  panic("Not implemented");
}

int memcmp(const void *s1, const void *s2, size_t n) {
  size_t i;
  char *xs1 = (char *)s1;
  char *xs2 = (char *)s2;
  for(i=0; i<n; i++){
    if(xs1[i] != xs2[i]){
      return xs1[i] - xs2[i];
    }
  }
  return 0;
}

#endif
