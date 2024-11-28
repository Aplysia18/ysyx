#ifndef __CPU_IRINGBUF_H__

#include <common.h>

typedef struct RingbufNode {
    char info[128];
    struct RingbufNode *next;
} RingbufNode;

typedef struct {
    int max; // buffer size
    int length; // number of elements in buffer
    RingbufNode *head; // head of buffer
    RingbufNode *tail; // tail of buffer
} Ringbuf;

extern Ringbuf ringbuf;

void init_ringbuf();
void ringbuf_add(vaddr_t pc, vaddr_t snpc, uint32_t inst);
void ringbuf_print();

#endif