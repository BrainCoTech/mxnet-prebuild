#include <stdio.h>
#include <stdlib.h>
#include "c_predict_api.h"
#include "model.h"

#define MXNET_DEV_TYPE 1 // 1:CPU, 2: GPU. In most platforms, GPU driver support will be limited
#define MXNET_DEV_ID 0   // Arbitrary.

#define MXNET_NUM_THREADS 1
#define MXNET_NUM_INPUT_NODES 1 // Number of input nodes to the net, for feedforward net, this is 1.


#define ATTENTION_INPUT_LENGTH 1250
#define ATTENTION_OUTPUT_LENGTH 3


const char* attention_input_key[1] = { "data" };
const char** attention_input_keys = attention_input_key;

const mx_uint attention_input_shape_indptr[2] = { 0, 3 }; // column dim is 3
const mx_uint attention_input_shape_data[3] = {1, 1, ATTENTION_INPUT_LENGTH};

static PredictorHandle predictor;

const mx_float test_data[1250] = {0};

int attention_model_create() {
    return MXPredCreate(ATTENTION_SYMBOL,
               ATTENTION_PARAMS,
               (int) sizeof(ATTENTION_PARAMS),
               MXNET_DEV_TYPE,
               MXNET_DEV_ID,
               MXNET_NUM_INPUT_NODES,
               attention_input_keys,
               attention_input_shape_indptr,
               attention_input_shape_data,
               &predictor);
}

int main() {
    int res = attention_model_create();
    printf("[TEST] Construct pseudo model: %d\n", res);
    res = MXPredSetInput(predictor, "data", test_data, ATTENTION_INPUT_LENGTH);
    printf("[TEST] Set input to the model: %d\n", res);
    res = MXPredForward(predictor);
    printf("[TEST] Run forward pass to the model: %d\n", res);

    mx_uint output_index = 0;
    mx_uint *output_shape = NULL;
    mx_uint ouput_shape_len;

    // Get Output Result
    res = MXPredGetOutputShape(predictor, output_index, &output_shape, &ouput_shape_len);

    printf("[TEST] Get output shape success: %d\n", res);

    printf("[TEST] Output shape: %d\n", output_shape[0]);

    size_t size = 1;
    for (mx_uint i = 0; i < ouput_shape_len; ++i) { size *= output_shape[i]; }

    float* output = malloc(sizeof(float) * ATTENTION_OUTPUT_LENGTH);

    res = MXPredGetOutput(predictor, output_index, output, (mx_uint) size);

    printf("[TEST] Retrieve output success: %d\n", res);
    printf("[TEST] Retrieved output value[0]: %f\n", output[0]);
    printf("[TEST] Retrieved output value[1]: %f\n", output[1]);
    printf("[TEST] Retrieved output value[2]: %f\n", output[1]);

    printf("[TEST] Last error:%s\n", MXGetLastError());
    free(output);
    return 0;
}
