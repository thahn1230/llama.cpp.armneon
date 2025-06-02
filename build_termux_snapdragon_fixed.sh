#!/bin/bash

# Termux Snapdragon 8 Gen 3 W4A8 빌드 스크립트 (수정된 버전)

echo "🚀 Termux Snapdragon 8 Gen 3 W4A8 빌드 (수정됨)"
echo "================================================="

# Termux 환경 확인
if [[ "$PREFIX" != *"termux"* ]]; then
    echo "❌ Termux 환경이 아닙니다."
    echo "💡 Android Termux에서 실행해주세요."
    exit 1
fi

echo "✅ Termux 환경 감지: $PREFIX"

# 필수 패키지 확인
echo ""
echo "📦 Termux 패키지 확인 중..."

REQUIRED_PACKAGES=("clang" "cmake" "ninja" "make" "git" "python" "curl")
MISSING_PACKAGES=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo "✅ 모든 필수 패키지가 설치되어 있습니다."
else
    echo "❌ 누락된 패키지: ${MISSING_PACKAGES[*]}"
    echo "💡 설치 명령어: pkg install ${MISSING_PACKAGES[*]}"
    exit 1
fi

# CPU 기능 확인
echo ""
echo "💪 Snapdragon 8 Gen 3 기능 확인:"

# ARM 기능 확인
NEON_SUPPORT=false
DOTPROD_SUPPORT=false
I8MM_SUPPORT=false
BF16_SUPPORT=false

if grep -q "asimd\|neon" /proc/cpuinfo; then
    NEON_SUPPORT=true
fi

if grep -q "asimddp" /proc/cpuinfo; then
    DOTPROD_SUPPORT=true
fi

if grep -q "i8mm" /proc/cpuinfo; then
    I8MM_SUPPORT=true
fi

if grep -q "bf16" /proc/cpuinfo; then
    BF16_SUPPORT=true
fi

echo "NEON: $NEON_SUPPORT"
echo "DotProd: $DOTPROD_SUPPORT"
echo "I8MM: $I8MM_SUPPORT"
echo "BF16: $BF16_SUPPORT"

# 컴파일러 기능 테스트
echo ""
echo "🔬 컴파일러 기능 테스트:"

if clang -march=armv9-a -c -o /dev/null -x c /dev/null 2>/dev/null; then
    echo "✅ ARMv9 지원"
    ARCH_FLAGS="-march=armv9-a"
else
    echo "⚠️  ARMv9 불가, ARMv8.2 사용"
    ARCH_FLAGS="-march=armv8.2-a+dotprod"
fi

# llama.cpp 루트 디렉토리 확인
if [ ! -f "CMakeLists.txt" ]; then
    echo "❌ llama.cpp 루트 디렉토리에서 실행해주세요"
    exit 1
fi

# 빌드 디렉토리 설정
echo ""
echo "📁 빌드 디렉토리 설정..."
rm -rf build_termux_snapdragon_fixed
mkdir -p build_termux_snapdragon_fixed
cd build_termux_snapdragon_fixed

# 안전한 최적화 플래그 (finite-math 문제 해결)
SAFE_FLAGS="$ARCH_FLAGS -O3 -fno-finite-math-only -DANDROID -D__ANDROID__"

echo ""
echo "🔧 안전한 최적화 플래그:"
echo "  $SAFE_FLAGS"
echo "  - ARMv9/ARMv8.2 최적화"
echo "  - O3 고성능 최적화"
echo "  - finite-math 해제 (NaN/infinity 허용)"
echo "  - Android 타겟"

# CMake 설정
echo ""
echo "⚙️  CMake 설정 중..."

# 우선 Ninja 시도
echo "🔧 Ninja 빌드 시스템 사용..."

cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DGGML_CPU=ON \
    -DGGML_NEON=ON \
    -DGGML_CPU_KLEIDIAI=ON \
    -DGGML_NATIVE=OFF \
    -DCMAKE_C_FLAGS="$SAFE_FLAGS -DDEBUG_W4A8=1" \
    -DCMAKE_CXX_FLAGS="$SAFE_FLAGS -DDEBUG_W4A8=1 -std=c++17"

