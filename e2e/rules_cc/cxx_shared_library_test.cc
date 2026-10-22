#include <cstdio>
#include <cstring>
#include <stdexcept>

#include "cxx_shared_library.h"

struct Square : Shape {
  int sides() const override { return 4; }
};

int main() {
  Square square;
  Shape* shape = &square;
  if (make_and_count() != 1 || Shape::created != 1 || shape->sides() != 4 ||
      kPrimes[2] != 5) {
    std::fprintf(stderr, "unexpected values\n");
    return 1;
  }
  try {
    throw_out_of_range();
  } catch (const std::out_of_range& e) {
    return std::strcmp(e.what(), "from shared library") == 0 ? 0 : 1;
  }
  std::fprintf(stderr, "exception not caught\n");
  return 1;
}
