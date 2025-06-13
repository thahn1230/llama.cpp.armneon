#!/usr/bin/env python3
"""
Comprehensive ARM Optimization Analysis
w4a16 (ARM optimized) vs w4a8 (ARM unoptimized)
Focus on DOTPROD, MATMUL_INT8, FP16_VA impact
"""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Rectangle
import matplotlib.patches as mpatches

# Set better style
plt.rcParams['font.size'] = 10
plt.rcParams['axes.titlesize'] = 12
plt.rcParams['axes.labelsize'] = 10
plt.rcParams['xtick.labelsize'] = 9
plt.rcParams['ytick.labelsize'] = 9
plt.rcParams['legend.fontsize'] = 9

# Corrected data interpretation
data_w4a16_optimized = {
    'config': 'w4a16 (ARM Optimized)',
    'arm_features': ['FP16_VA', 'MATMUL_INT8', 'DOTPROD'],
    'total_time_ms': 156.20,
    'prompt_eval_time_ms': 142.79,
    'tokens': 2,
    'ms_per_token': 71.40,
    'tokens_per_sec': 14.01,
    'gemm_ops': 0,  # Replaced by ARM-specific operations
    'dequant_ops': 130,
    'ggml_time_ms': 296.73,
    'dequant_time_ms': 1.20,
    'gemm_time_ms': 0.00,  # ARM instructions used instead
    'attention_time_ms': 0.16,
    'norm_time_ms': 0.52,
    'activation_time_ms': 0.88,
    'other_ops_ms': 293.55,  # Contains ARM-optimized operations
    'quantization': 'w4a16',
    'arm_optimized': True
}

data_w4a8_unoptimized = {
    'config': 'w4a8 (ARM Unoptimized)',
    'arm_features': [],
    'total_time_ms': 50566.16,
    'prompt_eval_time_ms': 50562.18,
    'tokens': 2,
    'ms_per_token': 25281.09,
    'tokens_per_sec': 0.04,
    'gemm_ops': 1028,  # Fallback to generic GEMM
    'dequant_ops': 514,
    'ggml_time_ms': 1795.65,
    'dequant_time_ms': 573.07,
    'gemm_time_ms': 1005.39,
    'attention_time_ms': 2.89,
    'norm_time_ms': 5.23,
    'activation_time_ms': 6.32,
    'other_ops_ms': 202.76,
    'quantization': 'w4a8',
    'arm_optimized': False
}

