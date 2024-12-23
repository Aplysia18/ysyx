#include <monitor/monitor.hpp>
#include <monitor/sdb.hpp>
#include <cpu/cpu.hpp>

int main(int argc, char** argv) {

  init_monitor(argc, argv);

  sdb_mainloop();

  exit_cpu();

  return 0;
}
