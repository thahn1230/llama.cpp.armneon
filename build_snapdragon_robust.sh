#!/bin/bash

# Snapdragon 8 Gen 3 Robust W4A8 빌드 스크립트 (Ninja 오류 해결)

echo "🚀 Snapdragon 8 Gen 3 Robust W4A8 빌드"
echo "======================================="

# 환경 확인
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo "❌ ARM64 환경이 아닙니다: $ARCH"
    exit 1
fi

echo "✅ ARM64 환경 감지: $ARCH"

# 빌드 도구 확인 및 선택
echo ""
echo "🔧 빌드 도구 확인:"

# 컴파일러 확인
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

echo "  ✅ CMake: $(cmake --version | head -1)"

# 빌드 시스템 선택 (Ninja vs Make)
BUILD_SYSTEM=""
CMAKE_GENERATOR=""

if command -v ninja >/dev/null 2>&1; then
    echo "  ✅ Ninja: $(ninja --version)"
    BUILD_SYSTEM="ninja"
    CMAKE_GENERATOR="-G Ninja"
    echo "  🎯 빌드 시스템: Ninja (더 빠름)"
elif command -v make >/dev/null 2>&1; then
    echo "  ✅ Make: $(make --version | head -1)"
    BUILD_SYSTEM="make"
    CMAKE_GENERATOR=""  # 기본 Unix Makefiles
    echo "  🎯 빌드 시스템: Make (안정적)"
else
    echo "  ❌ 빌드 도구를 찾을 수 없습니다!"
    echo "💡 설치 방법:"
    echo "  # Ubuntu/Debian: sudo apt install make"
    echo "  # Termux: pkg install make"
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
        echo "  ⚠️  기본 ARMv8 모드"
    fi
else
    echo "  ⚠️  CPU 정보 읽기 실패, 안전한 기본 설정 사용"
    ARCH_FLAGS="-march=armv8-a"
fi

# 빌드 디렉토리 설정
echo ""
echo "📁 빌드 디렉토리 설정..."
BUILD_DIR="build_snapdragon_robust"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# 최적화 플래그
OPTIMIZATION_FLAGS="$ARCH_FLAGS -mtune=cortex-a76 -O3 -ffast-math"

echo ""
echo "🔧 최적화 플래그:"
echo "  $OPTIMIZATION_FLAGS"
echo "  빌드 시스템: $BUILD_SYSTEM"

# CMake 설정 (robust 모드)
echo ""
echo "⚙️  CMake 설정 중..."
echo "  Generator: ${CMAKE_GENERATOR:-Unix Makefiles}"

# CMake 실행
cmake .. \
    $CMAKE_GENERATOR \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=$COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DGGML_LLAMAFILE=ON \
    -DGGML_CPU_KLEIDIAI=ON \
    -DGGML_NATIVE=ON \
    -DGGML_CPU=ON \
    -DGGML_BACKEND_DL=OFF \
    -DGGML_NEON=ON \
    -DCMAKE_C_FLAGS="$OPTIMIZATION_FLAGS -DDEBUG_W4A8=1" \
    -DCMAKE_CXX_FLAGS="$OPTIMIZATION_FLAGS -DDEBUG_W4A8=1 -std=c++17"

CMAKE_EXIT_CODE=$?

if [ $CMAKE_EXIT_CODE -ne 0 ]; then
    echo "❌ CMake 설정 실패!"
    echo ""
    echo "🔍 문제 해결 시도:"
    
    # 더 간단한 설정으로 재시도
    echo "  간단한 설정으로 재시도 중..."
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=$COMPILER \
        -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
        -DGGML_CPU=ON \
        -DGGML_NEON=ON \
        -DCMAKE_C_FLAGS="$ARCH_FLAGS -O3" \
        -DCMAKE_CXX_FLAGS="$ARCH_FLAGS -O3 -std=c++17"
    
    if [ $? -ne 0 ]; then
        echo "❌ 간단한 설정도 실패!"
        echo ""
        echo "💡 수동 해결 방법:"
        echo "  1. 의존성 설치: sudo apt install build-essential cmake"
        echo "  2. 권한 확인: ls -la .."
        echo "  3. 저장 공간: df -h"
        exit 1
    fi
fi

