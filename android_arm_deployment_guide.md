# 📱 안드로이드 ARM 배포 완전 가이드

## 🚀 1단계: 안드로이드 디바이스 준비

### 필수 요구사항
- **최소 RAM**: 8GB (Llama-2-7B용)
- **저장공간**: 10GB 이상
- **Android 버전**: 7.0+ (API 24+)
- **아키텍처**: ARM64 (aarch64)

### 개발자 옵션 활성화
```bash
# 안드로이드 설정 → 휴대전화 정보 → 빌드번호 7번 터치
# 개발자 옵션 → USB 디버깅 활성화
```

## 🔧 2단계: 파일 전송

### ADB를 통한 전송
```bash
# 안드로이드 디바이스에 파일 전송
adb push build-android/bin/llama-cli /data/local/tmp/
adb push build-android/bin/libggml.so /data/local/tmp/
adb push build-android/bin/libllama.so /data/local/tmp/
adb push models/llama2-7b-smoothquant-q8-0.gguf /data/local/tmp/

# 실행 권한 부여
adb shell chmod +x /data/local/tmp/llama-cli
```

### Termux를 통한 실행 (권장)
```bash
# Termux 설치 후
pkg update && pkg upgrade
pkg install wget proot-distro

# 파일을 Termux 홈으로 복사
cp /data/local/tmp/llama-cli ~/
cp /data/local/tmp/*.so ~/
cp /data/local/tmp/llama2-7b-smoothquant-q8-0.gguf ~/
```

## 🏃‍♂️ 3단계: 실행

### 기본 실행
```bash
# Termux에서
export LD_LIBRARY_PATH=./:$LD_LIBRARY_PATH
./llama-cli -m llama2-7b-smoothquant-q8-0.gguf \
  -p "안녕하세요! 한국어로 대답해주세요." \
  -n 50 -c 512 --temp 0.7
```

### 성능 최적화 옵션
```bash
# ARM NEON 최적화 활성화
./llama-cli -m llama2-7b-smoothquant-q8-0.gguf \
  -p "한국어 텍스트 생성 테스트" \
  -n 100 -c 1024 \
  --temp 0.7 \
  --threads 4 \
  --batch-size 512 \
  --ctx-size 2048
```

## 📊 4단계: 성능 모니터링

### CPU/메모리 사용량 확인
```bash
# 실행 중 다른 터미널에서
top -p $(pgrep llama-cli)
cat /proc/meminfo | grep -E "(MemTotal|MemAvailable)"
```

### 온도 모니터링
```bash
# Snapdragon 기준
cat /sys/class/thermal/thermal_zone*/temp
```

## 🎯 5단계: 성능 벤치마크

### 처리량 측정
```bash
# 100토큰 생성 벤치마크
time ./llama-cli -m llama2-7b-smoothquant-q8-0.gguf \
  -p "Benchmark test:" -n 100 --log-disable
```

### 배치 처리 테스트
```bash
# 여러 프롬프트 순차 처리
for i in {1..5}; do
  echo "Test $i:"
  ./llama-cli -m llama2-7b-smoothquant-q8-0.gguf \
    -p "Test prompt $i" -n 20
done
```

## 🔧 6단계: 트러블슈팅

### 일반적인 문제들

#### 메모리 부족
```bash
# 스왑 활성화 (root 필요)
dd if=/dev/zero of=/swapfile bs=1M count=4096
mkswap /swapfile
swapon /swapfile
```

#### 라이브러리 오류
```bash
# 의존성 확인
ldd llama-cli
export LD_LIBRARY_PATH=/system/lib64:/vendor/lib64:$LD_LIBRARY_PATH
```

#### 권한 문제
```bash
# SELinux 컨텍스트 확인
ls -Z llama-cli
# 필요시 실행 가능한 위치로 이동
mv llama-cli /data/local/tmp/
```

## 📱 7단계: 실제 앱 통합

### JNI 인터페이스 (참고)
```cpp
// Android NDK에서 사용
#include "llama.h"

extern "C" JNIEXPORT jstring JNICALL
Java_com_yourapp_LlamaInterface_generateText(
    JNIEnv *env, jobject thiz, jstring prompt) {
    // llama.cpp 호출 코드
    return env->NewStringUTF(result.c_str());
}
```

### Gradle 설정
```gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'arm64-v8a'
        }
    }
}
```

## 🎯 성능 최적화 팁

### 1. 메모리 최적화
- **mmap 사용**: 모델을 메모리 맵으로 로드
- **배치 크기 조정**: RAM에 따라 조정
- **컨텍스트 크기**: 필요한 만큼만 설정

### 2. CPU 최적화
- **스레드 수**: CPU 코어 수에 맞춰 설정
- **친화성 설정**: 고성능 코어 사용
- **전력 모드**: 성능 모드 활성화

### 3. 온도 관리
- **열 조절**: 장시간 실행 시 주의
- **배경 앱 종료**: 리소스 확보
- **CPU 주파수**: governor 설정

## 📋 최종 체크리스트

- [ ] 안드로이드 디바이스 준비 (8GB+ RAM)
- [ ] 개발자 옵션 및 USB 디버깅 활성화
- [ ] llama.cpp ARM 바이너리 빌드
- [ ] SmoothQuant 모델 생성 및 양자화
- [ ] 파일 전송 (ADB 또는 직접 복사)
- [ ] 실행 권한 설정
- [ ] 기본 실행 테스트
- [ ] 성능 벤치마크
- [ ] 메모리/온도 모니터링
- [ ] 최적화 적용

## 🎉 완료!

이제 SmoothQuant가 적용된 Llama-2-7B 모델이 안드로이드 ARM 디바이스에서 성공적으로 실행됩니다! 

**예상 성능**:
- 메모리 사용량: ~7GB
- 추론 속도: 5-15 tokens/sec (디바이스에 따라)
- 전력 효율: 기존 대비 30-40% 향상 