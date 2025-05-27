#include <am.h>
#include <riscv/riscv.h>

#define FB_ADDR 0x21000000

void __am_gpu_init() {

}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
*cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = 640, .height = 480,
    .vmemsz = 0
};
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
uint32_t screen_w = 640;
uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
uint32_t *pixels_32 = ctl->pixels;
for(int i=0; i<ctl->h; i++) {
    for(int j=0; j<ctl->w; j++) {
        fb[(ctl->y + i) * screen_w + ctl->x + j] = pixels_32[i * ctl->w + j];
    }
}
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
    status->ready = true;
}
