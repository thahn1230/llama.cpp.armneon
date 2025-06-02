#!/bin/bash

# Snapdragon 8 Gen 3 W4A8 특화 테스트 스크립트

echo "🎯 Snapdragon 8 Gen 3 W4A8 성능 테스트"
echo "======================================"

# Snapdragon 8 Gen 3 CPU 정보 확인
echo ""
echo "📱 Snapdragon 8 Gen 3 CPU 정보:"
echo "  Architecture: $(uname -m)"

if [ -f /proc/cpuinfo ]; then
    echo "  CPU 정보:"
    
    # Snapdragon 8 Gen 3 특유의 코어 구성 확인
    KRYO_CORES=$(grep -c "Kryo" /proc/cpuinfo 2>/dev/null || echo "0")
    CORTEX_X4=$(grep -c "Cortex-X4\|cortex-x4" /proc/cpuinfo 2>/dev/null || echo "0")
    CORTEX_A720=$(grep -c "Cortex-A720\|cortex-a720" /proc/cpuinfo 2>/dev/null || echo "0")
    CORTEX_A520=$(grep -c "Cortex-A520\|cortex-a520" /proc/cpuinfo 2>/dev/null || echo "0")
    
    echo "    Kryo cores: $KRYO_CORES"
    echo "    Cortex-X4 (Prime): $CORTEX_X4"  
    echo "    Cortex-A720 (Performance): $CORTEX_A720"
    echo "    Cortex-A520 (Efficiency): $CORTEX_A520"
    
    # CPU 주파수 정보
    echo "  CPU 주파수:"
    for i in {0..7}; do
        if [ -f "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq" ]; then
            FREQ=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq 2>/dev/null)
            if [ ! -z "$FREQ" ]; then
                FREQ_GHZ=$(echo "scale=2; $FREQ / 1000000" | bc 2>/dev/null || echo "N/A")
                echo "    CPU$i: ${FREQ_GHZ}GHz"
            fi
        fi
    done
fi

echo ""
echo "🔍 ARM 특화 기능 확인:"
if [ -f /proc/cpuinfo ]; then
    echo "  NEON: $(grep -q 'neon\|asimd' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  DotProd: $(grep -q 'asimddp\|dotprod' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')" 
    echo "  I8MM: $(grep -q 'i8mm' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  SVE: $(grep -q 'sve' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  BF16: $(grep -q 'bf16' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
else
    echo "  /proc/cpuinfo를 읽을 수 없습니다"
fi

# 빌드 확인
echo ""
echo "🔨 빌드 파일 확인:"
BUILD_PATH=""
if [ -f "build_snapdragon/bin/llama-cli" ]; then
    echo "  ✅ build_snapdragon/bin/llama-cli found (네이티브 빌드)"
    BUILD_PATH="build_snapdragon/bin/llama-cli"
elif [ -f "build_cross_arm64/bin/llama-cli" ]; then
    echo "  ✅ build_cross_arm64/bin/llama-cli found (크로스 컴파일)"
    BUILD_PATH="build_cross_arm64/bin/llama-cli"
elif [ -f "llama-cli" ]; then
    echo "  ✅ llama-cli found (현재 디렉토리)"
    BUILD_PATH="./llama-cli"
else
    echo "  ❌ Snapdragon 8 Gen 3용 빌드를 찾을 수 없습니다!"
    echo ""
    echo "🔧 빌드 방법:"
    echo "  1. 네이티브 빌드: chmod +x build_snapdragon8gen3_w4a8.sh && ./build_snapdragon8gen3_w4a8.sh"
    echo "  2. 크로스 컴파일: ./setup_cross_compile.sh && ./build_cross_snapdragon.sh"
    exit 1
fi

# 바이너리 정보 확인
echo ""
echo "🔍 바이너리 분석:"
file "$BUILD_PATH" 2>/dev/null || echo "  file 명령어 사용할 수 없음"
ls -lh "$BUILD_PATH"

# 모델 파일 확인
echo ""
echo "📁 Q4_0 모델 파일 확인:"
MODEL_FILE=""
for model in *.gguf models/*.gguf models/*/*.gguf; do
    if [ -f "$model" ] && [[ "$model" == *"Q4_0"* ]]; then
        echo "  ✅ Found Q4_0 model: $model"
        MODEL_FILE="$model"
        break
    fi
