
#include <emscripten.h>

extern "C" {

// Not using size_t for array indices as the values used by the javascript code are signed.
void array_bounds_check(const int array_size, const int array_idx) {
  if (array_idx < 0 || array_idx >= array_size) {
    EM_ASM({
      throw 'Array index ' + $0 + ' out of bounds: [0,' + $1 + ')';
    }, array_idx, array_size);
  }
}

// VoidPtr

void EMSCRIPTEN_KEEPALIVE emscripten_bind_VoidPtr___destroy___0(void** self) {
  delete self;
}

// File

File* EMSCRIPTEN_KEEPALIVE emscripten_bind_File_File_1(ByteString arg0) {
  return new File(arg0);
}

ByteString EMSCRIPTEN_KEEPALIVE emscripten_bind_File_getArticleByUrl_1(File* self, ByteString arg0) {
  return self->getArticleByUrl(arg0);
}

void EMSCRIPTEN_KEEPALIVE emscripten_bind_File___destroy___0(File* self) {
  delete self;
}

}

