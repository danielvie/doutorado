#pragma once

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>

#define MAX_SIGNAL_SIZE   100
#define MAX_MATRIX_ELEMENTS 100

#define CONTROL_MIN_GAP_US 3
#define CONTROL_MAX_DTK   (MAX_SIGNAL_SIZE - 1)

struct MatrixData {
    float    values[MAX_MATRIX_ELEMENTS];
    uint16_t size;
    uint16_t rows, cols;
    bool     is_valid;
};

struct DataSet {
    uint32_t   time_durations[MAX_SIGNAL_SIZE];
    uint32_t   modes_d4[MAX_SIGNAL_SIZE];
    uint32_t   modes_d5[MAX_SIGNAL_SIZE];
    uint32_t   modes_d6[MAX_SIGNAL_SIZE];
    uint32_t   size;
    int32_t    time_us_diff[MAX_SIGNAL_SIZE];
    float      target[3];
    MatrixData gain_k;
};

void compute_duration_corrections(const uint32_t *time_durations, const float *dtk_us, int32_t *corrections, uint32_t p, uint32_t N);
bool compute_control_correction(DataSet *dataset, float an3, float an5, float an6, float *dtk_us);