#include "../shared/types.hpp"
#include "./arch/x86_64/cpu.hpp"
#include "./boot/requests.hpp"

extern "C" void kmain() {
  if(!validate_base_revision()) halt_forever();

  struct limine_framebuffer* fb = get_framebuffer();
  if(fb == nullptr || fb->bpp != 32) halt_forever();
  u8* row = static_cast<u8*>(fb->address);

  for(u64 y = 0; y < fb->height; y += 1) {
    u32* dots = reinterpret_cast<u32*>(row);
    for(u64 x = 0; x < fb->width; x += 1) {
      dots[x] = 0x00ffffff;
    }
    row += fb->pitch;
  }

  halt_forever();
}