#include <iostream>
#include <chrono>
#include <array>
#include <random>

using Motor = std::array<float, 8>;

// Scalar motor multiplication (same as before)
inline Motor motor_mul(const Motor& a, const Motor& b) {
    Motor r;

    const float a0 = a[0], a1 = a[1], a2 = a[2], a3 = a[3];
    const float a4 = a[4], a5 = a[5], a6 = a[6], a7 = a[7];

    const float b0 = b[0], b1 = b[1], b2 = b[2], b3 = b[3];
    const float b4 = b[4], b5 = b[5], b6 = b[6], b7 = b[7];

    r[0] = a0*b0 - a1*b1 - a2*b2 - a3*b3;
    r[1] = a0*b1 + a1*b0 + a2*b3 - a3*b2;
    r[2] = a0*b2 - a1*b3 + a2*b0 + a3*b1;
    r[3] = a0*b3 + a1*b2 - a2*b1 + a3*b0;

    r[4] = a0*b4 + a4*b0 - a1*b5 - a5*b1 - a2*b6 - a6*b2 - a3*b7 - a7*b3;
    r[5] = a0*b5 + a5*b0 + a1*b4 + a4*b1 - a2*b7 - a7*b2 - a3*b6 - a6*b3;
    r[6] = a0*b6 + a6*b0 + a1*b7 + a7*b1 + a2*b4 + a4*b2 - a3*b5 - a5*b3;
    r[7] = a0*b7 + a7*b0 + a1*b6 + a6*b1 + a2*b5 + a5*b2 + a3*b4 + a4*b3;

    return r;
}

int main() {
    constexpr size_t MOTOR_COUNT = 100000;
    constexpr size_t REPEATS = 1000;

    // Random number generator
    std::mt19937 rng(0);
    std::uniform_real_distribution<float> dist(-100.f, 100.f);

    // Generate a list of random motors
    std::vector<Motor> motors(MOTOR_COUNT);
    for (auto& m : motors) {
        for (int i = 0; i < 8; ++i) {
            m[i] = dist(rng);
        }
    }

    volatile float sink = 0.0f;
    auto start = std::chrono::high_resolution_clock::now();

    for (size_t rep = 0; rep < REPEATS; ++rep) {
        Motor acc = {1,0,0,0, 0,0,0,0}; // identity motor
        for (const auto& m : motors) {
            acc = motor_mul(acc, m);
        }
        sink += acc[0]; // prevent elimination
    }

    auto end = std::chrono::high_resolution_clock::now();
    double seconds = std::chrono::duration<double>(end - start).count();
    size_t total_muls = MOTOR_COUNT * REPEATS;

    std::cout << "Total time: " << seconds << " s\n";
    std::cout << "Per multiplication: " << (seconds / total_muls * 1e9) << " ns\n";
    std::cout << "Sink: " << sink << "\n";

    return 0;
}
