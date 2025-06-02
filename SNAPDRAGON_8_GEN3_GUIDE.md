# 🚀 Snapdragon 8 Gen 3 W4A8 완전 가이드

Qualcomm Snapdragon 8 Gen 3에서 llama.cpp W4A8 (4bit weights + 8bit activations) 최적화 빌드 가이드

## 📱 지원 환경

### ✅ Snapdragon 8 Gen 3 디바이스
- **스마트폰**: Galaxy S24 Ultra, OnePlus 12, Xiaomi 14 Pro 등
- **태블릿**: Galaxy Tab S9 Ultra 등  
- **개발보드**: QRB5165, QCS8550 등
- **노트북**: ARM-based Windows/Linux

### 🏗️ 아키텍처 특징
- **CPU**: 1x Cortex-X4 (3.3GHz) + 3x Cortex-A720 (3.2GHz) + 4x Cortex-A520 (2.3GHz)
- **ISA**: ARMv9-A architecture
- **특화 기능**: SVE, I8MM, BF16, DotProd
- **메모리**: LPDDR5X (최대 4800MHz)

## 🛠️ 1단계: 환경 진단

먼저 현재 환경을 진단하세요:

```bash
# 환경 진단 스크립트 실행
chmod +x check_snapdragon_env.sh
./check_snapdragon_env.sh
```

## 🎯 2단계: 빌드 방법 선택

진단 결과에 따라 적절한 빌드 방법을 선택하세요:

### 📱 A. Android (Termux) 환경

**Termux 설치 및 설정:**
```bash
# Termux 앱 설치 후
pkg update && pkg upgrade
pkg install cmake clang make ninja git python binutils

# W4A8 빌드 실행
chmod +x build_termux_snapdragon.sh
./build_termux_snapdragon.sh
```

### 🐧 B. Linux 네이티브 환경

**필수 패키지 설치:**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y build-essential cmake ninja-build

# 최적화 빌드 (ARMv9 지원시)
chmod +x build_snapdragon8gen3_w4a8.sh
./build_snapdragon8gen3_w4a8.sh

# 호환 빌드 (ARMv9 미지원시)
chmod +x build_snapdragon_armv8_compat.sh
./build_snapdragon_armv8_compat.sh
```

### 💻 C. 크로스 컴파일 (x86_64 → ARM64)

**개발 PC에서 빌드:**
```bash
# 크로스 컴파일 환경 설정
chmod +x setup_cross_compile.sh
./setup_cross_compile.sh

# Snapdragon용 크로스 빌드
./build_cross_snapdragon.sh

# 디바이스로 복사
adb push build_cross_arm64/bin/llama-cli /data/local/tmp/
# 또는
scp build_cross_arm64/bin/llama-cli user@device:/path/to/destination/
```

## 🧪 3단계: W4A8 테스트

### Q4_0 모델 준비

```bash
# HuggingFace에서 소형 모델 다운로드
huggingface-cli download microsoft/DialoGPT-small --local-dir DialoGPT-small

# GGUF Q4_0로 변환
python convert_hf_to_gguf.py DialoGPT-small --outtype Q4_0

# 또는 기존 모델 quantize
./bin/llama-quantize input.gguf output_Q4_0.gguf Q4_0
```

### W4A8 성능 테스트

```bash
# Snapdragon 8 Gen 3 특화 테스트
chmod +x test_snapdragon8gen3_w4a8.sh
./test_snapdragon8gen3_w4a8.sh

# 또는 직접 실행
GGML_CPU_KLEIDIAI=1 ./bin/llama-cli \
    -m your_model_Q4_0.gguf \
    -p "Snapdragon 8 Gen 3 performance test" \
    -n 20 \
    -t 4
