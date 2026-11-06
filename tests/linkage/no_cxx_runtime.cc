#if __has_include(<vector>)
#error "Should not see any C++ runtime headers"
#endif

// The headers of the libc stay available.
#include <stdio.h>

int main() {
  printf("ok\n");
  return 0;
}
