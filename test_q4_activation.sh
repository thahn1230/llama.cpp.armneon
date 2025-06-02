#!/bin/bash

echo "🔍 === Q4_0 Weight Activation Debug Test ==="

# 1. 빌드 확인
if [ ! -f "./llama-cli" ]; then
    echo "📦 Building llama.cpp with debug output..."
    make clean
    make -j$(nproc) CFLAGS="-DGGML_USE_LLAMAFILE=1 -O2 -g" CXXFLAGS="-DGGML_USE_LLAMAFILE=1 -O2 -g"
fi

# 2. 테스트 모델 확인
TEST_MODEL="models/test_q4_0.gguf"
if [ ! -f "$TEST_MODEL" ]; then
    echo "❌ Q4_0 테스트 모델이 필요합니다."
    echo "   사용법:"
    echo "   1. 모델 다운로드: huggingface-cli download microsoft/DialoGPT-small ggml-model-f16.gguf"
    echo "   2. Q4_0 변환: ./llama-quantize ggml-model-f16.gguf $TEST_MODEL Q4_0"
    exit 1
fi

# 3. 환경 변수 설정
export GGML_USE_LLAMAFILE=1
export GGML_DEBUG=1

# 4. Q4_0 activation 디버그 테스트
echo ""
echo "🚀 Testing Q4_0 weight with activation quantization debug..."
echo "   Model: $TEST_MODEL"
echo "   Input: 'Hello'"
echo ""

# 디버그 출력을 캡처하기 위해 파일로 저장
./llama-cli -m "$TEST_MODEL" -p "Hello" -n 1 --temp 0 2>&1 | tee debug_output.log

echo ""
echo "📊 === Debug Output Analysis ==="
echo ""

# 중요한 디버그 정보 추출
echo "🔍 Q4_0 Weight Processing:"
grep -A 10 "Q4_0 WEIGHT PROCESSING DEBUG" debug_output.log || echo "   No Q4_0 processing found"

echo ""
echo "📊 F32 → Q8_0 Quantization:"
grep -A 15 "F32 → Q8_0 QUANTIZATION PROCESS" debug_output.log || echo "   No quantization debug found"

echo ""
echo "🚀 SGEMM Kernel Usage:"
grep -A 10 "Q4_0 WEIGHT DEBUG" debug_output.log || echo "   No SGEMM debug found"

echo ""
echo "📁 Full debug log saved to: debug_output.log"
echo "   Use 'cat debug_output.log' to see complete output"

echo ""
echo "✅ Q4_0 activation debug test completed!" 