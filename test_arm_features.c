#include <stdio.h>

// ARM feature check functions (copy from ggml-cpu.c)
int ggml_cpu_has_fp16_va(void) {
#if defined(__ARM_FEATURE_FP16_VECTOR_ARITHMETIC)
    return 1;
#else
    return 0;
#endif
}

int ggml_cpu_has_dotprod(void) {
#if defined(__ARM_FEATURE_DOTPROD)
    return 1;
#else
    return 0;
#endif
}

int ggml_cpu_has_matmul_int8(void) {
#if defined(__ARM_FEATURE_MATMUL_INT8)
    return 1;
#else
    return 0;
#endif
}

int ggml_cpu_has_llamafile(void) {
#if defined(GGML_USE_LLAMAFILE)
    return 1;
#else
    return 0;
#endif
}

int main() {
    printf("=== ARM Features Status ===\n");
    printf("FP16_VA:     %s\n", ggml_cpu_has_fp16_va() ? "✅ ENABLED" : "❌ DISABLED");
    printf("DOTPROD:     %s\n", ggml_cpu_has_dotprod() ? "✅ ENABLED" : "❌ DISABLED");
    printf("MATMUL_INT8: %s\n", ggml_cpu_has_matmul_int8() ? "✅ ENABLED" : "❌ DISABLED");
    printf("LLAMAFILE:   %s\n", ggml_cpu_has_llamafile() ? "✅ ENABLED" : "❌ DISABLED");
    
    printf("\n=== Compiler Macros ===\n");
#ifdef __ARM_FEATURE_FP16_VECTOR_ARITHMETIC
    printf("__ARM_FEATURE_FP16_VECTOR_ARITHMETIC: DEFINED\n");
#else
    printf("__ARM_FEATURE_FP16_VECTOR_ARITHMETIC: NOT DEFINED\n");
#endif

#ifdef __ARM_FEATURE_DOTPROD
    printf("__ARM_FEATURE_DOTPROD: DEFINED\n");
#else
    printf("__ARM_FEATURE_DOTPROD: NOT DEFINED\n");
#endif

#ifdef __ARM_FEATURE_MATMUL_INT8
    printf("__ARM_FEATURE_MATMUL_INT8: DEFINED\n");
#else
    printf("__ARM_FEATURE_MATMUL_INT8: NOT DEFINED\n");
#endif

#ifdef GGML_USE_LLAMAFILE
    printf("GGML_USE_LLAMAFILE: DEFINED\n");
#else
    printf("GGML_USE_LLAMAFILE: NOT DEFINED\n");
#endif

    return 0;
} 