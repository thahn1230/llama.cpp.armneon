#!/bin/bash

# Ninja 빌드 오류 빠른 해결 스크립트

echo "🔧 Ninja 빌드 오류 진단 및 해결"
echo "==============================="

# 현재 디렉토리 확인
if [ ! -f "CMakeLists.txt" ]; then
    echo "❌ llama.cpp 루트 디렉토리에서 실행해주세요"
    exit 1
fi

echo "✅ llama.cpp 디렉토리 확인됨"

# 기존 빌드 디렉토리 정리
echo ""
echo "🧹 기존 빌드 파일 정리..."
rm -rf build build_* CMakeCache.txt cmake_install.cmake
echo "✅ 정리 완료"

# 환경 확인
echo ""
echo "🔍 빌드 환경 확인:"
echo "  Architecture: $(uname -m)"

# 컴파일러 확인
COMPILER=""
if command -v gcc >/dev/null 2>&1; then
    COMPILER="gcc"
    echo "  ✅ GCC: $(gcc --version | head -1)"
elif command -v clang >/dev/null 2>&1; then
    COMPILER="clang"
    echo "  ✅ Clang: $(clang --version | head -1)"
else
    echo "  ❌ 컴파일러 없음!"
    echo "💡 설치: pkg install clang (Termux) 또는 sudo apt install build-essential"
    exit 1
fi

# CMake 확인
if command -v cmake >/dev/null 2>&1; then
    echo "  ✅ CMake: $(cmake --version | head -1)"
else
    echo "  ❌ CMake 없음!"
    echo "💡 설치: pkg install cmake (Termux) 또는 sudo apt install cmake"
    exit 1
fi

# 빌드 도구 확인
NINJA_AVAILABLE=false
MAKE_AVAILABLE=false

if command -v ninja >/dev/null 2>&1; then
    echo "  ✅ Ninja: $(ninja --version)"
    NINJA_AVAILABLE=true
fi

if command -v make >/dev/null 2>&1; then
    echo "  ✅ Make: $(make --version | head -1)"
    MAKE_AVAILABLE=true
fi

if [ "$NINJA_AVAILABLE" = false ] && [ "$MAKE_AVAILABLE" = false ]; then
    echo "  ❌ 빌드 도구 없음!"
    echo "💡 설치: pkg install make ninja (Termux) 또는 sudo apt install make ninja-build"
    exit 1
fi

# 빌드 디렉토리 생성
echo ""
echo "📁 새로운 빌드 디렉토리 생성..."
mkdir -p build_fixed
cd build_fixed

# 간단한 CMake 설정 (오류 방지)
echo ""
echo "⚙️  안전한 CMake 설정..."

if [ "$COMPILER" = "clang" ]; then
    CC_COMPILER="clang"
    CXX_COMPILER="clang++"
else
    CC_COMPILER="gcc" 
    CXX_COMPILER="g++"
fi

# 기본 아키텍처 플래그
ARCH_FLAGS=""
if [ -f /proc/cpuinfo ]; then
    if grep -q 'i8mm' /proc/cpuinfo; then
        ARCH_FLAGS="-march=armv8.4-a+dotprod+i8mm"
        echo "  🎯 I8MM 지원 감지"
    elif grep -q 'asimddp\|dotprod' /proc/cpuinfo; then
        ARCH_FLAGS="-march=armv8.2-a+dotprod"
        echo "  🎯 DotProd 지원 감지"
    else
        ARCH_FLAGS="-march=armv8-a"
        echo "  🔧 기본 ARMv8 사용"
    fi
else
    ARCH_FLAGS="-march=armv8-a"
    echo "  🔧 안전한 기본 설정 사용"
fi

# CMake 실행 (Make 우선, 안정성 보장)
echo "  Generator: Unix Makefiles (안정성 우선)"
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=$CC_COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DGGML_CPU=ON \
    -DGGML_NEON=ON \
    -DGGML_CPU_KLEIDIAI=ON \
    -DCMAKE_C_FLAGS="$ARCH_FLAGS -O3 -DDEBUG_W4A8=1" \
    -DCMAKE_CXX_FLAGS="$ARCH_FLAGS -O3 -DDEBUG_W4A8=1 -std=c++17"

CMAKE_SUCCESS=$?

if [ $CMAKE_SUCCESS -ne 0 ]; then
    echo "❌ CMake 설정 실패! 최소 설정으로 재시도..."
    
    # 최소 설정으로 재시도
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=$CC_COMPILER \
        -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
        -DGGML_CPU=ON
    
    if [ $? -ne 0 ]; then
        echo "❌ 최소 설정도 실패!"
        echo ""
        echo "🔍 문제 해결:"
        echo "  1. 패키지 업데이트: pkg update && pkg upgrade"
        echo "  2. 필수 패키지: pkg install cmake clang make git"
        echo "  3. 저장 공간 확인: df -h"
        echo "  4. 권한 확인: ls -la .."
        exit 1
    fi
fi

echo "✅ CMake 설정 성공!"

# Makefile 존재 확인
if [ -f "Makefile" ]; then
    echo "✅ Makefile 생성됨"
else
    echo "❌ Makefile 생성 실패"
    exit 1
fi

# 빌드 실행
echo ""
echo "🔨 빌드 시작..."
echo "  CPU 코어: $(nproc)"

# 안전한 단일 코어 빌드로 시작
echo "  🔧 안전한 빌드 (단일 코어)"
make -j1

if [ $? -eq 0 ]; then
    echo "✅ 빌드 성공!"
    
    if [ -f "bin/llama-cli" ]; then
        echo "📁 바이너리 생성: $(pwd)/bin/llama-cli"
        echo "📊 크기: $(ls -lh bin/llama-cli | awk '{print $5}')"
        
        # 실행 테스트
        if ./bin/llama-cli --help >/dev/null 2>&1; then
            echo "✅ 실행 테스트 성공"
            echo ""
            echo "🎯 W4A8 테스트 방법:"
            echo "  GGML_CPU_KLEIDIAI=1 ./bin/llama-cli -m model_Q4_0.gguf -p 'test' -n 5"
        else
            echo "⚠️  실행 테스트 실패 (라이브러리 의존성 문제일 수 있음)"
        fi
    else
        echo "⚠️  바이너리 생성되지 않음"
    fi
    
    echo ""
    echo "🚀 빠른 병렬 빌드를 원한다면:"
    echo "  make -j$(nproc)  # 현재 디렉토리에서 실행"
    
else
    echo "❌ 빌드 실패"
    echo ""
    echo "🔍 디버깅 정보:"
    echo "  1. 마지막 오류 확인: make -j1 | tail -20"
    echo "  2. 메모리: free -h"
    echo "  3. 저장 공간: df -h"
    echo "  4. 의존성 문제일 수 있음"
fi

echo ""
echo "💡 다음에 사용할 안전한 빌드 명령어:"
echo "  mkdir build && cd build"
echo "  cmake .. -DCMAKE_BUILD_TYPE=Release -DGGML_CPU=ON"
echo "  make -j1" 