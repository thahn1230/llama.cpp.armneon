#!/bin/bash

# KleidiAI 링킹 문제 진단 스크립트

echo "🔍 KleidiAI 링킹 문제 진단"
echo "=========================="

# 빌드 디렉토리 확인
if [ -d "build_termux_snapdragon_fixed" ]; then
    echo "✅ 빌드 디렉토리 발견: build_termux_snapdragon_fixed"
    cd build_termux_snapdragon_fixed
else
    echo "❌ 빌드 디렉토리 없음"
    exit 1
fi

echo ""
echo "🔬 KleidiAI 다운로드 상태 확인:"

# KleidiAI 소스 확인
if [ -d "_deps/kleidiai_download-src" ]; then
    echo "  ✅ KleidiAI 소스 다운로드됨"
    
    KLEIDIAI_DIR="_deps/kleidiai_download-src"
    echo "  📁 위치: $KLEIDIAI_DIR"
    
    # 주요 파일 확인
    if [ -f "$KLEIDIAI_DIR/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qsi4c32p/kai_matmul_clamp_f32_qsi8d32p4x4_qsi4c32p4x4_16x4_neon_dotprod.c" ]; then
        echo "  ✅ DotProd 커널 파일 존재"
    else
        echo "  ❌ DotProd 커널 파일 없음"
    fi
    
    # 라이브러리 파일 확인
    echo ""
    echo "🔍 KleidiAI 라이브러리 확인:"
    
    KLEIDIAI_LIBS=$(find . -name "*kleidiai*" -o -name "*kai*" | head -10)
    if [ -n "$KLEIDIAI_LIBS" ]; then
        echo "  발견된 KleidiAI 관련 파일:"
        echo "$KLEIDIAI_LIBS"
    else
        echo "  ❌ KleidiAI 라이브러리 파일 없음"
    fi
    
else
    echo "  ❌ KleidiAI 소스 다운로드 실패"
fi

echo ""
echo "🔧 CMake 설정 확인:"

if [ -f "CMakeCache.txt" ]; then
    echo "  ✅ CMakeCache.txt 존재"
    
    # KleidiAI 관련 설정 확인
    if grep -q "GGML_CPU_KLEIDIAI:BOOL=ON" CMakeCache.txt; then
        echo "  ✅ GGML_CPU_KLEIDIAI=ON"
    else
        echo "  ❌ GGML_CPU_KLEIDIAI=OFF 또는 설정 없음"
    fi
    
    # 컴파일러 플래그 확인
    echo "  📋 컴파일러 플래그:"
    grep "CMAKE_C_FLAGS" CMakeCache.txt | head -1
    
else
    echo "  ❌ CMakeCache.txt 없음"
fi

echo ""
echo "⚠️  링킹 오류 분석:"
echo "  문제: KleidiAI 함수들이 정의되지 않음"
echo "  원인: KleidiAI 라이브러리가 제대로 빌드되지 않음"

echo ""
echo "🔧 해결 방법:"
echo "  1. 안전한 빌드 (권장):"
echo "     ./build_termux_snapdragon_safe.sh"
echo ""
echo "  2. KleidiAI 수동 해결:"
echo "     - KleidiAI 소스를 수동으로 컴파일"
echo "     - 정적 라이브러리로 링크"
echo ""
echo "  3. 기본 ARM 최적화 사용:"
echo "     - GGML_CPU_KLEIDIAI=OFF"
echo "     - GGML_NEON=ON"
echo "     - ARM DotProd 최적화 유지"

echo ""
echo "💡 W4A8 동작 방식:"
echo "  - KleidiAI 없어도 W4A8 기능 작동"
echo "  - ARM NEON으로 기본 최적화"
echo "  - 성능 차이: ~10-20% (KleidiAI 대비)"
echo "  - 안정성: 훨씬 높음"

# 시스템 리소스 확인
echo ""
echo "📊 시스템 리소스:"
echo "  메모리 사용량:"
free -h | grep -E "Mem|Swap" || echo "    확인 불가"

echo "  저장 공간:"
df -h . | tail -1 || echo "    확인 불가"

echo ""
echo "🚀 권장 다음 단계:"
echo "  1. rm -rf build_termux_snapdragon_fixed"
echo "  2. ./build_termux_snapdragon_safe.sh"
echo "  3. 빌드 성공 후 Q4_0 모델로 테스트" 