```

### 성공 확인

W4A8가 제대로 작동하면 다음과 같은 로그가 출력됩니다:
```
🎯 W4A8 KERNEL: ggml_vec_dot_q4_0_q8_0 called! n=4096
```

## 📊 4단계: 성능 벤치마크

```bash
# 성능 측정 스크립트
chmod +x benchmark_w4a8_arm.sh
./benchmark_w4a8_arm.sh your_model_Q4_0.gguf
```

## ⚙️ 최적화 설정

### CPU 성능 모드

```bash
# 성능 거버너 설정 (루트 권한 필요)
su -c 'for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > "$cpu"
done'

# 또는 Termux에서
su -c 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
```

### 환경 변수 최적화

```bash
# KleidiAI W4A8 활성화
export GGML_CPU_KLEIDIAI=1

# 스레드 수 최적화 (Snapdragon 8 Gen 3)
export OMP_NUM_THREADS=4

# 메모리 정렬 최적화  
export GGML_FORCE_CPU=1
```

### Termux 특화 최적화

```bash
# 백그라운드 실행 방지
termux-wake-lock

# 저장소 권한 (모델 파일 접근)
termux-setup-storage

# 성능 모니터링
top -d 1
```

## 🔍 문제 해결

### 빌드 실패

**증상**: CMake 설정 실패
```bash
# 해결방법
pkg update && pkg upgrade  # Termux
sudo apt update && sudo apt install build-essential cmake  # Linux
```

**증상**: 컴파일러 오류 (ARMv9 미지원)
```bash
# ARMv8 호환 빌드 사용
./build_snapdragon_armv8_compat.sh
```

**증상**: 메모리 부족
```bash
# 단일 코어 빌드
make -j1
# 또는 스왑 설정 (Linux)
sudo fallocate -l 2G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### W4A8 미작동

**증상**: 🎯 W4A8 KERNEL 로그 없음
```bash
# 1. KleidiAI 환경변수 확인
export GGML_CPU_KLEIDIAI=1

# 2. Q4_0 모델 확인
file your_model.gguf | grep Q4_0

# 3. CPU 기능 확인
grep -E 'i8mm|dotprod' /proc/cpuinfo

# 4. 디버그 빌드로 재컴파일
cmake .. -DDEBUG_W4A8=1
```

### 성능 이슈

**증상**: 느린 추론 속도
```bash
# CPU 거버너 확인
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 온도 쓰로틀링 확인
cat /sys/class/thermal/thermal_zone*/temp

# 메모리 사용량 확인
free -h
```

## 📈 예상 성능

### Snapdragon 8 Gen 3 W4A8 벤치마크

| 모델 크기 | 메모리 사용량 | 토큰/초 (W4A8) | 토큰/초 (FP16) | 개선율 |
|----------|-------------|---------------|---------------|---------|
| 1B       | ~1.2GB      | 45-60         | 35-45         | +30%    |
| 3B       | ~2.8GB      | 25-35         | 18-25         | +40%    |
| 7B       | ~5.5GB      | 12-18         | 8-12          | +50%    |

### W4A8 장점

- ⚡ **속도**: I8MM 하드웨어 가속으로 30-50% 향상
- 💾 **메모리**: 50% 절약 (4bit weights + 8bit activations)  
- 🔋 **전력**: 효율적인 Cortex-A520 코어 활용
- 🎯 **정확도**: FP32 대비 99% 수준 유지

## 📚 참고 자료

- [llama.cpp W4A8 공식 문서](https://github.com/ggerganov/llama.cpp/blob/master/docs/build.md)
- [KleidiAI 최적화](https://github.com/ARM-software/kleidiai)
- [Snapdragon 8 Gen 3 스펙](https://www.qualcomm.com/products/mobile/snapdragon/smartphones/snapdragon-8-series-mobile-platforms/snapdragon-8-gen-3-mobile-platform)
- [Termux 공식 가이드](https://termux.dev/)

## 🆘 지원

문제가 발생하면:
1. `./check_snapdragon_env.sh` 실행하여 환경 확인
2. 로그 파일 확인: `tail -50 snapdragon_w4a8_test.log`
3. GitHub Issues에 환경 정보와 함께 문의

---

**🎯 Snapdragon 8 Gen 3 + W4A8 = 모바일 AI의 새로운 기준!** 🚀 