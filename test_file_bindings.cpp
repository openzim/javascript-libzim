#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <iostream>
#include <emscripten/bind.h>
#include <emscripten/emscripten.h>

#define _1GB (1024*1024*1024LL)

int test_read_one_byte(int fd, uint64_t offset) {
  char out;
  ssize_t char_read;

  printf("Try to read at position %lli\n", offset);
  char_read = pread(fd, &out, 1, offset);
  if (char_read == -1) {
    perror("Cannot read\n");
    return -1;
  }
  if (char_read == 1) {
    printf("Byte at position %lli is 0x%x.\n", offset, out);
  } else {
    printf("Nothing to read at this position (file too small?)...\n");
  }

  return char_read;
}

int test_big_file(std::string filename) {
  int fd = open(filename.c_str(), O_RDONLY);
  if (fd == -1) {
    perror("Cannot open filename");
    return -1;
  }

  if (test_read_one_byte(fd, 0) == -1) {
    printf("Fail reading at position 0\n");
    return -1;
  }


  // Read at 1Gb+1 offset
  if (test_read_one_byte(fd, _1GB+1) == -1) {
    printf("Fail reading at position 1GB+1\n");
    return -1;
  }

  // Read at 2Gb+1 offset
  if (test_read_one_byte(fd, 2*_1GB+1) == -1) {
    printf("Fail reading at position 2GB+1\n");
    return -1;
  }
  // Read at 3Gb+1 offset
  if (test_read_one_byte(fd, 3*_1GB+1) == -1) {
    printf("Fail reading at position 3GB+1\n");
    return -1;
  }
  // Read at 4Gb+1 offset
  if (test_read_one_byte(fd, 4*_1GB+1) == -1) {
    printf("Fail reading at position 4GB+1\n");
    return -1;
  }
  // Read at 5Gb+1 offset
  if (test_read_one_byte(fd, 5*_1GB+1) == -1) {
    printf("Fail reading at position 4GB+1\n");
    return -1;
  }
  // Read at 6Gb+1 offset
  if (test_read_one_byte(fd, 6*_1GB+1) == -1) {
    printf("Fail reading at position 4GB+1\n");
    return -1;
  }
  // Read at 7Gb+1 offset
  if (test_read_one_byte(fd, 7*_1GB+1) == -1) {
    printf("Fail reading at position 4GB+1\n");
    return -1;
  }
  // Read at 8Gb+1 offset
  if (test_read_one_byte(fd, 8*_1GB+1) == -1) {
    printf("Fail reading at position 4GB+1\n");
    return -1;
  }
  // Read at 9Gb+1 offset
  if (test_read_one_byte(fd, 9*_1GB+1) == -1) {
    printf("Fail reading at position 4GB+1\n");
    return -1;
  }
  // Read at 10Gb+1 offset
  if (test_read_one_byte(fd, 10*_1GB+1) == -1) {
    printf("Fail reading at position 4GB+1\n");
    return -1;
  }


  // Everything ok
  return 0;
}

int main(int argc, char* argv[]) {
  return 0;
}

// Binding code
EMSCRIPTEN_BINDINGS(testcase_module) {
    emscripten::function("test_big_file", &test_big_file);
}