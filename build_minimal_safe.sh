#!/bin/bash

# 최소한의 안전한 빌드 스크립트 (Illegal Instruction 방지)

echo "🛡️  최소한의 안전한 llama.cpp 빌드"
echo "=================================="

# 환경 확인
if [ ! -f "CMakeLists.txt" ]; then
    echo "❌ llama.cpp 루트 디렉토리에서 실행해주세요"
    exit 1
fi

echo "✅ llama.cpp 디렉토리 확인됨"
echo "🎯 목표: Illegal Instruction 오류 완전 방지"

# 기존 빌드 정리
echo ""
echo "🧹 기존 빌드 정리..."
rm -rf build build_* CMakeCache.txt
mkdir -p build_minimal_safe
cd build_minimal_safe

# 컴파일러 확인
COMPILER="gcc"
if command -v clang >/dev/null 2>&1; then
    COMPILER="clang"
    echo "✅ Clang 사용"
elif command -v gcc >/dev/null 2>&1; then
    COMPILER="gcc"
    echo "✅ GCC 사용"
else
    echo "❌ 컴파일러 없음!"
    exit 1
fi

# 최대한 안전한 플래그 (illegal instruction 절대 방지)
ULTRA_SAFE_FLAGS="-march=armv8-a -O1 -fno-fast-math"

echo ""
echo "🔧 Ultra Safe 컴파일 플래그:"
echo "  $ULTRA_SAFE_FLAGS"
echo "  - ARMv8-A 기본 (모든 ARM64에서 호환)"
echo "  - O1 최적화 (안전한 수준)"
echo "  - fast-math 비활성화"

# CMake 설정
echo ""
echo "⚙️  최소 CMake 설정..."

if [ "$COMPILER" = "clang" ]; then
    CMAKE_C_COMPILER="clang"
    CMAKE_CXX_COMPILER="clang++"
else
    CMAKE_C_COMPILER="gcc"
    CMAKE_CXX_COMPILER="g++"
fi

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=$CMAKE_C_COMPILER \
    -DCMAKE_CXX_COMPILER=$CMAKE_CXX_COMPILER \
    -DGGML_CPU=ON \
    -DGGML_NEON=ON \
    -DGGML_CPU_KLEIDIAI=OFF \
    -DGGML_NATIVE=OFF \
    -DCMAKE_C_FLAGS="$ULTRA_SAFE_FLAGS" \
    -DCMAKE_CXX_FLAGS="$ULTRA_SAFE_FLAGS -std=c++17"

if [ $? -ne 0 ]; then
    echo "❌ CMake 실패! 더 간단한 설정 시도..."
    
    # 절대 최소 설정
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_CPU=ON \
        -DCMAKE_C_FLAGS="-O1" \
        -DCMAKE_CXX_FLAGS="-O1 -std=c++17"
    
    if [ $? -ne 0 ]; then
        echo "❌ 최소 설정도 실패!"
        exit 1
    fi
fi

echo "✅ CMake 설정 성공!"

# 안전한 단일 코어 빌드
echo ""
echo "🔨 안전한 빌드 (단일 코어, 시간이 걸릴 수 있음)..."
make -j1

if [ $? -eq 0 ]; then
    echo "✅ 빌드 성공!"
    
    if [ -f "bin/llama-cli" ]; then
        echo "📁 바이너리: $(pwd)/bin/llama-cli"
        
        # 실행 테스트
        echo ""
        echo "🧪 실행 테스트:"
        
        # 매우 짧은 타임아웃으로 테스트
        if timeout 3 ./bin/llama-cli --version 2>/dev/null; then
            echo "  ✅ 버전 확인 성공!"
        else
            echo "  ⚠️  버전 확인 실패 (하지만 빌드는 성공)"
        fi
        
        # 도움말 테스트
        if timeout 5 ./bin/llama-cli --help >/dev/null 2>&1; then
            echo "  ✅ 도움말 실행 성공!"
            echo ""
            echo "🎯 이제 W4A8 테스트 가능:"
            echo "  ./bin/llama-cli -m model_Q4_0.gguf -p 'Hello' -n 5"
            echo ""
            echo "🚀 W4A8 최적화 환경변수:"
            echo "  export GGML_CPU_KLEIDIAI=1"
            echo "  export OMP_NUM_THREADS=4"
        else
            echo "  ❌ 도움말 실행 실패"
            echo ""
            echo "🔍 추가 문제 해결이 필요할 수 있습니다:"
            echo "  1. 라이브러리 의존성 문제"
            echo "  2. 시스템 호환성 문제"
            echo "  3. 크로스 컴파일 필요"
        fi
        
    else
        echo "❌ 바이너리 생성 실패"
    fi
else
    echo "❌ 빌드 실패"
    echo ""
    echo "🔍 문제 해결:"
    echo "  1. 메모리 부족: free -h"
    echo "  2. 저장 공간: df -h"
    echo "  3. 컴파일러 재설치"
fi

echo ""
echo "💡 요약:"
echo "  - 이 스크립트는 illegal instruction을 피하기 위해"
echo "  - 매우 보수적인 설정을 사용합니다"
echo "  - 성능보다 안정성을 우선시합니다"
echo "  - W4A8 기능은 일부 제한될 수 있습니다" 