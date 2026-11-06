// Runs directly on the Linux kernel, without a libc and its startup files.

#if __STDC_HOSTED__
#error "Should be compiled as freestanding"
#endif

#if __has_include(<stdio.h>)
#error "Should not see any libc headers"
#endif

// The Linux UAPI and the compiler's own headers don't depend on a libc.
#include <asm/unistd.h>
#include <stddef.h>
#include <stdint.h>

static long raw_syscall3(long number, long arg1, long arg2, long arg3) {
#if defined(__x86_64__)
  long result;
  __asm__ volatile("syscall"
                   : "=a"(result)
                   : "a"(number), "D"(arg1), "S"(arg2), "d"(arg3)
                   : "rcx", "r11", "memory");
  return result;
#elif defined(__aarch64__)
  register long x8 __asm__("x8") = number;
  register long x0 __asm__("x0") = arg1;
  register long x1 __asm__("x1") = arg2;
  register long x2 __asm__("x2") = arg3;
  __asm__ volatile("svc 0" : "+r"(x0) : "r"(x8), "r"(x1), "r"(x2) : "memory");
  return x0;
#else
#error "Unsupported CPU"
#endif
}

// Dividing 128-bit integers calls into compiler-rt.
static volatile unsigned __int128 dividend = (unsigned __int128)1 << 100;
static volatile unsigned __int128 divisor = (unsigned __int128)1 << 98;

// Without a libc, nothing determines the CPU features that outlined atomics depend on.
static int counter = 3;

__attribute__((used)) void freestanding_main(void) {
  static const char message[] = "ok\n";
  raw_syscall3(__NR_write, 1, (long)message, sizeof(message) - 1);
  int previous = __atomic_fetch_add(&counter, 1, __ATOMIC_SEQ_CST);
  raw_syscall3(__NR_exit, dividend / divisor == 4 && previous == 3 ? 0 : 1, 0, 0);
  __builtin_unreachable();
}

#if defined(__x86_64__)
__asm__(".globl _start\n_start:\n  xor %ebp, %ebp\n  and $-16, %rsp\n  call freestanding_main\n");
#elif defined(__aarch64__)
__asm__(".globl _start\n_start:\n  bl freestanding_main\n");
#endif
