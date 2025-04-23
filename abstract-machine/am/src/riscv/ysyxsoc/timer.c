#include <am.h>
#include <riscv/riscv.h>

uint64_t frequency = 0;

void __am_timer_init() {
  
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = inl(0x02000000+4);
  uptime->us <<= 32;
  uptime->us += inl(0x02000000);
  uptime->us *= 5;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