def create_comprehensive_analysis():
    """Create detailed analysis with multiple visualizations"""
    fig = plt.figure(figsize=(24, 20))
    
    # 1. Configuration Comparison Overview
    ax1 = plt.subplot(3, 4, 1)
    configs = ['w4a16\n(ARM Opt)', 'w4a8\n(Unopt)']
    total_times = [data_w4a16_optimized['total_time_ms'], data_w4a8_unoptimized['total_time_ms']]
    
    bars = ax1.bar(configs, total_times, color=['#2ecc71', '#e74c3c'], alpha=0.8, width=0.6)
    ax1.set_ylabel('Total Time (ms)')
    ax1.set_title('Configuration Comparison\nTotal Execution Time', fontweight='bold')
    ax1.set_yscale('log')
    
    # Add value labels
    for bar, time in zip(bars, total_times):
        ax1.text(bar.get_x() + bar.get_width()/2, time * 1.1, 
                f'{time:.1f}ms', ha='center', va='bottom', fontweight='bold')
    
    # 2. Quantization Impact Analysis
    ax2 = plt.subplot(3, 4, 2)
    quant_categories = ['Dequant Ops', 'Dequant Time\n(ms)']
    w4a16_quant = [data_w4a16_optimized['dequant_ops'], data_w4a16_optimized['dequant_time_ms']]
    w4a8_quant = [data_w4a8_unoptimized['dequant_ops'], data_w4a8_unoptimized['dequant_time_ms']]
    
    x = np.arange(len(quant_categories))
    width = 0.35
    
    bars1 = ax2.bar(x - width/2, w4a16_quant, width, label='w4a16 (Optimized)', color='#2ecc71', alpha=0.8)
    bars2 = ax2.bar(x + width/2, w4a8_quant, width, label='w4a8 (Unoptimized)', color='#e74c3c', alpha=0.8)
    
    ax2.set_ylabel('Count / Time')
    ax2.set_title('Quantization Impact\nDequantization Analysis', fontweight='bold')
    ax2.set_xticks(x)
    ax2.set_xticklabels(quant_categories)
    ax2.legend()
    ax2.set_yscale('log')
    
    # Add value labels
    for bars in [bars1, bars2]:
        for bar in bars:
            height = bar.get_height()
            ax2.text(bar.get_x() + bar.get_width()/2, height * 1.1, 
                    f'{height:.1f}', ha='center', va='bottom', fontsize=8)
    
    # 3. ARM Features Impact
    ax3 = plt.subplot(3, 4, 3)
    
    # Create feature activation matrix
    features = ['DOTPROD', 'MATMUL_INT8', 'FP16_VA']
    configs_arm = ['w4a16\n(Optimized)', 'w4a8\n(Unoptimized)']
    
    # Feature matrix: 1 = enabled, 0 = disabled
    feature_matrix = np.array([
        [1, 1, 1],  # w4a16 optimized
        [0, 0, 0]   # w4a8 unoptimized
    ])
    
    im = ax3.imshow(feature_matrix, cmap='RdYlGn', aspect='auto', vmin=0, vmax=1)
    ax3.set_xticks(range(len(features)))
    ax3.set_yticks(range(len(configs_arm)))
    ax3.set_xticklabels(features)
    ax3.set_yticklabels(configs_arm)
    ax3.set_title('ARM Features Activation\nMatrix', fontweight='bold')
    
    # Add text annotations
    for i in range(len(configs_arm)):
        for j in range(len(features)):
            text = 'ON' if feature_matrix[i, j] == 1 else 'OFF'
            color = 'white' if feature_matrix[i, j] == 1 else 'black'
            ax3.text(j, i, text, ha='center', va='center', color=color, fontweight='bold')
    
    # 4. GEMM vs ARM Instructions
    ax4 = plt.subplot(3, 4, 4)
    
    gemm_data = [data_w4a8_unoptimized['gemm_ops'], data_w4a16_optimized['gemm_ops']]
    other_data = [data_w4a8_unoptimized['other_ops_ms'], data_w4a16_optimized['other_ops_ms']]
    
    x_gemm = np.arange(2)
    bars_gemm = ax4.bar(x_gemm - 0.2, gemm_data, 0.4, label='Generic GEMM Ops', color='#e74c3c', alpha=0.8)
    
    # Secondary y-axis for "Other Ops" time
    ax4_twin = ax4.twinx()
    bars_other = ax4_twin.bar(x_gemm + 0.2, other_data, 0.4, label='ARM Optimized Ops (ms)', color='#3498db', alpha=0.8)
    
    ax4.set_ylabel('GEMM Operation Count', color='#e74c3c')
    ax4_twin.set_ylabel('ARM Ops Time (ms)', color='#3498db')
    ax4.set_title('GEMM vs ARM Instructions\nOperation Replacement', fontweight='bold')
    ax4.set_xticks(x_gemm)
    ax4.set_xticklabels(['w4a8\n(Unopt)', 'w4a16\n(Opt)'])
    
    # Add value labels
    for i, (bar_g, bar_o) in enumerate(zip(bars_gemm, bars_other)):
        ax4.text(bar_g.get_x() + bar_g.get_width()/2, bar_g.get_height() + 20, 
                f'{int(gemm_data[i])}', ha='center', va='bottom', color='#e74c3c', fontweight='bold')
        ax4_twin.text(bar_o.get_x() + bar_o.get_width()/2, bar_o.get_height() + 5, 
                     f'{other_data[i]:.1f}ms', ha='center', va='bottom', color='#3498db', fontweight='bold')
    
    # 5. Performance Metrics Breakdown
    ax5 = plt.subplot(3, 4, (5, 6))
    
    metrics = ['Total Time\n(ms)', 'Time/Token\n(ms)', 'Tokens/Sec', 'GGML Time\n(ms)']
    w4a16_values = [
        data_w4a16_optimized['total_time_ms'],
        data_w4a16_optimized['ms_per_token'],
        data_w4a16_optimized['tokens_per_sec'],
        data_w4a16_optimized['ggml_time_ms']
    ]
    w4a8_values = [
        data_w4a8_unoptimized['total_time_ms'],
        data_w4a8_unoptimized['ms_per_token'],
        data_w4a8_unoptimized['tokens_per_sec'],
        data_w4a8_unoptimized['ggml_time_ms']
    ]
    
    x_perf = np.arange(len(metrics))
    width = 0.35
    
    bars_w4a16 = ax5.bar(x_perf - width/2, w4a16_values, width, 
                        label='w4a16 (ARM Optimized)', color='#2ecc71', alpha=0.8)
    bars_w4a8 = ax5.bar(x_perf + width/2, w4a8_values, width, 
                       label='w4a8 (Unoptimized)', color='#e74c3c', alpha=0.8)
    
    ax5.set_ylabel('Value (Log Scale)')
    ax5.set_title('Performance Metrics Comparison\nComprehensive Analysis', fontweight='bold')
    ax5.set_xticks(x_perf)
    ax5.set_xticklabels(metrics)
    ax5.legend()
    ax5.set_yscale('log')
    
    # 6. Operation Time Distribution (w4a16)
    ax6 = plt.subplot(3, 4, 7)
    
    w4a16_ops_labels = ['Dequant', 'ARM Ops', 'Attention', 'Norm', 'Activation']
    w4a16_ops_values = [
        data_w4a16_optimized['dequant_time_ms'],
        data_w4a16_optimized['other_ops_ms'],
        data_w4a16_optimized['attention_time_ms'],
        data_w4a16_optimized['norm_time_ms'],
        data_w4a16_optimized['activation_time_ms']
    ]
    
    colors_opt = ['#27ae60', '#2ecc71', '#58d68d', '#85c1e9', '#5dade2']
    wedges, texts, autotexts = ax6.pie(w4a16_ops_values, labels=w4a16_ops_labels, 
                                      autopct='%1.1f%%', colors=colors_opt, startangle=90)
    ax6.set_title('w4a16 (ARM Optimized)\nOperation Time Distribution', fontweight='bold')
    
    # 7. Operation Time Distribution (w4a8)
    ax7 = plt.subplot(3, 4, 8)
    
    w4a8_ops_labels = ['Dequant', 'GEMM', 'Attention', 'Norm', 'Activation', 'Other']
    w4a8_ops_values = [
        data_w4a8_unoptimized['dequant_time_ms'],
        data_w4a8_unoptimized['gemm_time_ms'],
        data_w4a8_unoptimized['attention_time_ms'],
        data_w4a8_unoptimized['norm_time_ms'],
        data_w4a8_unoptimized['activation_time_ms'],
        data_w4a8_unoptimized['other_ops_ms']
    ]
    
    colors_unopt = ['#e74c3c', '#c0392b', '#f1948a', '#f5b7b1', '#fadbd8', '#d5a6bd']
    wedges, texts, autotexts = ax7.pie(w4a8_ops_values, labels=w4a8_ops_labels, 
                                      autopct='%1.1f%%', colors=colors_unopt, startangle=90)
    ax7.set_title('w4a8 (Unoptimized)\nOperation Time Distribution', fontweight='bold')
    
    # 8. Improvement Ratios
    ax8 = plt.subplot(3, 4, 9)
    
    improvement_metrics = ['Total\nTime', 'Time/\nToken', 'GGML\nTime', 'Dequant\nOps']
    improvements = [
        data_w4a8_unoptimized['total_time_ms'] / data_w4a16_optimized['total_time_ms'],
        data_w4a8_unoptimized['ms_per_token'] / data_w4a16_optimized['ms_per_token'],
        data_w4a8_unoptimized['ggml_time_ms'] / data_w4a16_optimized['ggml_time_ms'],
        data_w4a8_unoptimized['dequant_ops'] / data_w4a16_optimized['dequant_ops']
    ]
    
    bars_imp = ax8.bar(improvement_metrics, improvements, color='#f39c12', alpha=0.8)
    ax8.set_ylabel('Improvement Factor (x)')
    ax8.set_title('Performance Improvement\nw4a16 vs w4a8', fontweight='bold')
    
    # Add value labels
    for bar, imp in zip(bars_imp, improvements):
        ax8.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 5, 
                f'{imp:.1f}x', ha='center', va='bottom', fontweight='bold')
    
    # 9. ARM Feature Benefits Explanation
    ax9 = plt.subplot(3, 4, (10, 12))
    ax9.axis('off')
    
    explanation_text = """
ARM OPTIMIZATION FEATURES IMPACT ANALYSIS:

🔥 DOTPROD (Dot Product Instructions):
   • Accelerates vector dot product operations
   • Replaces multiple scalar operations with single instruction
   • Critical for attention mechanisms and matrix operations
   • Reduces computation from O(n) to O(1) for vector pairs

⚡ MATMUL_INT8 (8-bit Integer Matrix Multiplication):
   • Hardware-accelerated 8-bit integer matrix multiplication
   • Eliminates generic GEMM operations (1028 → 0)
   • Specialized ARM instructions for quantized operations
   • Massive speedup for quantized neural networks

🚀 FP16_VA (16-bit Floating Point Vector Arithmetic):
   • SIMD operations on 16-bit floats
   • 2x throughput compared to FP32 operations
   • Maintains numerical precision for critical operations
   • Essential for w4a16 quantization scheme

💡 WHY w4a8 IS SLOWER:
   • No ARM optimizations → fallback to generic operations
   • 8-bit activations require more quantization overhead
   • Generic GEMM operations (1028 ops) vs ARM instructions (0 ops)
   • Higher quantization error requires more correction

📊 GEMM ELIMINATION EXPLANATION:
   • ARM MATMUL_INT8 replaces generic GEMM entirely
   • Operations moved to "Other Ops" category (293.55ms)
   • Hardware-specific instructions vs software emulation
   • Direct hardware acceleration vs CPU computation
    """
    
    ax9.text(0.05, 0.95, explanation_text, transform=ax9.transAxes, fontsize=10,
             verticalalignment='top', fontfamily='monospace',
             bbox=dict(boxstyle="round,pad=0.5", facecolor="lightgray", alpha=0.8))
    
    plt.tight_layout(pad=2.0)
    
    # Add main title
    fig.suptitle('🔥 ARM Optimization Deep Dive Analysis\n'
                'w4a16 (DOTPROD+MATMUL_INT8+FP16_VA) vs w4a8 (Unoptimized)', 
                fontsize=18, fontweight='bold', y=0.98)
    
    return fig

