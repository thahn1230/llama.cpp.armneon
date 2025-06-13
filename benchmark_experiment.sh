#!/bin/bash

# ARM optimization vs w4a8 kernel performance comparison script (FIXED)
# 🧪 Performance Experiment: ARM Hardware vs LLAMAFILE w4a8

echo "🧪 === ARM Optimization vs w4a8 Kernel Performance Comparison ==="
echo ""
echo "⚠️  ISSUE DETECTED: Android ARM64 binaries cannot run on Linux x86_64"
echo "📋 SOLUTION: Create native x86_64 builds for actual testing"
echo ""

# Test parameters
MODEL_PATH="${1:-models/tinyllamaabc.gguf}"  # Q4_0 model required
PROMPT="The quick brown fox jumps over the lazy dog. This is a test prompt for benchmarking matrix multiplication performance in language models. We need sufficient text length to trigger multiple matrix operations."
N_PREDICT=50
N_WARMUP=3

if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Error: Model file not found: $MODEL_PATH"
    echo "Usage: $0 [model_path.gguf]"
    echo "Note: Model must be Q4_0 quantized for w4a8 testing"
    exit 1
fi

echo "📝 Test Parameters:"
echo "   Model: $MODEL_PATH"
echo "   Prompt length: ${#PROMPT} characters"
echo "   Tokens to generate: $N_PREDICT"
echo "   Warmup runs: $N_WARMUP"
echo ""

check_build_architecture() {
    local build_dir="$1"
    local name="$2"
    
    if [ ! -f "$build_dir/bin/llama-cli" ]; then
        echo "❌ Binary not found: $build_dir/bin/llama-cli"
        return 1
    fi
    
    local arch=$(file "$build_dir/bin/llama-cli" | grep -o "ARM aarch64\|x86-64")
    echo "🔍 $name architecture: $arch"
    
    if [[ "$arch" == "ARM aarch64" ]]; then
        echo "⚠️  Cannot run ARM binary on x86_64 system"
        return 1
    fi
    
    return 0
}

run_experiment() {
    local name="$1"
    local build_dir="$2"
    local expected_kernel="$3"
    
    echo "🔬 Running Experiment: $name"
    echo "   Expected kernel: $expected_kernel"
    echo "   Build directory: $build_dir"
    
    if ! check_build_architecture "$build_dir" "$name"; then
        echo "💡 SOLUTION: Build native x86_64 version"
        echo "   Command: cmake -B $build_dir -DCMAKE_BUILD_TYPE=Release [options]"
        echo "   Then: cmake --build $build_dir --config Release"
        echo ""
        return 1
    fi
    
    # Warmup runs
    echo "   🔥 Warming up ($N_WARMUP runs)..."
    for i in $(seq 1 $N_WARMUP); do
        $build_dir/bin/llama-cli -m "$MODEL_PATH" -p "$PROMPT" -n 5 --temp 0.0 -ngl 0 > /dev/null 2>&1
    done
    
    # Performance run with detailed output
    echo "   📊 Performance measurement run..."
    echo "   =============================================="
    
    time_output=$(
        { time $build_dir/bin/llama-cli \
            -m "$MODEL_PATH" \
            -p "$PROMPT" \
            -n $N_PREDICT \
            --temp 0.0 \
            -ngl 0 \
            --log-disable 2>&1; } 2>&1
    )
    
    echo "$time_output" | head -50
    echo "   =============================================="
    
    # Extract timing information
    real_time=$(echo "$time_output" | grep "^real" | awk '{print $2}')
    user_time=$(echo "$time_output" | grep "^user" | awk '{print $2}')
    sys_time=$(echo "$time_output" | grep "^sys" | awk '{print $2}')
    
    # Check for kernel usage indicators
    w4a8_usage=$(echo "$time_output" | grep -c "ARM w4a8 GEMM completed" || echo "0")
    matmul_usage=$(echo "$time_output" | grep -c "Using.*MATMUL_INT8" || echo "0")
    llamafile_usage=$(echo "$time_output" | grep -c "llamafile_sgemm" || echo "0")
    
    echo "   ⏱️  Timing Results:"
    echo "      Real time: $real_time"
    echo "      User time: $user_time" 
    echo "      Sys time:  $sys_time"
    echo ""
    echo "   🔍 Kernel Usage Detection:"
    echo "      w4a8 GEMM calls: $w4a8_usage"
    echo "      MATMUL_INT8 usage: $matmul_usage"
    echo "      llamafile calls: $llamafile_usage"
    echo ""
    
    # Store results
    echo "$name,$expected_kernel,$real_time,$user_time,$sys_time,$w4a8_usage,$matmul_usage,$llamafile_usage" >> experiment_results.csv
    
    echo "✅ $name completed"
    echo ""
}

