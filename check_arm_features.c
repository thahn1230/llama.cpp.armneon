#include <stdio.h>

int main() {
    printf("=== ARM Feature Detection Report ===\n");
    
    // ARM Architecture Info
    printf("ARM Architecture Info:\n");
    #ifdef __aarch64__
        printf("  ✅ __aarch64__ defined\n");
    #else
        printf("  ❌ __aarch64__ NOT defined\n");
    #endif
    
    #ifdef __ARM_ARCH
        printf("  ✅ __ARM_ARCH = %d\n", __ARM_ARCH);
    #else
        printf("  ❌ __ARM_ARCH NOT defined\n");
    #endif
    
    // ARM NEON
    printf("\nARM NEON Features:\n");
    #ifdef __ARM_NEON
        printf("  ✅ __ARM_NEON defined\n");
    #else
        printf("  ❌ __ARM_NEON NOT defined\n");
    #endif
    
    // DOTPROD (for w4a8)
    printf("\nDOTPROD Support (Critical for w4a8):\n");
    #ifdef __ARM_FEATURE_DOTPROD
        printf("  ✅ __ARM_FEATURE_DOTPROD defined\n");
    #else
        printf("  ❌ __ARM_FEATURE_DOTPROD NOT defined\n");
    #endif
    
    // I8MM (for advanced w4a8)
    printf("\nI8MM Support (Advanced w4a8):\n");
    #ifdef __ARM_FEATURE_MATMUL_INT8
        printf("  ✅ __ARM_FEATURE_MATMUL_INT8 defined\n");
    #else
        printf("  ❌ __ARM_FEATURE_MATMUL_INT8 NOT defined\n");
    #endif
    
    // Other ARM Features
    printf("\nOther ARM Features:\n");
    #ifdef __ARM_FEATURE_FMA
        printf("  ✅ __ARM_FEATURE_FMA defined\n");
    #else
        printf("  ❌ __ARM_FEATURE_FMA NOT defined\n");
    #endif
    
    #ifdef __ARM_FEATURE_FP16_VECTOR_ARITHMETIC
        printf("  ✅ __ARM_FEATURE_FP16_VECTOR_ARITHMETIC defined\n");
    #else
        printf("  ❌ __ARM_FEATURE_FP16_VECTOR_ARITHMETIC NOT defined\n");
    #endif
    
    #ifdef __ARM_FEATURE_SVE
        printf("  ✅ __ARM_FEATURE_SVE defined\n");
    #else
        printf("  ❌ __ARM_FEATURE_SVE NOT defined\n");
    #endif
    
    // Compiler Info
    printf("\nCompiler Info:\n");
    #ifdef __GNUC__
        printf("  ✅ GCC version: %d.%d.%d\n", __GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
    #endif
    
    #ifdef __clang__
        printf("  ✅ Clang version: %s\n", __clang_version__);
    #endif
    
    #ifdef __ANDROID__
        printf("  ✅ Android build (__ANDROID__ defined)\n");
    #else
        printf("  ❌ Not Android build\n");
    #endif
    
    printf("\n=== End Report ===\n");
    return 0;
} 