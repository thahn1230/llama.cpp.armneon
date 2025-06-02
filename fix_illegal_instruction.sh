#!/bin/bash

# Illegal Instruction 오류 해결 스크립트

echo "🔧 Illegal Instruction 오류 진단 및 해결"
echo "========================================"

# 현재 디렉토리 확인
if [ ! -f "CMakeLists.txt" ]; then
    echo "❌ llama.cpp 루트 디렉토리에서 실행해주세요"
    exit 1
fi

echo "✅ llama.cpp 디렉토리 확인됨"

# 시스템 정보 확인
echo ""
echo "🔍 시스템 정보:"
echo "  Architecture: $(uname -m)"
echo "  Kernel: $(uname -r)"

# 자세한 CPU 정보 확인
echo ""
echo "💻 CPU 상세 정보:"
if [ -f /proc/cpuinfo ]; then
    # CPU 모델명
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    echo "  Model: $CPU_MODEL"
    
    # CPU 구현체 확인
    CPU_IMPLEMENTER=$(grep "CPU implementer" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    CPU_PART=$(grep "CPU part" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    echo "  Implementer: $CPU_IMPLEMENTER"
    echo "  CPU Part: $CPU_PART"
    
    # ARM 기능 플래그 상세 확인
    echo ""
    echo "🔬 ARM 기능 플래그 상세 분석:"
    
    if grep -q "asimd" /proc/cpuinfo; then
        echo "  ✅ ASIMD (Advanced SIMD/NEON)"
    else
        echo "  ❌ ASIMD 없음"
    fi
    
    if grep -q "asimddp" /proc/cpuinfo; then
        echo "  ✅ ASIMDDP (DotProd)"
    else
        echo "  ❌ ASIMDDP 없음"
    fi
    
    if grep -q "i8mm" /proc/cpuinfo; then
        echo "  ✅ I8MM (8-bit Matrix Multiplication)"
    else
        echo "  ❌ I8MM 없음"
    fi
    
    if grep -q "sve" /proc/cpuinfo; then
        echo "  ✅ SVE (Scalable Vector Extension)"
    else
        echo "  ❌ SVE 없음"
    fi
    
    if grep -q "bf16" /proc/cpuinfo; then
        echo "  ✅ BF16 (Brain Float 16)"
    else
        echo "  ❌ BF16 없음"
    fi
    
    # 전체 features 출력
    echo ""
    echo "📋 전체 CPU Features:"
    grep "Features" /proc/cpuinfo | head -1 | cut -d: -f2
    
else
    echo "  ❌ /proc/cpuinfo 읽기 실패"
fi

# 컴파일러 정보
echo ""
echo "🔧 컴파일러 확인:"
COMPILER=""
if command -v gcc >/dev/null 2>&1; then
    COMPILER="gcc"
    echo "  ✅ GCC: $(gcc --version | head -1)"
    
    # GCC가 지원하는 아키텍처 확인
    echo "  GCC 지원 아키텍처:"
    gcc -march=native -Q --help=target 2>/dev/null | grep -E "march|mtune" | head -5 || echo "    정보 없음"
    
elif command -v clang >/dev/null 2>&1; then
    COMPILER="clang"
    echo "  ✅ Clang: $(clang --version | head -1)"
else
    echo "  ❌ 컴파일러 없음!"
    exit 1
fi

# 안전한 아키텍처 플래그 결정
echo ""
echo "🎯 안전한 컴파일 플래그 결정:"

# 매우 보수적인 접근
SAFE_ARCH_FLAGS="-march=armv8-a"
DESCRIPTION="ARMv8-A 기본 (최대 호환성)"

# 단계별 기능 테스트
echo "  CPU 기능 단계별 테스트..."

# 1. NEON 테스트
if grep -q "asimd\|neon" /proc/cpuinfo; then
    echo "    ✅ NEON 지원 확인됨"
    SAFE_ARCH_FLAGS="-march=armv8-a"
    DESCRIPTION="ARMv8-A + NEON"
else
    echo "    ❌ NEON 지원 없음 (매우 드문 경우)"
fi

# 2. DotProd 테스트 (매우 보수적)
if grep -q "asimddp" /proc/cpuinfo; then
    echo "    ✅ DotProd 지원 감지, 하지만 보수적 접근"
    # DotProd를 지원한다고 해도 실제 실행에서 문제가 생길 수 있으므로 신중히 접근
    SAFE_ARCH_FLAGS="-march=armv8-a"  # 일단 기본으로 유지
    DESCRIPTION="ARMv8-A (DotProd 사용 안함 - 안전성 우선)"
fi

# 3. Cortex 계열 감지
if echo "$CPU_MODEL" | grep -qi "cortex"; then
    echo "    ✅ Cortex 계열 CPU 감지"
    SAFE_ARCH_FLAGS="$SAFE_ARCH_FLAGS -mtune=cortex-a57"  # 안전한 Cortex 타겟
    DESCRIPTION="$DESCRIPTION + Cortex-A57 tune"
fi

echo ""
echo "🔧 최종 선택된 플래그:"
echo "  $SAFE_ARCH_FLAGS"
echo "  설명: $DESCRIPTION"

# 기존 빌드 정리
echo ""
echo "🧹 기존 빌드 정리..."
rm -rf build build_* CMakeCache.txt cmake_install.cmake
echo "✅ 정리 완료"

# 새 빌드 디렉토리
echo ""
echo "📁 안전한 빌드 디렉토리 생성..."
mkdir -p build_safe
cd build_safe

# 안전한 CMake 설정
echo ""
echo "⚙️  안전한 CMake 설정 (illegal instruction 방지)..."

if [ "$COMPILER" = "clang" ]; then
    CC_COMPILER="clang"
    CXX_COMPILER="clang++"
else
    CC_COMPILER="gcc"
    CXX_COMPILER="g++"
fi

# 매우 보수적인 플래그
CONSERVATIVE_FLAGS="$SAFE_ARCH_FLAGS -O2"  # O3 대신 O2 사용
echo "  보수적 플래그: $CONSERVATIVE_FLAGS"

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=$CC_COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DGGML_CPU=ON \
    -DGGML_NEON=ON \
    -DCMAKE_C_FLAGS="$CONSERVATIVE_FLAGS -DDEBUG_W4A8=1" \
    -DCMAKE_CXX_FLAGS="$CONSERVATIVE_FLAGS -DDEBUG_W4A8=1 -std=c++17"

if [ $? -ne 0 ]; then
    echo "❌ CMake 설정 실패! 최소 설정으로 재시도..."
    
    # 최소한의 설정
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=$CC_COMPILER \
        -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
        -DGGML_CPU=ON
    
    if [ $? -ne 0 ]; then
        echo "❌ 최소 설정도 실패!"
        exit 1
    fi
fi

echo "✅ CMake 설정 성공!"

# 안전한 빌드
echo ""
echo "🔨 안전한 빌드 시작 (단일 코어)..."
make -j1

if [ $? -eq 0 ]; then
    echo "✅ 빌드 성공!"
    
    if [ -f "bin/llama-cli" ]; then
        echo "📁 바이너리 생성: $(pwd)/bin/llama-cli"
        echo "📊 크기: $(ls -lh bin/llama-cli | awk '{print $5}')"
        
        # 바이너리 정보 확인
        echo ""
        echo "🔍 바이너리 정보:"
        file bin/llama-cli 2>/dev/null || echo "  file 명령어 없음"
        
        # 단계별 실행 테스트
        echo ""
        echo "🧪 단계별 실행 테스트:"
        
        # 1. 가장 기본적인 실행
        echo "  1️⃣ 기본 실행 테스트..."
        if timeout 5 ./bin/llama-cli 2>/dev/null; then
            echo "    ✅ 기본 실행 성공"
        else
            EXIT_CODE=$?
            if [ $EXIT_CODE -eq 132 ]; then
                echo "    ❌ 여전히 illegal instruction 발생!"
                echo ""
                echo "🔍 추가 진단 필요:"
                echo "  1. 더 낮은 최적화 레벨 필요"
                echo "  2. 라이브러리 호환성 문제"
                echo "  3. 크로스 컴파일 필요할 수 있음"
            else
                echo "    ⚠️  다른 종료 코드: $EXIT_CODE (정상일 수 있음)"
            fi
        fi
        
        # 2. 도움말 출력 테스트
        echo "  2️⃣ 도움말 테스트..."
        if timeout 10 ./bin/llama-cli --help >/dev/null 2>&1; then
            echo "    ✅ 도움말 실행 성공!"
            echo ""
            echo "🎯 W4A8 테스트 준비 완료!"
            echo "  GGML_CPU_KLEIDIAI=1 ./bin/llama-cli -m model_Q4_0.gguf -p 'test' -n 5"
        else
            echo "    ❌ 도움말 실행 실패"
        fi
        
    else
        echo "⚠️  바이너리 생성되지 않음"
    fi
else
    echo "❌ 빌드 실패"
fi

echo ""
echo "💡 Illegal Instruction 완전 해결 방법:"
echo "  1. 현재 보수적 빌드 시도 완료"
echo "  2. 여전히 문제 시: 크로스 컴파일 권장"
echo "  3. 또는 -march=armv7-a 등 더 낮은 아키텍처 시도"
echo "  4. 환경 변수: export QEMU_CPU=cortex-a57"
echo ""
echo "🔧 더 안전한 빌드 명령어:"
echo "  cmake .. -DCMAKE_BUILD_TYPE=Release -DGGML_CPU=ON -DCMAKE_C_FLAGS='-march=armv8-a -O1'"
echo "  make -j1" 