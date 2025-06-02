#!/bin/bash

# Termux Snapdragon W4A8 안전한 빌드 스크립트 (KleidiAI 링킹 문제 해결)

echo "🛡️  Termux Snapdragon W4A8 안전한 빌드"
echo "===================================="

# Termux 환경 확인
if [[ "$PREFIX" != *"termux"* ]]; then
    echo "❌ Termux 환경이 아닙니다."
    exit 1
fi

echo "✅ Termux 환경 감지: $PREFIX"

# 필수 패키지 확인
echo ""
echo "📦 패키지 확인 중..."

REQUIRED_PACKAGES=("clang" "cmake" "make" "git")
MISSING_PACKAGES=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo "✅ 필수 패키지 확인됨"
else
    echo "❌ 누락된 패키지: ${MISSING_PACKAGES[*]}"
    echo "💡 설치: pkg install ${MISSING_PACKAGES[*]}"
    exit 1
fi

# CPU 기능 확인
echo ""
echo "💪 CPU 기능 확인:"

if grep -q "asimd\|neon" /proc/cpuinfo; then
    echo "  ✅ NEON"
    NEON_SUPPORT=true
else
    echo "  ❌ NEON 없음"
    NEON_SUPPORT=false
fi

if grep -q "asimddp" /proc/cpuinfo; then
    echo "  ✅ DotProd"
    DOTPROD_SUPPORT=true
else
    echo "  ❌ DotProd 없음"
    DOTPROD_SUPPORT=false
fi

# 컴파일러 테스트
echo ""
echo "🔬 컴파일러 테스트:"

if clang -march=armv9-a -c -o /dev/null -x c /dev/null 2>/dev/null; then
    echo "  ✅ ARMv9 지원"
    ARCH_FLAGS="-march=armv9-a"
elif clang -march=armv8.2-a+dotprod -c -o /dev/null -x c /dev/null 2>/dev/null; then
    echo "  ✅ ARMv8.2+dotprod 지원"
    ARCH_FLAGS="-march=armv8.2-a+dotprod"
else
    echo "  ⚠️  기본 ARMv8 사용"
    ARCH_FLAGS="-march=armv8-a"
fi

# llama.cpp 확인
if [ ! -f "CMakeLists.txt" ]; then
    echo "❌ llama.cpp 루트에서 실행하세요"
    exit 1
fi

# 빌드 디렉토리
echo ""
echo "📁 빌드 디렉토리 설정..."
rm -rf build_termux_safe
mkdir -p build_termux_safe
cd build_termux_safe

# 안전한 플래그 (KleidiAI 제외)
SAFE_FLAGS="$ARCH_FLAGS -O3 -fno-finite-math-only -DANDROID -D__ANDROID__"

echo ""
echo "🔧 안전한 빌드 플래그:"
echo "  $SAFE_FLAGS"
echo "  - KleidiAI 제외 (링킹 문제 방지)"
echo "  - ARM NEON 최적화"
echo "  - W4A8 기본 지원"

# CMake 설정
echo ""
echo "⚙️  안전한 CMake 설정..."

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DGGML_CPU=ON \
    -DGGML_NEON=$NEON_SUPPORT \
    -DGGML_CPU_KLEIDIAI=OFF \
    -DGGML_NATIVE=OFF \
    -DCMAKE_C_FLAGS="$SAFE_FLAGS -DDEBUG_W4A8=1" \
    -DCMAKE_CXX_FLAGS="$SAFE_FLAGS -DDEBUG_W4A8=1 -std=c++17"

if [ $? -ne 0 ]; then
    echo "❌ CMake 설정 실패!"
    
    # 최소 설정으로 재시도
    echo "🔄 최소 설정으로 재시도..."
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_CPU=ON \
        -DGGML_NEON=ON \
        -DGGML_CPU_KLEIDIAI=OFF \
        -DCMAKE_C_FLAGS="-O2 -DDEBUG_W4A8=1" \
        -DCMAKE_CXX_FLAGS="-O2 -DDEBUG_W4A8=1 -std=c++17"
    
    if [ $? -ne 0 ]; then
        echo "❌ 최소 설정도 실패!"
        exit 1
    fi
fi

echo "✅ CMake 설정 성공!"

# 빌드
echo ""
echo "🔨 빌드 중..."

# 안전한 단일 코어 빌드
echo "  단일 코어 빌드 (안정성 우선)"
make -j1

BUILD_SUCCESS=$?

# 결과
echo ""
echo "📋 빌드 결과:"

if [ $BUILD_SUCCESS -eq 0 ]; then
    echo "✅ 안전한 빌드 성공!"
    
    if [ -f "bin/llama-cli" ]; then
        echo "📁 바이너리: $(pwd)/bin/llama-cli"
        echo "📊 크기: $(ls -lh bin/llama-cli | awk '{print $5}')"
        
        # 실행 테스트
        echo ""
        echo "🧪 실행 테스트:"
        
        if timeout 5 ./bin/llama-cli --help >/dev/null 2>&1; then
            echo "  ✅ 실행 성공!"
            
            echo ""
            echo "🎯 W4A8 테스트 (KleidiAI 없음):"
            echo "  ./bin/llama-cli -m model_Q4_0.gguf -p 'Hello' -n 5"
            echo ""
            echo "📝 W4A8 설명:"
            echo "  - KleidiAI는 비활성화됨 (링킹 문제 방지)"
            echo "  - 기본 ARM NEON 최적화 사용"
            echo "  - Q4_0 모델 지원"
            echo "  - 디버그 정보 포함"
            
        else
            echo "  ⚠️  실행 테스트 실패"
        fi
        
    else
        echo "❌ 바이너리 생성 실패"
    fi
    
else
    echo "❌ 빌드 실패!"
    
    # 메모리/저장공간 확인
    echo ""
    echo "🔍 시스템 상태:"
    echo "  메모리:"
    free -h 2>/dev/null || echo "    확인 불가"
    echo "  저장공간:"
    df -h . 2>/dev/null | tail -1 || echo "    확인 불가"
fi

echo ""
echo "💡 W4A8 최적화 팁:"
echo "  • Q4_0 모델이 가장 안정적"
echo "  • Q8_0 모델도 지원"
echo "  • KleidiAI 없이도 ARM 최적화 적용"
echo "  • 메모리 사용량 ~50% 절약"

echo ""
echo "🚀 다음 단계:"
echo "  1. Q4_0 모델 다운로드"
echo "  2. ./bin/llama-cli로 테스트"
echo "  3. 성능 모니터링: top" 