# Initialize results file
echo "Experiment,Expected_Kernel,Real_Time,User_Time,Sys_Time,W4A8_Calls,MATMUL_INT8_Usage,Llamafile_Calls" > experiment_results.csv

echo "🔍 === ARCHITECTURE CHECK ==="
echo ""

# Check all builds
for build in build-experiment1 build-experiment2 build-experiment3; do
    if [ -d "$build" ]; then
        check_build_architecture "$build" "$build"
        echo ""
    else
        echo "❌ Build directory not found: $build"
        echo ""
    fi
done

echo "💡 === RECOMMENDED ACTIONS ==="
echo ""
echo "1. 🏗️  Create native x86_64 builds for testing:"
echo ""
echo "   # LLAMAFILE Only (for w4a8)"
echo "   cmake -B build-native-llamafile -DCMAKE_BUILD_TYPE=Release -DGGML_LLAMAFILE=ON"
echo "   cmake --build build-native-llamafile --config Release"
echo ""
echo "   # ARM Features Only (for MATMUL_INT8/DOTPROD/FP16_VA)"
echo "   cmake -B build-native-arm -DCMAKE_BUILD_TYPE=Release -DGGML_LLAMAFILE=OFF"
echo "   cmake --build build-native-arm --config Release"
echo ""
echo "   # Both LLAMAFILE + ARM Features"
echo "   cmake -B build-native-both -DCMAKE_BUILD_TYPE=Release -DGGML_LLAMAFILE=ON"
echo "   cmake --build build-native-both --config Release"
echo ""
echo "2. 📱 For Android testing:"
echo "   - Transfer binaries to Android device"
echo "   - Run via ADB shell or Termux"
echo "   - Use Android NDK emulator"
echo ""
echo "3. 🎯 Your current Android builds should work fine on actual ARM64 devices!"
echo ""

# Try to run experiments on available builds
echo "🧪 === ATTEMPTING EXPERIMENTS (will skip ARM binaries) ==="
echo ""

run_experiment "Experiment 1: LLAMAFILE Only" "build-experiment1" "w4a8"
run_experiment "Experiment 2: ARM Optimizations Only" "build-experiment2" "MATMUL_INT8"  
run_experiment "Experiment 3: Both Enabled" "build-experiment3" "MATMUL_INT8 (priority)"

if [ -f experiment_results.csv ] && [ $(wc -l < experiment_results.csv) -gt 1 ]; then
    echo "📊 === SUMMARY ==="
    echo ""
    echo "Results saved to: experiment_results.csv"
    echo ""
    cat experiment_results.csv | column -t -s ','
    echo ""
    
    echo "🔍 === ANALYSIS ==="
    echo ""
    echo "1. Check 'W4A8_Calls' column to see which experiment actually used w4a8 kernel"
    echo "2. Compare 'Real_Time' to see performance differences"
    echo "3. 'MATMUL_INT8_Usage' shows ARM I8MM optimization usage"
    echo "4. Look for debug output above to see which kernel was actually selected"
else
    echo "📊 === NO RESULTS ==="
    echo ""
    echo "⚠️  All builds were ARM64 Android binaries - cannot run on x86_64"
    echo "🏗️  Please create native builds for testing as shown above"
fi

echo ""
echo "🧪 Experiment analysis completed!" 
