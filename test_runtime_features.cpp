#include <iostream>
#include <string>

// llama.cpp includes (외부 함수 선언)
extern "C" {
    const char * llama_print_system_info(void);
    
    // CPU feature functions (extern 선언)
    int ggml_cpu_has_fp16_va(void);
    int ggml_cpu_has_dotprod(void);
    int ggml_cpu_has_matmul_int8(void);
    int ggml_cpu_has_llamafile(void);
}

int main() {
    std::cout << "=== Runtime ARM Features Test ===" << std::endl;
    std::cout << std::endl;
    
    std::cout << "🔍 Compile-time Macros:" << std::endl;
#ifdef __ARM_FEATURE_FP16_VECTOR_ARITHMETIC
    std::cout << "  FP16_VA: ✅ DEFINED" << std::endl;
#else
    std::cout << "  FP16_VA: ❌ NOT DEFINED" << std::endl;
#endif

#ifdef __ARM_FEATURE_DOTPROD
    std::cout << "  DOTPROD: ✅ DEFINED" << std::endl;
#else
    std::cout << "  DOTPROD: ❌ NOT DEFINED" << std::endl;
#endif

#ifdef __ARM_FEATURE_MATMUL_INT8
    std::cout << "  MATMUL_INT8: ✅ DEFINED" << std::endl;
#else
    std::cout << "  MATMUL_INT8: ❌ NOT DEFINED" << std::endl;
#endif

#ifdef GGML_USE_LLAMAFILE
    std::cout << "  LLAMAFILE: ✅ DEFINED" << std::endl;
#else
    std::cout << "  LLAMAFILE: ❌ NOT DEFINED" << std::endl;
#endif

    std::cout << std::endl;
    std::cout << "🎯 Runtime Functions (from ggml-cpu):" << std::endl;
    
    // Note: 이 함수들은 실제 llama.cpp 라이브러리와 링크되어야 합니다
    // 지금은 extern 선언만 되어 있으므로 링크 에러가 날 수 있습니다
    
    std::cout << std::endl;
    std::cout << "📋 llama_print_system_info() output:" << std::endl;
    // std::cout << llama_print_system_info() << std::endl;
    std::cout << "  (링크된 라이브러리에서만 실행 가능)" << std::endl;
    
    return 0;
} 