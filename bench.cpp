#include <iostream>
#include <chrono>
#include <array>

using Mat4 = std::array<float, 16>;

inline Mat4 mul(const Mat4& a, const Mat4& b) {
    Mat4 r;

    // Manually unrolled 4x4 matrix multiplication
    for (int i = 0; i < 4; ++i) {
        const float ai0 = a[i * 4 + 0];
        const float ai1 = a[i * 4 + 1];
        const float ai2 = a[i * 4 + 2];
        const float ai3 = a[i * 4 + 3];

        r[i * 4 + 0] = ai0 * b[0]  + ai1 * b[4]  + ai2 * b[8]  + ai3 * b[12];
        r[i * 4 + 1] = ai0 * b[1]  + ai1 * b[5]  + ai2 * b[9]  + ai3 * b[13];
        r[i * 4 + 2] = ai0 * b[2]  + ai1 * b[6]  + ai2 * b[10] + ai3 * b[14];
        r[i * 4 + 3] = ai0 * b[3]  + ai1 * b[7]  + ai2 * b[11] + ai3 * b[15];
    }

    return r;
}

int main() {
    constexpr size_t ITERATIONS = 100000000; // 100M

    Mat4 a = {
        1,2,3,4,
        5,6,7,8,
        9,10,11,12,
        13,14,15,16
    };

    Mat4 b = {
        16,15,14,13,
        12,11,10,9,
        8,7,6,5,
        4,3,2,1
    };

    volatile float sink = 0.0f; // prevent optimization

    auto start = std::chrono::high_resolution_clock::now();

    for (size_t i = 0; i < ITERATIONS; ++i) {
        Mat4 r = mul(a, b);
        sink += r[0]; // use result so it's not optimized away
    }

    auto end = std::chrono::high_resolution_clock::now();

    double seconds = std::chrono::duration<double>(end - start).count();

    std::cout << "Time: " << seconds << " seconds\n";
    std::cout << "Per mul: " << (seconds / ITERATIONS * 1e9) << " ns\n";
    std::cout << "Ignore: " << sink << "\n";

    return 0;
}
