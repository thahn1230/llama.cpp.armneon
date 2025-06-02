#!/bin/bash

# ARM W4A8 테스트 스크립트

echo "🎯 ARM W4A8 종합 테스트 스크립트"
echo "=================================="

# 시스템 정보 확인
echo ""
echo "📱 시스템 정보:"
echo "  Architecture: $(uname -m)"
echo "  CPU info:"
lscpu | grep -E "(Architecture|Model name|CPU\(s\)|Thread|Core)" | head -6

echo ""
echo "🔍 ARM CPU 기능 확인:"
if [ -f /proc/cpuinfo ]; then
    echo "  NEON support: $(grep -q 'neon' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  DOTPROD support: $(grep -q 'asimddp\|dotprod' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
    echo "  I8MM support: $(grep -q 'i8mm' /proc/cpuinfo && echo '✅ Yes' || echo '❌ No')"
else
    echo "  /proc/cpuinfo not available"
fi

# 빌드 확인
echo ""
echo "🔨 빌드 파일 확인:"
if [ -f "build_arm/bin/llama-cli" ]; then
    echo "  ✅ build_arm/bin/llama-cli found"
    BUILD_PATH="build_arm/bin/llama-cli"
elif [ -f "llama-cli-arm" ]; then
    echo "  ✅ llama-cli-arm found"
    BUILD_PATH="llama-cli-arm"
else
    echo "  ❌ No ARM build found!"
    echo ""
    echo "🔧 빌드 명령어:"
    echo "  1. CMake 방법: chmod +x build_arm_w4a8.sh && ./build_arm_w4a8.sh"
    echo "  2. Makefile 방법: make -f Makefile.arm"
    exit 1
fi

# 모델 파일 확인
echo ""
echo "📁 Q4_0 모델 파일 확인:"
MODEL_FILE=""
for model in models/*Q4_0*.gguf models/*/*Q4_0*.gguf *.gguf */*Q4_0*.gguf; do
    if [ -f "$model" ]; then
        echo "  ✅ Found: $model"
        MODEL_FILE="$model"
        break
    fi
done

if [ -z "$MODEL_FILE" ]; then
    echo "  ❌ No Q4_0 model found!"
    echo ""
    echo "💡 Q4_0 모델 생성 방법:"
    echo "  1. HuggingFace에서 다운로드:"
    echo "     huggingface-cli download microsoft/DialoGPT-medium --local-dir DialoGPT-medium"
    echo "  2. GGUF로 변환:"
    echo "     python convert_hf_to_gguf.py DialoGPT-medium --outtype Q4_0"
    echo "  또는 기존 모델을 quantize:"
    echo "     ./build_arm/bin/llama-quantize input.gguf output_Q4_0.gguf Q4_0"
    exit 1
fi

# W4A8 테스트 실행
echo ""
echo "🧪 W4A8 커널 테스트 실행:"
echo "  Model: $MODEL_FILE"
echo "  Command: $BUILD_PATH -m \"$MODEL_FILE\" -p \"Hello World\" -n 3 --no-warmup"
echo ""
echo "📊 예상 출력:"
echo "  🎯 W4A8 KERNEL: ggml_vec_dot_q4_0_q8_0 called! n=XXX"
echo ""
echo "🚀 실행 중..."
echo "=================================="

# 실제 테스트 실행
$BUILD_PATH -m "$MODEL_FILE" -p "Hello World" -n 3 --no-warmup 2>&1 | tee w4a8_test_output.log

echo ""
echo "=================================="
echo "📋 결과 분석:"

# W4A8 커널 호출 확인
if grep -q "🎯 W4A8 KERNEL" w4a8_test_output.log; then
    echo "  ✅ W4A8 커널이 성공적으로 호출되었습니다!"
    W4A8_CALLS=$(grep "🎯 W4A8 KERNEL" w4a8_test_output.log | wc -l)
    echo "  📊 W4A8 커널 호출 횟수: $W4A8_CALLS"
else
    echo "  ❌ W4A8 커널이 호출되지 않았습니다."
    echo ""
    echo "🔍 가능한 원인:"
    echo "  1. KleidiAI가 비활성화되어 있음"
    echo "  2. ARM CPU 기능 부족 (dotprod, i8mm 필요)"
    echo "  3. 컴파일 플래그 누락"
    echo "  4. 모델이 자동으로 dequantize됨"
fi

# 실행 로그 확인
if grep -q "🔍" w4a8_test_output.log; then
    echo ""
    echo "📊 텐서 타입 분석:"
    grep "🔍" w4a8_test_output.log | sort | uniq -c | head -10
fi

echo ""
echo "💾 전체 로그가 w4a8_test_output.log에 저장되었습니다."
echo ""
echo "🎯 성공 시 W4A8 Benefits:"
echo "  ⚡ 메모리 사용량 50% 감소"
echo "  🚀 INT8 연산으로 속도 향상"
echo "  🎯 정확도 유지" 