def create_detailed_comparison_table():
    """Create a comprehensive comparison table"""
    fig, ax = plt.subplots(figsize=(16, 12))
    ax.axis('tight')
    ax.axis('off')
    
    # Create detailed comparison data
    metrics = [
        'Configuration',
        'Quantization Scheme',
        'ARM Features',
        'Total Time (ms)',
        'Time per Token (ms)',
        'Tokens per Second',
        'GEMM Operations',
        'Dequantization Ops',
        'GGML Total Time (ms)',
        'Dequant Time (ms)',
        'GEMM Time (ms)',
        'ARM Ops Time (ms)',
        'Attention Time (ms)',
        'Normalization Time (ms)',
        'Activation Time (ms)',
        'Speedup vs w4a8',
        'Efficiency Gain'
    ]
    
    w4a16_values = [
        'w4a16 (ARM Optimized)',
        'Weight 4-bit, Activation 16-bit',
        'DOTPROD + MATMUL_INT8 + FP16_VA',
        f"{data_w4a16_optimized['total_time_ms']:.2f}",
        f"{data_w4a16_optimized['ms_per_token']:.2f}",
        f"{data_w4a16_optimized['tokens_per_sec']:.2f}",
        f"{data_w4a16_optimized['gemm_ops']} (ARM replaced)",
        f"{data_w4a16_optimized['dequant_ops']}",
        f"{data_w4a16_optimized['ggml_time_ms']:.2f}",
        f"{data_w4a16_optimized['dequant_time_ms']:.2f}",
        f"{data_w4a16_optimized['gemm_time_ms']:.2f} (ARM)",
        f"{data_w4a16_optimized['other_ops_ms']:.2f}",
        f"{data_w4a16_optimized['attention_time_ms']:.2f}",
        f"{data_w4a16_optimized['norm_time_ms']:.2f}",
        f"{data_w4a16_optimized['activation_time_ms']:.2f}",
        "323.7x faster",
        "99.7% reduction"
    ]
    
    w4a8_values = [
        'w4a8 (Unoptimized)',
        'Weight 4-bit, Activation 8-bit',
        'None (Generic operations)',
        f"{data_w4a8_unoptimized['total_time_ms']:.2f}",
        f"{data_w4a8_unoptimized['ms_per_token']:.2f}",
        f"{data_w4a8_unoptimized['tokens_per_sec']:.2f}",
        f"{data_w4a8_unoptimized['gemm_ops']} (Generic)",
        f"{data_w4a8_unoptimized['dequant_ops']}",
        f"{data_w4a8_unoptimized['ggml_time_ms']:.2f}",
        f"{data_w4a8_unoptimized['dequant_time_ms']:.2f}",
        f"{data_w4a8_unoptimized['gemm_time_ms']:.2f}",
        f"{data_w4a8_unoptimized['other_ops_ms']:.2f}",
        f"{data_w4a8_unoptimized['attention_time_ms']:.2f}",
        f"{data_w4a8_unoptimized['norm_time_ms']:.2f}",
        f"{data_w4a8_unoptimized['activation_time_ms']:.2f}",
        "1.0x (baseline)",
        "0% (baseline)"
    ]
    
    table_data = []
    for i, metric in enumerate(metrics):
        table_data.append([metric, w4a16_values[i], w4a8_values[i]])
    
    # Create table
    table = ax.table(cellText=table_data,
                    colLabels=['Metric', 'w4a16 (ARM Optimized)', 'w4a8 (Unoptimized)'],
                    cellLoc='center',
                    loc='center',
                    colWidths=[0.35, 0.35, 0.3])
    
    # Style the table
    table.auto_set_font_size(False)
    table.set_fontsize(9)
    table.scale(1, 1.8)
    
    # Color code the headers
    for i in range(3):
        table[(0, i)].set_facecolor('#2c3e50')
        table[(0, i)].set_text_props(weight='bold', color='white')
    
    # Color code rows by category
    categories = {
        'config': [1, 2, 3],  # Configuration rows
        'performance': [4, 5, 6],  # Performance rows
        'operations': [7, 8, 9, 10, 11, 12],  # Operation rows
        'timing': [13, 14, 15],  # Timing rows
        'summary': [16, 17]  # Summary rows
    }
    
    colors = {
        'config': '#ecf0f1',
        'performance': '#d5f4e6',
        'operations': '#fdeaa7',
        'timing': '#fab1a0',
        'summary': '#a29bfe'
    }
    
    for category, rows in categories.items():
        for row in rows:
            for col in range(3):
                table[(row, col)].set_facecolor(colors[category])
                if col == 1:  # w4a16 column
                    table[(row, col)].set_text_props(weight='bold')
    
    plt.title('📊 Comprehensive Performance Comparison\n'
              'ARM Optimization Impact on Different Quantization Schemes', 
              fontsize=16, fontweight='bold', pad=30)
    
    return fig

