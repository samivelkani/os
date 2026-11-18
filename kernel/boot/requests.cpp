#include "../../shared/types.hpp"
#include "./requests.hpp"

namespace {
  __attribute__((used, section(".limine_requests_start")))
  volatile u64 start_marker[] = LIMINE_REQUESTS_START_MARKER;

  __attribute__((used, section(".limine_requests")))
  volatile u64 base_revision[] = LIMINE_BASE_REVISION(6);

  __attribute__((used, section(".limine_requests")))
  volatile limine_framebuffer_request framebuffer_request = {
    .id = LIMINE_FRAMEBUFFER_REQUEST_ID,
    .revision = 0,
    .response = nullptr
  };

  __attribute__((used, section(".limine_requests_end")))
  volatile u64 end_marker[] = LIMINE_REQUESTS_END_MARKER;
}

bool validate_base_revision() {
  return LIMINE_BASE_REVISION_SUPPORTED(base_revision);
}

struct limine_framebuffer* get_framebuffer() {
  if(framebuffer_request.response == nullptr) return nullptr;
  if(framebuffer_request.response->framebuffer_count == 0) return nullptr;
  return framebuffer_request.response->framebuffers[0];
}