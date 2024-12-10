#include <stdio.h>
#include <monitor/sdb.hpp>

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  uint32_t val;
  char e[65535];
  
} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */

WP *new_wp() {
  if (free_ == NULL) {
    printf("No enough watchpoints.\n");
    assert(0);
  }
  WP *wp = free_;
  free_ = free_->next;
  wp->next = head;
  head = wp;
  return wp;
}

void free_wp(WP *wp) {
  WP *p;
  if (head == wp) {
    head = head->next;
  } else {
    for (p = head; p != NULL; p = p->next) {
      if (p->next == wp) {
        p->next = wp->next;
        break;
      }
    }
  }
  wp->next = free_;
  free_ = wp;
}


void create_wp(char *e, uint32_t val) {
  WP *p = new_wp();
  p->val = val;
  strcpy(p->e , e);
  printf("Create watchpoint %d: %s. Value = %u\n", p->NO, p->e, p->val);
  return;
}

void print_wp() {
  if(head==NULL){
    printf("No watchpoints.\n");
    return;
  }
  
  printf("%-4s | %-12s | What\n", "NO", "Value");

  WP *p;
  for (p = head; p != NULL; p = p->next) {
    printf("%-4d | %-12u | %s\n", p->NO, p->val, p->e);
  }
}

void delete_wp(int n) {
  WP *p;
  for(p = head; p != NULL; p = p->next) {
    if(p->NO == n) {
      free_wp(p);
      printf("Watchpoint %d deleted.\n", n);
      return;
    }
  }
  printf("No watchpoint %d.\n", n);
  return;
}

void check_watchpoints() {
  WP *p;
  for (p = head; p != NULL; p = p->next) {
    bool success = true;
    uint32_t val = expr(p->e, &success);
    if (val != p->val) {
      printf("Watchpoint %d: %s\n", p->NO, p->e);
      printf("Old value = %u\n", p->val);
      printf("New value = %u\n", val);
      p->val = val;
    //   nemu_state.state = NEMU_STOP;
    }
  }
}