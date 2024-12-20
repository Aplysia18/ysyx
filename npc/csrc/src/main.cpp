#include <cpu/cpu.hpp>
#include <monitor/monitor.hpp>
#include <monitor/sdb.hpp>


int main(int argc, char** argv) {

  init_cpu(argc, argv);

  init_monitor(argc, argv);

  sdb_mainloop();

  exit_cpu();

  return 0;
}
