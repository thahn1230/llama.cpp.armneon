#include <iostream>
int main() {
#ifdef __ARM_FEATURE_MATMUL_INT8
    std::cout << "MATMUL_INT8: YES" << std::endl;
#else
    std::cout << "MATMUL_INT8: NO" << std::endl;  
#endif
#ifdef __ARM_FEATURE_SVE
    std::cout << "SVE: YES" << std::endl;
#else
    std::cout << "SVE: NO" << std::endl;
#endif
    return 0;
} 