echo "✅ CMake 설정 완료"

# 빌드 파일 확인
echo ""
echo "🔍 빌드 파일 확인:"
if [ "$BUILD_SYSTEM" = "ninja" ]; then
    if [ -f "build.ninja" ]; then
        echo "  ✅ build.ninja 파일 생성됨"
    else
        echo "  ❌ build.ninja 파일 없음, Make로 폴백"
        BUILD_SYSTEM="make"
    fi
fi

if [ "$BUILD_SYSTEM" = "make" ]; then
    if [ -f "Makefile" ]; then
        echo "  ✅ Makefile 생성됨"
    else
        echo "  ❌ Makefile도 없음!"
        exit 1
    fi
fi

# 빌드 실행
echo ""
echo "🔨 컴파일 중..."
echo "  빌드 시스템: $BUILD_SYSTEM"
echo "  CPU 코어: $(nproc)"
echo "  예상 시간: 3-10분"

PARALLEL_JOBS=$(nproc)
# 메모리가 부족할 수 있으므로 코어 수 제한
if [ $PARALLEL_JOBS -gt 4 ]; then
    PARALLEL_JOBS=4
fi

echo "  병렬 작업 수: $PARALLEL_JOBS"

# 빌드 실행
if [ "$BUILD_SYSTEM" = "ninja" ]; then
    ninja -j$PARALLEL_JOBS
    BUILD_SUCCESS=$?
else
    make -j$PARALLEL_JOBS
    BUILD_SUCCESS=$?
fi

# 빌드 실패 시 단일 코어로 재시도
if [ $BUILD_SUCCESS -ne 0 ]; then
    echo "⚠️  병렬 빌드 실패, 단일 코어로 재시도..."
    
    if [ "$BUILD_SYSTEM" = "ninja" ]; then
        ninja -j1
        BUILD_SUCCESS=$?
    else
        make -j1
        BUILD_SUCCESS=$?
    fi
fi

# 결과 확인
echo ""
echo "📋 빌드 결과:"
if [ $BUILD_SUCCESS -eq 0 ]; then
    echo "✅ Snapdragon 8 Gen 3 빌드 성공!"
    
    if [ -f "bin/llama-cli" ]; then
        echo "📁 바이너리: $(pwd)/bin/llama-cli"
        echo "📊 크기: $(ls -lh bin/llama-cli | awk '{print $5}')"
        
        # 바이너리 정보
        echo ""
        echo "🔍 바이너리 정보:"
        file bin/llama-cli 2>/dev/null || echo "  file 명령어 없음"
        
        # 간단한 실행 테스트
        echo ""
        echo "🧪 실행 테스트:"
        if ./bin/llama-cli --help >/dev/null 2>&1; then
            echo "  ✅ 바이너리 실행 가능"
        else
            echo "  ⚠️  실행 테스트 실패 (라이브러리 의존성 확인 필요)"
        fi
        
        echo ""
        echo "🎯 W4A8 테스트 방법:"
        echo "  GGML_CPU_KLEIDIAI=1 ./bin/llama-cli -m your_Q4_0_model.gguf -p \"test\" -n 5"
        
    else
        echo "⚠️  바이너리가 생성되지 않았습니다"
        echo "빌드 타겟 확인:"
        ls -la bin/ 2>/dev/null || echo "  bin/ 디렉토리 없음"
    fi
else
    echo "❌ 빌드 실패!"
    echo ""
    echo "🔍 문제 해결:"
    echo "  1. 마지막 오류 확인: tail -20 빌드 로그"
    echo "  2. 메모리 확인: free -h"
    echo "  3. 저장 공간: df -h"
    echo "  4. 의존성 설치:"
    echo "     sudo apt install build-essential cmake libssl-dev"
    echo "  5. 최소 빌드 시도:"
    echo "     cmake .. -DCMAKE_BUILD_TYPE=Release -DGGML_CPU=ON"
    echo "     make -j1"
fi

echo ""
echo "💡 다음 단계:"
echo "  1. 환경 진단: cd .. && ./check_snapdragon_env.sh"
echo "  2. W4A8 테스트: ./test_snapdragon8gen3_w4a8.sh"
echo "  3. 성능 벤치마크: ./benchmark_w4a8_arm.sh" 