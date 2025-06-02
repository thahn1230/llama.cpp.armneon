#!/bin/bash

# ARM W4A8 성능 벤치마크 스크립트

echo "🏁 ARM W4A8 성능 벤치마크"
echo "========================"

MODEL_FILE="${1:-models/llama2-7b/llama2-7B-hf-Q4_0.gguf}"

if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ 모델 파일을 찾을 수 없습니다: $MODEL_FILE"
    echo "사용법: $0 <model_file.gguf>"
    exit 1
fi

BUILD_PATH="build_arm/bin/llama-cli"
if [ ! -f "$BUILD_PATH" ]; then
    BUILD_PATH="llama-cli-arm"
fi

echo "📁 모델: $MODEL_FILE"
echo "🔧 바이너리: $BUILD_PATH"
echo ""

# 벤치마크 실행
echo "🧪 W4A8 추론 성능 측정 중..."

# 1. 짧은 텍스트 생성 (속도 측정)
echo "1️⃣ 짧은 생성 (50 토큰):"
time $BUILD_PATH -m "$MODEL_FILE" -p "The future of AI is" -n 50 --no-warmup -t 1 2>&1 | \
    grep -E "(tokens per second|🎯 W4A8|total time)"

echo ""

# 2. 중간 길이 생성 (처리량 측정)  
echo "2️⃣ 중간 생성 (200 토큰):"
time $BUILD_PATH -m "$MODEL_FILE" -p "Artificial intelligence will revolutionize" -n 200 --no-warmup -t 1 2>&1 | \
    grep -E "(tokens per second|🎯 W4A8|total time)"

echo ""

# 3. 메모리 사용량 측정
echo "3️⃣ 메모리 사용량 측정:"
if command -v /usr/bin/time >/dev/null 2>&1; then
    /usr/bin/time -v $BUILD_PATH -m "$MODEL_FILE" -p "Memory test" -n 10 --no-warmup 2>&1 | \
        grep -E "(Maximum resident set size|🎯 W4A8)"
else
    echo "⚠️  GNU time 사용할 수 없음. 메모리 측정 생략."
fi

echo ""
echo "🎯 W4A8 장점:"
echo "  ⚡ 메모리: Q4_0 weight (4bit) + Q8_0 activation (8bit)"
echo "  🚀 속도: INT8 GEMM 연산 활용"
echo "  🎯 정확도: FP32 수준 유지"
echo ""
echo "📊 더 자세한 분석:"
echo "  tail -f w4a8_test_output.log" 