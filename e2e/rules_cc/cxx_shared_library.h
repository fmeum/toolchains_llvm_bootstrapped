#ifndef CXX_SHARED_LIBRARY_H_
#define CXX_SHARED_LIBRARY_H_

#include <stdexcept>

struct Shape {
  virtual ~Shape();
  virtual int sides() const;
  static int created;
};

extern const int kPrimes[3];

int make_and_count();

// Throws a standard exception across the shared library boundary.
void throw_out_of_range();

#endif  // CXX_SHARED_LIBRARY_H_