CMAKE_SUCCESS=$?

# Ninja 실패시 Make로 폴백
if [ $CMAKE_SUCCESS -ne 0 ]; then
    echo "⚠️  Ninja 설정 실패, Make로 폴백..."
    
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DGGML_CPU=ON \
        -DGGML_NEON=ON \
        -DGGML_CPU_KLEIDIAI=ON \
        -DGGML_NATIVE=OFF \
        -DCMAKE_C_FLAGS="$SAFE_FLAGS -DDEBUG_W4A8=1" \
        -DCMAKE_CXX_FLAGS="$SAFE_FLAGS -DDEBUG_W4A8=1 -std=c++17"
    
    CMAKE_SUCCESS=$?
fi

if [ $CMAKE_SUCCESS -ne 0 ]; then
    echo "❌ CMake 설정 실패!"
    exit 1
fi

echo "✅ CMake 설정 완료"

# 빌드 시작
echo ""
echo "🔨 컴파일 중..."

# CPU 코어 수 확인
CORES=$(nproc)
BUILD_JOBS=$((CORES > 4 ? 4 : CORES))  # 최대 4개 코어 사용

echo "사용 코어: $BUILD_JOBS"
echo "예상 시간: 10-20분 (디바이스 성능에 따라)"

# 빌드 실행
if command -v ninja >/dev/null 2>&1 && [ -f "build.ninja" ]; then
    echo "🔧 Ninja 빌드 실행"
    ninja -j$BUILD_JOBS
    BUILD_SUCCESS=$?
else
    echo "🔧 Make 빌드 실행"
    make -j$BUILD_JOBS
    BUILD_SUCCESS=$?
fi

# 빌드 실패시 단일 코어로 재시도
if [ $BUILD_SUCCESS -ne 0 ]; then
    echo "⚠️  병렬 빌드 실패, 단일 코어로 재시도..."
    
    if command -v ninja >/dev/null 2>&1 && [ -f "build.ninja" ]; then
        ninja -j1
        BUILD_SUCCESS=$?
    else
        make -j1
        BUILD_SUCCESS=$?
    fi
fi

# 빌드 결과
echo ""
echo "📋 빌드 결과:"

if [ $BUILD_SUCCESS -eq 0 ]; then
    echo "✅ 빌드 성공!"
    
    if [ -f "bin/llama-cli" ]; then
        echo "📁 바이너리: $(pwd)/bin/llama-cli"
        echo "📊 크기: $(ls -lh bin/llama-cli | awk '{print $5}')"
        
        # 실행 테스트
        echo ""
        echo "🧪 실행 테스트:"
        
        if timeout 5 ./bin/llama-cli --help >/dev/null 2>&1; then
            echo "✅ 실행 성공!"
            echo ""
            echo "🎯 W4A8 테스트 명령어:"
            echo "  GGML_CPU_KLEIDIAI=1 ./bin/llama-cli -m model_Q4_0.gguf -p 'Hello world' -n 10"
            echo ""
            echo "🚀 성능 최적화 환경변수:"
            echo "  export GGML_CPU_KLEIDIAI=1"
            echo "  export OMP_NUM_THREADS=$BUILD_JOBS"
            echo "  export ANDROID_LOG_TAGS='*:I'"
        else
            echo "⚠️  실행 테스트 실패 (바이너리는 생성됨)"
        fi
    else
        echo "❌ 바이너리 생성되지 않음"
    fi
else
    echo "❌ 빌드 실패!"
    echo ""
    echo "🔍 문제 해결 방법:"
    echo "  1. 저장 공간 확인: df -h"
    echo "  2. 메모리 확인: free -h"
    echo "  3. Termux 업데이트: pkg update && pkg upgrade"
    echo "  4. 재시도: rm -rf build_termux_snapdragon_fixed && ./build_termux_snapdragon_fixed.sh"
fi

echo ""
echo "💡 Termux 팁:"
echo "  • 백그라운드 실행: termux-wake-lock"
echo "  • 성능 모드: su -c 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'"
echo "  • 메모리 모니터링: top" 