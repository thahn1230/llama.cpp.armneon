#!/bin/bash

# Snapdragon 8 Gen 3 ARMv8 호환 W4A8 빌드 스크립트

echo "🚀 Snapdragon 8 Gen 3 ARMv8 호환 W4A8 빌드"
echo "=========================================="

# 환경 확인
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo "❌ ARM64 환경이 아닙니다: $ARCH"
    exit 1
fi

echo "✅ ARM64 환경 감지: $ARCH"

# 컴파일러 확인
echo ""
echo "🔧 컴파일러 확인:"
if command -v gcc >/dev/null 2>&1; then
    echo "  ✅ GCC: $(gcc --version | head -1)"
    COMPILER="gcc"
    CXX_COMPILER="g++"
elif command -v clang >/dev/null 2>&1; then
    echo "  ✅ Clang: $(clang --version | head -1)"
    COMPILER="clang"
    CXX_COMPILER="clang++"
else
    echo "  ❌ 컴파일러를 찾을 수 없습니다!"
    echo "💡 설치 방법:"
    echo "  # Ubuntu/Debian: sudo apt install build-essential"
    echo "  # Termux: pkg install clang"
    exit 1
fi

# CMake 확인
if ! command -v cmake >/dev/null 2>&1; then
    echo "  ❌ CMake를 찾을 수 없습니다!"
    echo "💡 설치 방법:"
    echo "  # Ubuntu/Debian: sudo apt install cmake"
    echo "  # Termux: pkg install cmake"
    exit 1
fi

# CPU 기능 확인
echo ""
echo "💪 ARM CPU 기능 확인:"
if [ -f /proc/cpuinfo ]; then
    HAS_NEON=$(grep -q 'neon\|asimd' /proc/cpuinfo && echo "✅" || echo "❌")
    HAS_DOTPROD=$(grep -q 'asimddp\|dotprod' /proc/cpuinfo && echo "✅" || echo "❌")
    HAS_I8MM=$(grep -q 'i8mm' /proc/cpuinfo && echo "✅" || echo "❌")
    
    echo "  NEON: $HAS_NEON"
    echo "  DotProd: $HAS_DOTPROD"
    echo "  I8MM: $HAS_I8MM"
    
    # 기능에 따른 플래그 설정
    if grep -q 'i8mm' /proc/cpuinfo; then
        ARCH_FLAGS="-march=armv8.4-a+dotprod+i8mm"
        echo "  🎯 I8MM 지원으로 최대 W4A8 성능!"
    elif grep -q 'asimddp\|dotprod' /proc/cpuinfo; then
        ARCH_FLAGS="-march=armv8.2-a+dotprod"
        echo "  🎯 DotProd 지원으로 W4A8 가속!"
    else
        ARCH_FLAGS="-march=armv8-a"
        echo "  ⚠️  기본 ARMv8 모드 (성능 제한)"
    fi
else
    echo "  ⚠️  CPU 정보 읽기 실패, 기본 설정 사용"
    ARCH_FLAGS="-march=armv8.2-a+dotprod"
fi

# 빌드 디렉토리 설정
echo ""
echo "📁 빌드 디렉토리 설정..."
rm -rf build_snapdragon_armv8
mkdir -p build_snapdragon_armv8
cd build_snapdragon_armv8

# ARMv8 호환 최적화 플래그
COMPAT_FLAGS="$ARCH_FLAGS -mtune=cortex-a76 -O3 -ffast-math"

echo ""
echo "🔧 ARMv8 호환 플래그:"
echo "  $COMPAT_FLAGS"
echo "  Target: Cortex-A76 (범용 호환성)"
echo "  Features: NEON, DotProd, I8MM (가능한 경우)"

# CMake 설정
echo ""
echo "⚙️  CMake 설정 중..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=$COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DGGML_LLAMAFILE=ON \
    -DGGML_CPU_KLEIDIAI=ON \
    -DGGML_NATIVE=ON \
    -DGGML_CPU=ON \
    -DGGML_BACKEND_DL=OFF \
    -DGGML_NEON=ON \
    -DCMAKE_C_FLAGS="$COMPAT_FLAGS -DDEBUG_W4A8=1" \
    -DCMAKE_CXX_FLAGS="$COMPAT_FLAGS -DDEBUG_W4A8=1 -std=c++17"

if [ $? -ne 0 ]; then
    echo "❌ CMake 설정 실패!"
    echo ""
    echo "🔍 가능한 해결방법:"
    echo "  1. 빌드 도구 설치: sudo apt install build-essential cmake"
    echo "  2. 권한 확인: ls -la ."
    echo "  3. 저장 공간 확인: df -h"
    exit 1
fi

echo "✅ CMake 설정 완료"

# 빌드 실행
echo ""
echo "🔨 컴파일 중..."
echo "  아키텍처: ARMv8 호환 모드"
echo "  CPU 코어: $(nproc)"
echo "  예상 시간: 3-10분"

make -j$(nproc)
BUILD_SUCCESS=$?

# 결과 확인
echo ""
echo "📋 빌드 결과:"
if [ $BUILD_SUCCESS -eq 0 ]; then
    echo "✅ ARMv8 호환 빌드 성공!"
    
    if [ -f "bin/llama-cli" ]; then
        echo "📁 바이너리: $(pwd)/bin/llama-cli"
        echo "📊 크기: $(ls -lh bin/llama-cli | awk '{print $5}')"
        
        # 바이너리 정보 확인
        echo ""
        echo "🔍 바이너리 정보:"
        file bin/llama-cli 2>/dev/null || echo "  file 명령어 없음"
        
        echo ""
        echo "🧪 W4A8 테스트:"
        echo "  ./bin/llama-cli -m your_Q4_0_model.gguf -p \"ARM test\" -n 5"
        
        echo ""
        echo "📊 ARMv8 호환 모드 특징:"
        echo "  ✅ 광범위한 ARM 디바이스 호환"
        echo "  ⚡ DotProd 가속 (지원시)"
        echo "  🎯 I8MM 활용 (Snapdragon 8 Gen 3)"
        echo "  💾 W4A8 메모리 효율성"
        
    else
        echo "⚠️  바이너리가 생성되지 않았습니다"
    fi
else
    echo "❌ 빌드 실패!"
    echo ""
    echo "🔍 문제 해결:"
    echo "  1. 로그 확인: tail -50 빌드 로그"
    echo "  2. 메모리 확인: free -h"
    echo "  3. 더 간단한 빌드 시도:"
    echo "     cmake .. -DCMAKE_BUILD_TYPE=Release -DGGML_CPU=ON"
    echo "     make -j1  # 단일 코어 빌드"
fi

echo ""
echo "💡 성능 팁:"
echo "  • CPU 거버너: echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
echo "  • 스레드 수 조절: export OMP_NUM_THREADS=4"
echo "  • 메모리 최적화: export GGML_CPU_KLEIDIAI=1" 