#include <iostream>
#include <stdexcept>

#include "lib.h"

int main() {
  try {
    throw std::runtime_error("ok");
  } catch (const std::exception& e) {
    std::cout << e.what() << lib() << std::endl;
  }
  return 0;
}
