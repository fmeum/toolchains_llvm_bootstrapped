#define WIN32_LEAN_AND_MEAN
#include <windows.h>

extern "C" void _start() {
    const char message[] = "Hello from MinGW!\r\n";
    HANDLE stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD written = 0;
    if (stdout_handle) {
        WriteFile(stdout_handle, message, sizeof(message) - 1, &written, nullptr);
    }
    ExitProcess(0);
}
