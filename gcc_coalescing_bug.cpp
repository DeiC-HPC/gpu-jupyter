#include <iostream>
#include <time.h>

using namespace std;

#define HEIGHT 20000
#define WIDTH 20000
#define MEMSIZE WIDTH *HEIGHT

static double timespec_diff(struct timespec *start, struct timespec *stop) {
  return (stop->tv_sec - start->tv_sec) +
         (stop->tv_nsec - start->tv_nsec) / 1000000000.0;
}

void run(const char *name, void (*f)(int *, int *, int *)) {
  int *a = new int[MEMSIZE];
  int *b = new int[MEMSIZE];
  int *res = new int[MEMSIZE];
  timespec start, end;

  for (int i = 0; i < HEIGHT; i++) {
    for (int j = 0; j < WIDTH; j++) {
      a[i * WIDTH + j] = 1;
      b[i * WIDTH + j] = 1;
    }
  }

  clock_gettime(CLOCK_MONOTONIC, &start);
  f(a, b, res);
  clock_gettime(CLOCK_MONOTONIC, &end);
  std::cout << "Elapsed time " << name << ": " << timespec_diff(&start, &end)
            << std::endl;

  delete a;
  delete b;
  delete res;
}

void non_coalesced(int *a, int *b, int *res) {
  #pragma omp target teams distribute parallel for \
      map(to: a[:WIDTH * HEIGHT]) \
      map(to: b[:WIDTH * HEIGHT]) \
      map(from: res[:WIDTH * HEIGHT])
  for (int i = 0; i < HEIGHT; i++) {
    for (int j = 0; j < WIDTH; j++) {
      res[i * WIDTH + j] = a[i * WIDTH + j] + b[i * WIDTH + j];
    }
  }
}

void coalesced(int *a, int *b, int *res) {
  #pragma omp target teams distribute parallel for \
      map(to: a[:WIDTH * HEIGHT]) \
      map(to: b[:WIDTH * HEIGHT]) \
      map(from: res[:WIDTH * HEIGHT])
  for (int j = 0; j < WIDTH; j++) {
    for (int i = 0; i < HEIGHT; i++) {
      res[i * WIDTH + j] = a[i * WIDTH + j] + b[i * WIDTH + j];
    }
  }
}

int main() {
  for (int i = 0; i < 4; i++) {
    run("non_coalesced", non_coalesced);
    run("coalesced", coalesced);
  }

  return 0;
}
