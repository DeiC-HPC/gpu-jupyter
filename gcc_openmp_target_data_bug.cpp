#include <iostream>

using namespace std;

void with_target_data(int num) {
  int *elements = new int[num];
  long res = 0;

  #pragma omp target data map(from: elements[:num]) map(from: res)
  {
    #pragma omp target teams distribute parallel for
    for (int i = 0; i < num; i++) {
      elements[i] = i;
    }

    #pragma omp target teams distribute parallel for reduction(+: res)
    for (int i = 0; i < num; i++) {
      res += elements[i];
    }
  }

  cout << "Result with target data: " << res;

  delete elements;
}

void without_target_data(int num) {
  int *elements = new int[num];
  long res = 0;

  #pragma omp target teams distribute parallel for map(from: elements[:num])
  for (int i = 0; i < num; i++) {
    elements[i] = i;
  }

  #pragma omp target teams distribute parallel for reduction(+: res) map(to: elements[:num]) map(from: res)
  for (int i = 0; i < num; i++) {
    res += elements[i];
  }

  cout << "Result without target data: " << res;

  delete elements;
}

int main () {
  int num = 100000000;
  without_target_data(num);
  with_target_data(num);
  return 0;
}
