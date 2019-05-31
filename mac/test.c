#include <stdio.h>
#include "c_predict_api.h"

int main() {
    int pred = MXPredCreate("{}", NULL, 0, 0, 0, 0, NULL, NULL, NULL, NULL);

    printf("[TEST] Construct pseudo model: %d\n", pred);
    printf("%s\n", MXGetLastError());
    return 0;
}
