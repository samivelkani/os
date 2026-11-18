#ifndef CPU_HPP
#define CPU_HPP

[[noreturn]] inline void halt_forever() {
  while(1) {
    __asm__ volatile("cli; hlt");
  }
}

#endif