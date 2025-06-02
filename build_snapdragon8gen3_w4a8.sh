#!/bin/bash

# Snapdragon 8 Gen 3 W4A8 최적화 빌드 스크립트
echo "🚀 Building llama.cpp with W4A8 for Snapdragon 8 Gen 3..."

# 환경 확인
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo "⚠️  현재 환경: $ARCH (크로스 컴파일 모드)"
    echo "🎯 Snapdragon 8 Gen 3 타겟으로 빌드합니다"
else
    echo "✅ ARM64 네이티브 환경 감지: $ARCH"
fi

# 기존 빌드 디렉토리 정리
rm -rf build_snapdragon
mkdir -p build_snapdragon
cd build_snapdragon

# Snapdragon 8 Gen 3 최적화 설정
# - ARMv9-A 아키텍처 
# - Cortex-X4 (성능 코어) 타겟
# - dotprod, i8mm, sve, bf16 지원
SNAPDRAGON_FLAGS="-march=armv9-a+sve+i8mm+bf16+dotprod -mtune=cortex-x4 -O3 -ffast-math"

echo "🔧 Snapdragon 8 Gen 3 최적화 플래그:"
echo "  Architecture: ARMv9-A"
echo "  Target CPU: Cortex-X4 (big cores)"
echo "  Features: SVE, I8MM, BF16, DotProd"
echo "  Optimization: -O3 -ffast-math"

# CMake 빌드 설정
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_LLAMAFILE=ON \
    -DLLAMA_NATIVE=ON \
    -DGGML_CPU_KLEIDIAI=ON \
    -DGGML_NATIVE=ON \
    -DGGML_CPU=ON \
    -DGGML_BACKEND_DL=OFF \
    -DGGML_SVE=ON \
    -DGGML_NEON=ON \
    -DCMAKE_C_FLAGS="$SNAPDRAGON_FLAGS -DDEBUG_W4A8=1" \
    -DCMAKE_CXX_FLAGS="$SNAPDRAGON_FLAGS -DDEBUG_W4A8=1 -std=c++17"

echo "📋 Configuration completed. Building with $(nproc) threads..."

# 병렬 빌드
make -j$(nproc)

if [ $? -eq 0 ]; then
    echo "✅ Snapdragon 8 Gen 3 빌드 완료!"
    echo ""
    echo "🎯 W4A8 테스트:"
    echo "  ./bin/llama-cli -m your_Q4_0_model.gguf -p \"Hello\" -n 5"
    echo ""
    echo "📊 예상 성능 개선:"
    echo "  🚀 ARMv9 SVE: 벡터 연산 최적화"
    echo "  ⚡ I8MM: 8bit 매트릭스 곱셈 가속"
    echo "  🎯 BF16: 메모리 대역폭 최적화"
    echo "  💪 Cortex-X4: 최대 성능 코어 활용"
else
    echo "❌ 빌드 실패!"
    echo "🔍 가능한 해결방법:"
    echo "  1. 네이티브 ARM64 환경에서 빌드"
    echo "  2. 크로스 컴파일 도구체인 설치"
    echo "  3. Docker ARM64 컨테이너 사용"
fi 