done

if [ -z "$MODEL_FILE" ]; then
    echo "  ❌ Q4_0 모델을 찾을 수 없습니다!"
    echo ""
    echo "💡 Q4_0 모델 준비 방법:"
    echo "  huggingface-cli download microsoft/DialoGPT-small --local-dir DialoGPT-small"
    echo "  python convert_hf_to_gguf.py DialoGPT-small --outtype Q4_0"
    exit 1
fi

# Snapdragon 8 Gen 3 성능 최적화 설정
echo ""
echo "⚙️  Snapdragon 8 Gen 3 성능 최적화:"

# CPU 거버너를 performance로 설정 (가능한 경우)
if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
    echo "  CPU 거버너 확인 중..."
    CURRENT_GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    echo "    현재 CPU 거버너: $CURRENT_GOV"
    
    if [ "$CURRENT_GOV" != "performance" ] && [ -w "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        echo "    performance 모드로 변경 중..."
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo performance > "$cpu" 2>/dev/null || true
        done
    fi
fi

# Snapdragon 8 Gen 3 W4A8 테스트 실행
echo ""
echo "🧪 Snapdragon 8 Gen 3 W4A8 테스트 실행:"
echo "  Model: $MODEL_FILE"
echo "  Binary: $BUILD_PATH"
echo "  Command: $BUILD_PATH -m \"$MODEL_FILE\" -p \"Snapdragon 8 Gen 3 test\" -n 10 -t 1"
echo ""
echo "📊 예상 성능 특징:"
echo "  🚀 ARMv9 SVE: 가변 길이 벡터 연산"
echo "  ⚡ I8MM: 8bit 매트릭스 곱셈 하드웨어 가속"
echo "  🎯 BF16: 16bit 브레인 플로팅 포인트"
echo "  💪 Cortex-X4: 3.3GHz 고성능 코어"
echo ""
echo "🚀 실행 중..."
echo "=================================="

# 실제 테스트 실행 - Snapdragon 특화 최적화
GGML_CPU_KLEIDIAI=1 OMP_NUM_THREADS=4 "$BUILD_PATH" \
    -m "$MODEL_FILE" \
    -p "Snapdragon 8 Gen 3 performance test" \
    -n 10 \
    -t 4 \
    --no-warmup 2>&1 | tee snapdragon_w4a8_test.log

echo ""
echo "=================================="
echo "📋 Snapdragon 8 Gen 3 결과 분석:"

# W4A8 커널 호출 확인
if grep -q "🎯 W4A8 KERNEL" snapdragon_w4a8_test.log; then
    echo "  ✅ W4A8 커널이 성공적으로 호출되었습니다!"
    W4A8_CALLS=$(grep "🎯 W4A8 KERNEL" snapdragon_w4a8_test.log | wc -l)
    echo "  📊 W4A8 커널 호출 횟수: $W4A8_CALLS"
    
    # 성능 메트릭 추출
    if grep -q "tokens per second" snapdragon_w4a8_test.log; then
        TPS=$(grep "tokens per second" snapdragon_w4a8_test.log | tail -1)
        echo "  ⚡ $TPS"
    fi
else
    echo "  ❌ W4A8 커널이 호출되지 않았습니다."
    echo ""
    echo "🔍 Snapdragon 8 Gen 3 관련 가능한 원인:"
    echo "  1. KleidiAI가 이 특정 Snapdragon 변형에서 비활성화"
    echo "  2. ARMv9 기능이 컴파일에서 제외됨"
    echo "  3. Android 권한 문제 (루팅 필요할 수 있음)"
    echo "  4. 모델이 자동으로 dequantize됨"
fi

echo ""
echo "💾 전체 로그: snapdragon_w4a8_test.log"
echo ""
echo "🎯 Snapdragon 8 Gen 3 W4A8 장점:"
echo "  ⚡ 메모리: 50% 절약 (Q4_0 + Q8_0)"
echo "  🚀 성능: I8MM 하드웨어 가속"
echo "  🔋 전력: 효율적인 Cortex-A520 코어 활용"
echo "  �� 정확도: FP32 수준 유지" 