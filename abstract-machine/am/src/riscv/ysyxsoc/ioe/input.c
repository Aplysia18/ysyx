#include <am.h>
#include <riscv/riscv.h>
#include <stdio.h>

#define KBD_ADDR 0x10011000

int __am_input_keybrd_decode(bool e0, uint8_t k);

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint8_t k = inb(KBD_ADDR);
  printf("k = %x\n", k);
  if(k==0) {
    kbd->keydown = false;
    kbd->keycode = AM_KEY_NONE;
    return;
  }
  if(k == 0xe0) {
    printf("e0\n");
    uint8_t k2 = inb(KBD_ADDR);
    if(k2 == 0xf0){
        printf("e0f0\n");
        kbd->keydown = false;
        uint8_t k3 = inb(KBD_ADDR);
        kbd->keycode = __am_input_keybrd_decode(true, k3);
    } else {
        kbd->keydown = true;
        kbd->keycode = __am_input_keybrd_decode(true, k2);
    }
  } else if(k == 0xf0) {
    printf("f0\n");
    uint8_t k2 = inb(KBD_ADDR);
    kbd->keydown = false;
    kbd->keycode = __am_input_keybrd_decode(false, k2);
  } else {
    printf("normal\n");
    kbd->keydown = true;
    kbd->keycode = __am_input_keybrd_decode(false, k);
  }
  return;
}

int __am_input_keybrd_decode(bool e0, uint8_t k) {
    if(e0){
        switch(k) {
            case 0x2F: return AM_KEY_APPLICATION;
            case 0x11: return AM_KEY_RALT;
            case 0x14: return AM_KEY_RCTRL;
            case 0x75: return AM_KEY_UP;
            case 0x72: return AM_KEY_DOWN;
            case 0x6B: return AM_KEY_LEFT;
            case 0x74: return AM_KEY_RIGHT;
            case 0x70: return AM_KEY_INSERT;
            case 0x71: return AM_KEY_DELETE;
            case 0x6C: return AM_KEY_HOME;
            case 0x69: return AM_KEY_END;
            case 0x7D: return AM_KEY_PAGEUP;
            case 0x7A: return AM_KEY_PAGEDOWN;
            default: return AM_KEY_NONE;
        }
    } else {
        switch(k) {
            case 0x76: return AM_KEY_ESCAPE;
            case 0x05: return AM_KEY_F1;
            case 0x06: return AM_KEY_F2;
            case 0x04: return AM_KEY_F3;
            case 0x0C: return AM_KEY_F4;
            case 0x03: return AM_KEY_F5;
            case 0x0B: return AM_KEY_F6;
            case 0x83: return AM_KEY_F7;
            case 0x0A: return AM_KEY_F8;
            case 0x01: return AM_KEY_F9;
            case 0x09: return AM_KEY_F10;
            case 0x78: return AM_KEY_F11;
            case 0x07: return AM_KEY_F12;
            case 0x0E: return AM_KEY_GRAVE;
            case 0x16: return AM_KEY_1;
            case 0x1E: return AM_KEY_2;
            case 0x26: return AM_KEY_3;
            case 0x25: return AM_KEY_4;
            case 0x2E: return AM_KEY_5;
            case 0x36: return AM_KEY_6;
            case 0x3D: return AM_KEY_7;
            case 0x3E: return AM_KEY_8;
            case 0x46: return AM_KEY_9;
            case 0x45: return AM_KEY_0;
            case 0x4E: return AM_KEY_MINUS;
            case 0x55: return AM_KEY_EQUALS;
            case 0x66: return AM_KEY_BACKSPACE;
            case 0x0D: return AM_KEY_TAB;
            case 0x15: return AM_KEY_Q;
            case 0x1D: return AM_KEY_W;
            case 0x24: return AM_KEY_E;
            case 0x2D: return AM_KEY_R;
            case 0x2C: return AM_KEY_T;
            case 0x35: return AM_KEY_Y;
            case 0x3C: return AM_KEY_U;
            case 0x43: return AM_KEY_I;
            case 0x44: return AM_KEY_O;
            case 0x4D: return AM_KEY_P;
            case 0x54: return AM_KEY_LEFTBRACKET;
            case 0x5B: return AM_KEY_RIGHTBRACKET;
            case 0x5D: return AM_KEY_BACKSLASH;
            case 0x58: return AM_KEY_CAPSLOCK;
            case 0x1C: return AM_KEY_A;
            case 0x1B: return AM_KEY_S;
            case 0x23: return AM_KEY_D;
            case 0x2B: return AM_KEY_F;
            case 0x34: return AM_KEY_G;
            case 0x33: return AM_KEY_H;
            case 0x3B: return AM_KEY_J;
            case 0x42: return AM_KEY_K;
            case 0x4B: return AM_KEY_L;
            case 0x4C: return AM_KEY_SEMICOLON;
            case 0x52: return AM_KEY_APOSTROPHE;
            case 0x5A: return AM_KEY_RETURN;
            case 0x12: return AM_KEY_LSHIFT;
            case 0x1A: return AM_KEY_Z;
            case 0x22: return AM_KEY_X;
            case 0x21: return AM_KEY_C;
            case 0x2A: return AM_KEY_V;
            case 0x32: return AM_KEY_B;
            case 0x31: return AM_KEY_N;
            case 0x3A: return AM_KEY_M;
            case 0x41: return AM_KEY_COMMA;
            case 0x49: return AM_KEY_PERIOD;
            case 0x4A: return AM_KEY_SLASH;
            case 0x59: return AM_KEY_RSHIFT;
            case 0x14: return AM_KEY_LCTRL;
            case 0x11: return AM_KEY_LALT;
            case 0x29: return AM_KEY_SPACE;
            default: return AM_KEY_NONE;
        }
    }
    return AM_KEY_NONE;
}