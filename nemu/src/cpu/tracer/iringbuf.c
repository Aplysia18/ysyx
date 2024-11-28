#include <string.h>
#include <cpu/iringbuf.h>

Ringbuf ringbuf;

void init_ringbuf() {
    ringbuf.max = 20;
    ringbuf.length = 0;
    ringbuf.head = NULL;
    ringbuf.tail = NULL;
}

void ringbuf_add(vaddr_t pc, vaddr_t snpc, uint32_t inst) {
    if (ringbuf.length == ringbuf.max) {
        RingbufNode *temp = ringbuf.head;
        ringbuf.head = ringbuf.head->next;
        free(temp);
        ringbuf.length--;
    }
    RingbufNode *new_node = (RingbufNode *)malloc(sizeof(RingbufNode));
    new_node->next = NULL;
    if (ringbuf.length == 0) {
        ringbuf.head = new_node;
        ringbuf.tail = new_node;
    } else {
        ringbuf.tail->next = new_node;
        ringbuf.tail = new_node;
    }
    ringbuf.length++;

    char *p = new_node->info;
    p += sprintf(p, FMT_WORD ":", pc);
    int ilen = snpc - pc;
    int i;
    uint8_t *inst_t = (uint8_t *) &inst;
    for (i = ilen - 1; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", inst_t[i]);
    }
    int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
    int space_len = ilen_max - ilen;
    if (space_len < 0) space_len = 0;
    space_len = space_len * 3 + 1;
    memset(p, ' ', space_len);
    p += space_len;

#ifndef CONFIG_ISA_loongarch32r
    void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
    disassemble(p, new_node->info + sizeof(new_node->info) - p,
        MUXDEF(CONFIG_ISA_x86, snpc, pc), (uint8_t *)&inst, ilen);
#endif
}

void print_ringbuf() {
    RingbufNode *temp = ringbuf.head;
    while (temp != NULL) {
        printf("%s\n", temp->info);
        temp = temp->next;
    }
}