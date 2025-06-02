#!/bin/bash

# Snapdragon 8 Gen 3 빌드 환경 진단 스크립트

echo "🔍 Snapdragon 8 Gen 3 빌드 환경 진단"
echo "===================================="

# 1. 시스템 기본 정보
echo ""
echo "📱 시스템 정보:"
echo "  Architecture: $(uname -m)"
echo "  Kernel: $(uname -r)"
echo "  OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo 'Unknown')"

# 2. Android 환경 확인
echo ""
echo "🤖 Android 환경 확인:"
if [ -d "/system" ] && [ -f "/system/build.prop" ]; then
    echo "  ✅ Android 환경 감지"
    
    # Android 버전 확인
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    echo "  Android 버전: $ANDROID_VERSION"
    
    # Snapdragon 정보
    SOC_MODEL=$(getprop ro.board.platform 2>/dev/null || echo "Unknown")
    echo "  SoC: $SOC_MODEL"
    
    # Termux 확인
    if [ "$PREFIX" ]; then
        echo "  ✅ Termux 환경: $PREFIX"
        TERMUX_ENV=true
    else
        echo "  ❌ 표준 Linux 도구 필요 (Termux 권장)"
        TERMUX_ENV=false
    fi
else
    echo "  ✅ 표준 Linux 환경"
    TERMUX_ENV=false
fi

# 3. 컴파일러 확인
echo ""
echo "🔧 컴파일러 확인:"
if command -v gcc >/dev/null 2>&1; then
    echo "  ✅ GCC: $(gcc --version | head -1)"
    GCC_AVAILABLE=true
else
    echo "  ❌ GCC 없음"
    GCC_AVAILABLE=false
fi

if command -v clang >/dev/null 2>&1; then
    echo "  ✅ Clang: $(clang --version | head -1)"
    CLANG_AVAILABLE=true
else
    echo "  ❌ Clang 없음"
    CLANG_AVAILABLE=false
fi

if command -v g++ >/dev/null 2>&1; then
    echo "  ✅ G++: $(g++ --version | head -1)"
    CPP_AVAILABLE=true
else
    echo "  ❌ G++ 없음"
    CPP_AVAILABLE=false
fi

# 4. 빌드 도구 확인
echo ""
echo "🛠️  빌드 도구 확인:"
if command -v cmake >/dev/null 2>&1; then
    echo "  ✅ CMake: $(cmake --version | head -1)"
    CMAKE_AVAILABLE=true
else
    echo "  ❌ CMake 없음"
    CMAKE_AVAILABLE=false
fi

if command -v make >/dev/null 2>&1; then
    echo "  ✅ Make: $(make --version | head -1)"
    MAKE_AVAILABLE=true
else
    echo "  ❌ Make 없음"  
    MAKE_AVAILABLE=false
fi

if command -v ninja >/dev/null 2>&1; then
    echo "  ✅ Ninja: $(ninja --version)"
    NINJA_AVAILABLE=true
else
    echo "  ❌ Ninja 없음"
    NINJA_AVAILABLE=false
fi

# 5. CPU 기능 확인
echo ""
echo "💪 ARM CPU 기능 확인:"
if [ -f /proc/cpuinfo ]; then
    echo "  NEON: $(grep -q 'neon\|asimd' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  DotProd: $(grep -q 'asimddp\|dotprod' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  I8MM: $(grep -q 'i8mm' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  SVE: $(grep -q 'sve' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  BF16: $(grep -q 'bf16' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
else
    echo "  ❌ /proc/cpuinfo 읽기 실패"
fi

# 6. 환경 진단 및 해결책 제시
echo ""
echo "🎯 환경 진단 결과:"

if [ "$TERMUX_ENV" = true ]; then
    echo "  환경: Termux (Android)"
    
    if [ "$CMAKE_AVAILABLE" = false ] || [ "$GCC_AVAILABLE" = false ]; then
        echo ""
        echo "💡 Termux 패키지 설치 필요:"
        echo "  pkg update && pkg upgrade"
        echo "  pkg install cmake clang make ninja git python"
        echo "  pkg install binutils"
    fi
    
    echo ""
    echo "🚀 Termux용 최적화된 빌드 방법:"
    echo "  1. 패키지 설치 후"
    echo "  2. ./build_termux_snapdragon.sh 실행"
    
elif [ "$CMAKE_AVAILABLE" = false ] || [ "$GCC_AVAILABLE" = false ]; then
    echo "  환경: Linux (빌드 도구 부족)"
    echo ""
    echo "💡 필수 패키지 설치:"
    echo "  # Ubuntu/Debian:"
    echo "  sudo apt update && sudo apt install -y build-essential cmake ninja-build"
    echo "  # CentOS/RHEL:"
    echo "  sudo yum groupinstall 'Development Tools' && sudo yum install cmake ninja-build"
    echo "  # Arch Linux:"
    echo "  sudo pacman -S base-devel cmake ninja"
    
else
    echo "  환경: Linux (빌드 준비 완료)"
    echo ""
    echo "🚀 빌드 가능! 다음 명령어 실행:"
    echo "  ./build_snapdragon8gen3_w4a8.sh"
fi

# 7. ARMv9 컴파일러 지원 확인
echo ""
echo "🔬 ARMv9 컴파일러 지원 테스트:"
if [ "$GCC_AVAILABLE" = true ]; then
    echo "int main(){return 0;}" > test_armv9.c
    if gcc -march=armv9-a test_armv9.c -o test_armv9 2>/dev/null; then
        echo "  ✅ ARMv9 지원됨"
        rm -f test_armv9 test_armv9.c
        ARMV9_SUPPORT=true
    else
        echo "  ❌ ARMv9 미지원 (ARMv8 사용)"
        rm -f test_armv9 test_armv9.c
        ARMV9_SUPPORT=false
    fi
else
    ARMV9_SUPPORT=false
fi

echo ""
echo "📋 권장 빌드 전략:"
if [ "$TERMUX_ENV" = true ]; then
    echo "  🎯 Termux 최적화 빌드 사용"
elif [ "$ARMV9_SUPPORT" = false ]; then
    echo "  🎯 ARMv8 호환 빌드 사용"
else
    echo "  🎯 ARMv9 네이티브 빌드 사용"
fi 