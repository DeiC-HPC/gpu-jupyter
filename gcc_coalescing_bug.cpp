#include <iostream>
#include <time.h>

using namespace std;

#define DIMSIZE 15001
#define MEMSIZE DIMSIZE * DIMSIZE

static double timespec_diff(struct timespec *start, struct timespec *stop) {
  return (stop->tv_sec - start->tv_sec) +
         (stop->tv_nsec - start->tv_nsec) / 1000000000.0;
}

void run(const char *name, void (*f)(int *, int *, int *)) {
  int *a = (int *)calloc(MEMSIZE, sizeof(int));
  int *b = (int *)calloc(MEMSIZE, sizeof(int));
  int *res = (int *)calloc(MEMSIZE, sizeof(int));
  timespec start, end;

  for (int i = 0; i < DIMSIZE; i++) {
    for (int j = 0; j < DIMSIZE; j++) {
      a[i * DIMSIZE + j] = 1;
      b[i * DIMSIZE + j] = 1;
    }
  }

  #pragma omp target data \
      map(to: a[:MEMSIZE]) \
      map(to: b[:MEMSIZE]) \
      map(from: res[:MEMSIZE])
  {
    clock_gettime(CLOCK_MONOTONIC, &start);
    f(a, b, res);
    clock_gettime(CLOCK_MONOTONIC, &end);
  }
  std::cout << name << ": " << std::endl;
  std::cout << "  Elapsed time: " << timespec_diff(&start, &end)
            << std::endl << std::endl;

  free(a);
  free(b);
  free(res);
}

void non_coalesced(int *a, int *b, int *res) {
  #pragma omp target teams distribute parallel for
  for (int i = 0; i < DIMSIZE; i++) {
    for (int j = 0; j < DIMSIZE; j++) {
      res[i * DIMSIZE + j] = a[i * DIMSIZE + j] + b[i * DIMSIZE + j];
    }
  }
}

void coalesced(int *a, int *b, int *res) {
  #pragma omp target teams distribute parallel for
  for (int j = 0; j < DIMSIZE; j++) {
    for (int i = 0; i < DIMSIZE; i++) {
      res[i * DIMSIZE + j] = a[i * DIMSIZE + j] + b[i * DIMSIZE + j];
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
