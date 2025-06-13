# 🔥 진짜 SmoothQuant W8A8 구현 계획

## ❌ **현재 문제점**
- 현재 Q8_A8는 **가중치만 8-bit, 활성화는 float32** (W8A16)
- SmoothQuant 스케일링은 적용되었지만 **런타임 activation quantization 없음**

## ✅ **실제 SmoothQuant 요구사항**

### 1️⃣ **구조체 재정의**
```c
typedef struct {
    ggml_half weight_scale;      // 가중치 양자화 스케일
    ggml_half activation_scale;  // 활성화 양자화 스케일 (런타임 계산)
    int8_t weight_qs[QK8_A8];    // 8-bit 양자화된 가중치
    // 활성화는 런타임에 동적 양자화
} block_q8_a8_v2;
```

### 2️⃣ **런타임 Activation Quantization**
```c
// Forward pass에서 활성화를 동적으로 8-bit 양자화
void quantize_activation_q8_a8(const float* input, int8_t* output, 
                               ggml_half* scale, int size) {
    // 활성화의 절대값 최대치 찾기
    float amax = 0.0f;
    for (int i = 0; i < size; i++) {
        amax = fmaxf(amax, fabsf(input[i]));
    }
    
    // 8-bit 양자화 스케일 계산
    *scale = amax / 127.0f;
    float inv_scale = (*scale != 0) ? 127.0f / amax : 0.0f;
    
    // 활성화를 8-bit로 양자화
    for (int i = 0; i < size; i++) {
        output[i] = (int8_t)roundf(input[i] * inv_scale);
    }
}
```

### 3️⃣ **W8A8 Matrix Multiplication**
```c
// 8-bit weights × 8-bit activations
void ggml_vec_dot_q8_a8_q8_a8_real(int n, float* s, 
                                   const void* vx, const void* vy) {
    const block_q8_a8_v2* x = vx;
    const block_q8_a8_v2* y = vy;  // y는 런타임에 양자화된 활성화
    
    float sumf = 0.0f;
    const int nb = n / QK8_A8;
    
    for (int i = 0; i < nb; i++) {
        int32_t sumi = 0;
        
        // 8-bit weights × 8-bit activations
        for (int j = 0; j < QK8_A8; j++) {
            sumi += (int32_t)x[i].weight_qs[j] * (int32_t)y[i].weight_qs[j];
        }
        
        // 스케일 적용: weight_scale × activation_scale
        float scale = GGML_FP16_TO_FP32(x[i].weight_scale) * 
                     GGML_FP16_TO_FP32(y[i].activation_scale);
        sumf += sumi * scale;
    }
    
    *s = sumf;
}
```

## 🚀 **구현 단계**

### Step 1: Forward Pass Hook 추가
```c
// ggml-cpu.c의 forward pass에서 activation을 동적 양자화
static void ggml_compute_forward_mul_mat_q8_a8_real(
    const struct ggml_compute_params* params,
    struct ggml_tensor* dst) {
    
    // 활성화 텐서를 런타임에 8-bit로 양자화
    quantize_activation_runtime(src1, quantized_activation);
    
    // W8A8 연산 수행
    ggml_vec_dot_q8_a8_q8_a8_real(...);
}
```

### Step 2: SmoothQuant Policy 적용
```python
# Python에서 더 정교한 SmoothQuant 적용
def apply_smoothquant_policy(model, alpha=0.5):
    for layer_name, layer in model.named_modules():
        if isinstance(layer, nn.Linear):
            # 활성화 통계 수집
            activation_stats = collect_activation_stats(layer)
            
            # SmoothQuant 스케일링
            s = activation_stats.max(dim=-1, keepdim=True)[0].clamp(min=1e-5)
            s = s ** alpha / (layer.weight.abs().max(dim=0, keepdim=True)[0] ** (1-alpha))
            
            # 가중치와 활성화에 역 스케일링 적용
            layer.weight.data = layer.weight.data * s
            # 다음 레이어 입력에 1/s 스케일링 적용
            apply_inverse_scaling_to_next_layer(s)
```

## 📱 **안드로이드 ARM 최적화**

### ARM NEON W8A8 최적화
```c
#if defined(__ARM_NEON)
void ggml_vec_dot_q8_a8_q8_a8_neon(int n, float* s, 
                                   const void* vx, const void* vy) {
    // ARM MATMUL_INT8 instruction 사용
    // 8x8 → 32-bit accumulation
    // 벡터화된 8-bit × 8-bit 연산
}
#endif
```

## 🎯 **기대 효과**

1. **메모리**: 50% 절약 (W8A8 vs FP16)
2. **속도**: ARM에서 2-3x 향상 (MATMUL_INT8)
3. **정확도**: SmoothQuant로 quantization error 최소화
4. **실용성**: 8GB RAM 안드로이드에서 7B 모델 실행

## ⚠️ **주의사항**

- **동적 양자화 오버헤드**: Forward pass마다 activation quantization 필요
- **메모리 증가**: 런타임에 temporary quantized activation buffer 필요
- **정확도 trade-off**: W8A8는 W8A16보다 약간의 정확도 손실 