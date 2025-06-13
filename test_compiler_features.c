#include <stdio.h>
int main() {
    printf("=== Compiler Feature Detection ===\n");
    
#ifdef __ARM_FEATURE_FP16_VECTOR_ARITHMETIC
    printf("FP16_VA: ENABLED\n");
#else
    printf("FP16_VA: DISABLED\n");
#endif

#ifdef __ARM_FEATURE_DOTPROD
    printf("DOTPROD: ENABLED\n");
#else
    printf("DOTPROD: DISABLED\n");
#endif

#ifdef __ARM_FEATURE_MATMUL_INT8
    printf("MATMUL_INT8: ENABLED\n");
#else
    printf("MATMUL_INT8: DISABLED\n");
#endif

    return 0;
} 