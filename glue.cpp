
#include <emscripten.h>
#include <reader.h>

extern "C" {

// Not using size_t for array indices as the values used by the javascript code are signed.
void array_bounds_check(const int array_size, const int array_idx) {
  if (array_idx < 0 || array_idx >= array_size) {
    EM_ASM({
      throw 'Array index ' + $0 + ' out of bounds: [0,' + $1 + ')';
    }, array_idx, array_size);
  }
}

// Entry

kiwix::Entry* EMSCRIPTEN_KEEPALIVE emscripten_bind_Entry_Entry_0() {
  return new kiwix::Entry();
}

void EMSCRIPTEN_KEEPALIVE emscripten_bind_Entry___destroy___0(kiwix::Entry* self) {
  delete self;
}

// VoidPtr

void EMSCRIPTEN_KEEPALIVE emscripten_bind_VoidPtr___destroy___0(void** self) {
  delete self;
}

// Reader

kiwix::Reader* EMSCRIPTEN_KEEPALIVE emscripten_bind_Reader_Reader_0() {
  return new kiwix::Reader();
}

int EMSCRIPTEN_KEEPALIVE emscripten_bind_Reader_getArticleCount_0(kiwix::Reader* self) {
  return self->getArticleCount();
}

kiwix::Entry* EMSCRIPTEN_KEEPALIVE emscripten_bind_Reader_getEntryFromPath_1(kiwix::Reader* self, char* arg0) {
  return self->getEntryFromPath(arg0);
}

void EMSCRIPTEN_KEEPALIVE emscripten_bind_Reader___destroy___0(kiwix::Reader* self) {
  delete self;
}

}

