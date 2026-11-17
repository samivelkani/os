/*
 * The main file of our kernel.
 * kmain() is the main function as bootstrap
 * It is called directly from the bootloader via limine
 * This file with the main function is the orchestrator and everything is called here
 * This function does not return at all - we should not get back to bootloader (with call and ret commands)
 */

#include "../shared/types.hpp"

extern "C" void kmain() {
  while(1) {
    __asm__("hlt");
  }
}