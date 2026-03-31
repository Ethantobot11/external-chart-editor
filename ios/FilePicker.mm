#include <hx/CFFI.h>

extern "C" void hx_onFilePicked(const char* path);

void hx_onFilePicked(const char* path) {
    value func = val_field(val_id("FilePickerCallback"), val_id("onFilePicked"));
    if (val_is_function(func)) {
        val_call1(func, alloc_string(path));
    }
}
