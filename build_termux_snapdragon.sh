#!/bin/bash

# Termux Snapdragon 8 Gen 3 W4A8 빌드 스크립트

echo "🚀 Termux Snapdragon 8 Gen 3 W4A8 빌드"
echo "====================================="

# Termux 환경 확인
if [ -z "$PREFIX" ]; then
    echo "❌ Termux 환경이 아닙니다. 일반 Linux 빌드 스크립트를 사용하세요."
    exit 1
fi

echo "✅ Termux 환경 감지: $PREFIX"

# 필수 패키지 확인 및 설치
echo ""
echo "📦 Termux 패키지 확인 중..."

PACKAGES_TO_INSTALL=""

if ! command -v clang >/dev/null 2>&1; then
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL clang"
fi

if ! command -v cmake >/dev/null 2>&1; then
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL cmake"
fi

if ! command -v make >/dev/null 2>&1; then
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL make"
fi

if ! command -v ninja >/dev/null 2>&1; then
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL ninja"
fi

if ! command -v git >/dev/null 2>&1; then
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL git"
fi

if [ ! -z "$PACKAGES_TO_INSTALL" ]; then
    echo "📥 필수 패키지 설치 중:$PACKAGES_TO_INSTALL"
    pkg update
    pkg install $PACKAGES_TO_INSTALL binutils
    
    if [ $? -ne 0 ]; then
        echo "❌ 패키지 설치 실패!"
        echo "💡 수동으로 설치해보세요:"
        echo "  pkg update && pkg upgrade"
        echo "  pkg install clang cmake make ninja git python binutils"
        exit 1
    fi
else
    echo "✅ 모든 필수 패키지가 설치되어 있습니다."
fi

# Snapdragon 8 Gen 3 CPU 기능 확인
echo ""
echo "💪 Snapdragon 8 Gen 3 기능 확인:"
if [ -f /proc/cpuinfo ]; then
    HAS_NEON=$(grep -q 'neon\|asimd' /proc/cpuinfo && echo "true" || echo "false")
    HAS_DOTPROD=$(grep -q 'asimddp\|dotprod' /proc/cpuinfo && echo "true" || echo "false")
    HAS_I8MM=$(grep -q 'i8mm' /proc/cpuinfo && echo "true" || echo "false")
    HAS_BF16=$(grep -q 'bf16' /proc/cpuinfo && echo "true" || echo "false")
    
    echo "  NEON: $HAS_NEON"
    echo "  DotProd: $HAS_DOTPROD"  
    echo "  I8MM: $HAS_I8MM"
    echo "  BF16: $HAS_BF16"
else
    echo "  ⚠️  CPU 기능 감지 실패"
    HAS_NEON="true"  # 기본값 설정
    HAS_DOTPROD="true"
    HAS_I8MM="true"
    HAS_BF16="true"
fi

# Termux 컴파일러 테스트
echo ""
echo "🔬 컴파일러 기능 테스트:"
echo "int main(){return 0;}" > test_compile.c

# ARMv9 지원 테스트
if clang -march=armv9-a test_compile.c -o test_armv9 2>/dev/null; then
    echo "  ✅ ARMv9 지원"
    ARCH_FLAGS="-march=armv9-a"
    rm -f test_armv9
elif clang -march=armv8.4-a+dotprod+i8mm test_compile.c -o test_armv8 2>/dev/null; then
    echo "  ✅ ARMv8.4 + extensions 지원"
    ARCH_FLAGS="-march=armv8.4-a+dotprod+i8mm"
    rm -f test_armv8
else
    echo "  ⚠️  기본 ARMv8 사용"
    ARCH_FLAGS="-march=armv8-a+dotprod"
fi

rm -f test_compile.c

# 빌드 디렉토리 설정
echo ""
echo "📁 빌드 디렉토리 설정..."
rm -rf build_termux_snapdragon
mkdir -p build_termux_snapdragon
cd build_termux_snapdragon

# Termux용 최적화 플래그
TERMUX_FLAGS="$ARCH_FLAGS -O3 -ffast-math -DANDROID -D__ANDROID__"

echo "🔧 Termux 최적화 플래그:"
echo "  $TERMUX_FLAGS"

# CMake 설정 (Termux용)
echo ""
echo "⚙️  CMake 설정 중..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DGGML_LLAMAFILE=ON \
    -DGGML_CPU_KLEIDIAI=ON \
    -DGGML_NATIVE=ON \
    -DGGML_CPU=ON \
    -DGGML_BACKEND_DL=OFF \
    -DGGML_NEON=ON \
    -DCMAKE_C_FLAGS="$TERMUX_FLAGS -DDEBUG_W4A8=1" \
    -DCMAKE_CXX_FLAGS="$TERMUX_FLAGS -DDEBUG_W4A8=1 -std=c++17" \
    -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY

if [ $? -ne 0 ]; then
    echo "❌ CMake 설정 실패!"
    echo ""
    echo "🔍 가능한 원인:"
    echo "  1. Termux 패키지 부족"
    echo "  2. 권한 문제"
    echo "  3. 저장 공간 부족"
    echo ""
    echo "💡 해결 방법:"
    echo "  termux-setup-storage  # 저장소 권한"
    echo "  pkg install cmake clang make ninja git"
    exit 1
fi

echo "✅ CMake 설정 완료"

# 빌드 실행
echo ""
echo "🔨 컴파일 중..."
echo "  사용 코어: $(nproc)"
echo "  예상 시간: 5-15분 (디바이스 성능에 따라)"

# Ninja 빌드 (더 빠름)
if command -v ninja >/dev/null 2>&1; then
    echo "  빌드 도구: Ninja"
    ninja -j$(nproc)
    BUILD_SUCCESS=$?
else
    echo "  빌드 도구: Make"
    make -j$(nproc)
    BUILD_SUCCESS=$?
fi

# 결과 확인
echo ""
echo "📋 빌드 결과:"
if [ $BUILD_SUCCESS -eq 0 ]; then
    echo "✅ Termux Snapdragon 8 Gen 3 빌드 성공!"
    
    if [ -f "bin/llama-cli" ]; then
        echo "📁 바이너리 위치: $(pwd)/bin/llama-cli"
        echo "📊 파일 크기: $(ls -lh bin/llama-cli | awk '{print $5}')"
        
        echo ""
        echo "🧪 W4A8 테스트 실행:"
        echo "  cd $(pwd)"
        echo "  ./bin/llama-cli -m your_Q4_0_model.gguf -p \"Hello Snapdragon\" -n 5"
        
        echo ""
        echo "📱 Termux W4A8 장점:"
        echo "  ⚡ Android 네이티브 성능"
        echo "  🎯 Snapdragon 8 Gen 3 최적화"
        echo "  💾 모바일 메모리 효율성"
        echo "  🔋 전력 효율적 추론"
    else
        echo "⚠️  바이너리 생성되지 않음"
    fi
else
    echo "❌ 빌드 실패!"
    echo ""
    echo "🔍 문제 해결 방법:"
    echo "  1. 저장 공간 확인: df -h"
    echo "  2. 메모리 확인: free -h"
    echo "  3. Termux 업데이트: pkg update && pkg upgrade"
    echo "  4. 재시도: rm -rf build_termux_snapdragon && ./build_termux_snapdragon.sh"
fi

echo ""
echo "💡 Termux 팁:"
echo "  • 백그라운드 실행: termux-wake-lock"
echo "  • 성능 모드: su -c 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'"
echo "  • 메모리 모니터링: top" 