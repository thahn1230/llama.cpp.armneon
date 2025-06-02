#!/bin/bash

# ARM W4A8 빌드 스크립트
echo "🚀 Building llama.cpp with W4A8 support for ARM..."

# 기존 빌드 디렉토리 정리
rm -rf build_arm
mkdir -p build_arm
cd build_arm

# ARM W4A8 최적화 빌드 설정
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_LLAMAFILE=ON \
    -DGGML_CPU_KLEIDIAI=ON \
    -DGGML_NATIVE=ON \
    -DGGML_CPU=ON \
    -DGGML_BACKEND_DL=OFF \
    -DCMAKE_C_FLAGS="-march=armv8-a+dotprod+i8mm -mtune=cortex-a76 -O3" \
    -DCMAKE_CXX_FLAGS="-march=armv8-a+dotprod+i8mm -mtune=cortex-a76 -O3"

echo "📋 Configuration completed. Building..."

# 병렬 빌드
make -j$(nproc)

echo "✅ Build completed!"
echo ""
echo "🔍 Testing W4A8 activation:"
echo "  ./bin/llama-cli -m your_model_Q4_0.gguf -p \"Hello\" -n 5"
echo ""
echo "📊 Expected output should show:"
echo "  🎯 W4A8 KERNEL: ggml_vec_dot_q4_0_q8_0 called!" 