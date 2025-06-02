#!/bin/bash

# ARM64 크로스 컴파일 환경 설정 스크립트
echo "🔧 ARM64 크로스 컴파일 환경 설정..."

# 시스템 확인
if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "❌ 이 스크립트는 x86_64 호스트에서 실행되어야 합니다."
    exit 1
fi

# 크로스 컴파일 도구체인 설치 확인
echo "📦 크로스 컴파일 도구체인 확인 중..."

if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    echo "✅ aarch64-linux-gnu-gcc 이미 설치됨"
else
    echo "📥 aarch64 크로스 컴파일러 설치 중..."
    
    # Ubuntu/Debian 계열
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
    
    # CentOS/RHEL 계열  
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
    
    # Arch Linux
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S aarch64-linux-gnu-gcc
    
    else
        echo "❌ 지원되지 않는 패키지 매니저입니다."
        echo "수동으로 aarch64-linux-gnu-gcc를 설치해주세요."
        exit 1
    fi
fi

# 크로스 컴파일 도구체인 확인
echo ""
echo "🔍 설치된 크로스 컴파일러:"
aarch64-linux-gnu-gcc --version | head -1
aarch64-linux-gnu-g++ --version | head -1

# 크로스 컴파일 CMake 설정 파일 생성
echo ""
echo "📝 ARM64 크로스 컴파일 CMake 툴체인 생성..."

cat > cmake_toolchain_aarch64.cmake << 'EOF'
# ARM64 크로스 컴파일 CMake 툴체인

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# 크로스 컴파일러 설정
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# 타겟 시스템 루트 경로
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)

# 프로그램, 라이브러리, 헤더 찾기 설정
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Snapdragon 8 Gen 3 최적화 플래그
set(SNAPDRAGON_FLAGS "-march=armv9-a+sve+i8mm+bf16+dotprod -mtune=cortex-x4 -O3 -ffast-math")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SNAPDRAGON_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SNAPDRAGON_FLAGS}")
EOF

echo "✅ cmake_toolchain_aarch64.cmake 생성 완료"

# 크로스 컴파일 빌드 스크립트 생성
echo ""
echo "📝 크로스 컴파일 빌드 스크립트 생성..."

cat > build_cross_snapdragon.sh << 'EOF'
#!/bin/bash

echo "🚀 Snapdragon 8 Gen 3 크로스 컴파일 빌드..."

# 빌드 디렉토리 설정
rm -rf build_cross_arm64
mkdir -p build_cross_arm64
cd build_cross_arm64

# 크로스 컴파일 CMake 설정
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=../cmake_toolchain_aarch64.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_LLAMAFILE=ON \
    -DLLAMA_NATIVE=ON \
    -DGGML_CPU_KLEIDIAI=ON \
    -DGGML_NATIVE=ON \
    -DGGML_CPU=ON \
    -DGGML_SVE=ON \
    -DGGML_NEON=ON \
    -DDEBUG_W4A8=1

echo "🔨 크로스 컴파일 중..."
make -j$(nproc)

if [ $? -eq 0 ]; then
    echo "✅ 크로스 컴파일 성공!"
    echo "📁 바이너리 위치: build_cross_arm64/bin/"
    echo "📱 Snapdragon 8 Gen 3 디바이스로 복사하여 실행하세요"
    
    echo ""
    echo "📋 파일 복사 명령어 예시:"
    echo "  scp build_cross_arm64/bin/llama-cli user@device:/path/to/destination/"
    echo "  adb push build_cross_arm64/bin/llama-cli /data/local/tmp/"
else
    echo "❌ 크로스 컴파일 실패!"
fi
EOF

chmod +x build_cross_snapdragon.sh

echo ""
echo "✅ 크로스 컴파일 환경 설정 완료!"
echo ""
echo "🎯 사용 방법:"
echo "  1. 현재 환경에서 크로스 컴파일: ./build_cross_snapdragon.sh"
echo "  2. Snapdragon 8 Gen 3 디바이스로 바이너리 복사"
echo "  3. 디바이스에서 W4A8 테스트 실행"
echo ""
echo "💡 Android 디바이스인 경우:"
echo "  adb push build_cross_arm64/bin/llama-cli /data/local/tmp/"
echo "  adb shell 'cd /data/local/tmp && ./llama-cli -m model.gguf -p \"test\" -n 5'"
EOF 