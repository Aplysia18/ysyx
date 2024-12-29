#include <am.h>
#include <nemu.h>
#include <stdio.h>

void __am_timer_init() {
  outl(RTC_ADDR, 0);
  outl(RTC_ADDR + 4, 0);
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  // uint32_t low = inl(RTC_ADDR);
  // printf("uptime before: %d\n", uptime->us);
  uptime->us = inl(RTC_ADDR+4);
  uptime->us <<= 32;
  uptime->us += inl(RTC_ADDR);
  // printf("uptime after: %d\n", uptime->us);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