def main():
    print("🔥 Generating Comprehensive ARM Optimization Analysis...")
    
    # Generate main analysis
    fig1 = create_comprehensive_analysis()
    fig1.savefig('arm_comprehensive_analysis.png', dpi=300, bbox_inches='tight')
    print("✅ Comprehensive analysis saved as 'arm_comprehensive_analysis.png'")
    
    # Generate detailed table
    fig2 = create_detailed_comparison_table()
    fig2.savefig('arm_detailed_comparison_table.png', dpi=300, bbox_inches='tight')
    print("✅ Detailed comparison table saved as 'arm_detailed_comparison_table.png'")
    
    # Print detailed insights
    print("\n" + "="*80)
    print("🔥 COMPREHENSIVE ARM OPTIMIZATION ANALYSIS")
    print("="*80)
    
    print("\n📊 CONFIGURATION COMPARISON:")
    print(f"   • w4a16 (ARM Optimized): {data_w4a16_optimized['total_time_ms']:.1f}ms")
    print(f"   • w4a8 (Unoptimized): {data_w4a8_unoptimized['total_time_ms']:.1f}ms")
    print(f"   • Performance Gap: {data_w4a8_unoptimized['total_time_ms']/data_w4a16_optimized['total_time_ms']:.1f}x slower")
    
    print("\n🔧 ARM FEATURES IMPACT:")
    print("   • DOTPROD: Vector dot product acceleration")
    print("   • MATMUL_INT8: Hardware 8-bit matrix multiplication")
    print("   • FP16_VA: 16-bit floating point vector arithmetic")
    
    print("\n⚡ GEMM OPERATION ANALYSIS:")
    print(f"   • w4a8 Generic GEMM: {data_w4a8_unoptimized['gemm_ops']} operations")
    print(f"   • w4a16 ARM Optimized: {data_w4a16_optimized['gemm_ops']} operations (replaced by ARM instructions)")
    print(f"   • ARM Operations Time: {data_w4a16_optimized['other_ops_ms']:.1f}ms")
    
    print("\n📈 QUANTIZATION IMPACT:")
    print(f"   • w4a8 Dequant Ops: {data_w4a8_unoptimized['dequant_ops']} ({data_w4a8_unoptimized['dequant_time_ms']:.1f}ms)")
    print(f"   • w4a16 Dequant Ops: {data_w4a16_optimized['dequant_ops']} ({data_w4a16_optimized['dequant_time_ms']:.1f}ms)")
    print(f"   • Quantization Efficiency: {data_w4a8_unoptimized['dequant_ops']/data_w4a16_optimized['dequant_ops']:.1f}x reduction")
    
    print("\n🎯 KEY INSIGHTS:")
    print("   1. ARM optimizations eliminate generic GEMM operations entirely")
    print("   2. w4a16 requires fewer dequantization operations than w4a8")
    print("   3. ARM MATMUL_INT8 provides hardware acceleration for quantized operations")
    print("   4. FP16_VA enables efficient 16-bit activation processing")
    print("   5. DOTPROD accelerates attention and vector operations")
    
    plt.show()

if __name__ == "__main__":
    main() 