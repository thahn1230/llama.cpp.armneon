#!/usr/bin/env python3
"""
Performance Comparison Visualization
ARM Features: Disabled vs Enabled
"""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Rectangle
import pandas as pd

# Set style
plt.style.use('default')

# Data from the results
data_before = {
    'total_time_ms': 50566.16,
    'prompt_eval_time_ms': 50562.18,
    'tokens': 2,
    'ms_per_token': 25281.09,
    'tokens_per_sec': 0.04,
    'gemm_ops': 1028,
    'dequant_ops': 514,
    'ggml_time_ms': 1795.65,
    'dequant_time_ms': 573.07,
    'gemm_time_ms': 1005.39,
    'attention_time_ms': 2.89,
    'norm_time_ms': 5.23,
    'activation_time_ms': 6.32,
    'other_ops_ms': 202.76
}

data_after = {
    'total_time_ms': 156.20,
    'prompt_eval_time_ms': 142.79,
    'tokens': 2,
    'ms_per_token': 71.40,
    'tokens_per_sec': 14.01,
    'gemm_ops': 0,
    'dequant_ops': 130,
    'ggml_time_ms': 296.73,
    'dequant_time_ms': 1.20,
    'gemm_time_ms': 0.00,
    'attention_time_ms': 0.16,
    'norm_time_ms': 0.52,
    'activation_time_ms': 0.88,
    'other_ops_ms': 293.55
}

def create_comparison_plots():
    fig = plt.figure(figsize=(20, 16))
    
    # 1. Overall Performance Comparison
    ax1 = plt.subplot(2, 3, 1)
    categories = ['Total Time\n(ms)', 'Time per Token\n(ms)', 'Tokens per Sec']
    before_values = [data_before['total_time_ms'], data_before['ms_per_token'], data_before['tokens_per_sec']]
    after_values = [data_after['total_time_ms'], data_after['ms_per_token'], data_after['tokens_per_sec']]
    
    x = np.arange(len(categories))
    width = 0.35
    
    bars1 = ax1.bar(x - width/2, before_values, width, label='ARM Features Disabled', color='#ff6b6b', alpha=0.8)
    bars2 = ax1.bar(x + width/2, after_values, width, label='ARM Features Enabled', color='#4ecdc4', alpha=0.8)
    
    ax1.set_ylabel('Value')
    ax1.set_title('🚀 Overall Performance Comparison\n(Lower is better for time metrics)', fontweight='bold', fontsize=12)
    ax1.set_xticks(x)
    ax1.set_xticklabels(categories)
    ax1.legend()
    ax1.set_yscale('log')  # Log scale due to huge differences
    
    # Add value labels on bars
    for bars in [bars1, bars2]:
        for bar in bars:
            height = bar.get_height()
            ax1.annotate(f'{height:.2f}',
                        xy=(bar.get_x() + bar.get_width() / 2, height),
                        xytext=(0, 3),  # 3 points vertical offset
                        textcoords="offset points",
                        ha='center', va='bottom', fontsize=8)
    
    # 2. Operation Count Comparison
    ax2 = plt.subplot(2, 3, 2)
    ops_categories = ['GEMM Ops', 'Dequant Ops']
    ops_before = [data_before['gemm_ops'], data_before['dequant_ops']]
    ops_after = [data_after['gemm_ops'], data_after['dequant_ops']]
    
    x_ops = np.arange(len(ops_categories))
    bars3 = ax2.bar(x_ops - width/2, ops_before, width, label='ARM Features Disabled', color='#ff6b6b', alpha=0.8)
    bars4 = ax2.bar(x_ops + width/2, ops_after, width, label='ARM Features Enabled', color='#4ecdc4', alpha=0.8)
    
    ax2.set_ylabel('Number of Operations')
    ax2.set_title('📊 Operation Count Comparison', fontweight='bold', fontsize=12)
    ax2.set_xticks(x_ops)
    ax2.set_xticklabels(ops_categories)
    ax2.legend()
    
    # Add value labels
    for bars in [bars3, bars4]:
        for bar in bars:
            height = bar.get_height()
            ax2.annotate(f'{int(height)}',
                        xy=(bar.get_x() + bar.get_width() / 2, height),
                        xytext=(0, 3),
                        textcoords="offset points",
                        ha='center', va='bottom', fontsize=10)
    
    # 3. GGML Time Breakdown - Before
    ax3 = plt.subplot(2, 3, 3)
    ggml_labels_before = ['Dequant', 'GEMM', 'Attention', 'Norm', 'Activation', 'Other']
    ggml_values_before = [
        data_before['dequant_time_ms'],
        data_before['gemm_time_ms'],
        data_before['attention_time_ms'],
        data_before['norm_time_ms'],
        data_before['activation_time_ms'],
        data_before['other_ops_ms']
    ]
    
    colors_before = ['#ff9999', '#ff6666', '#ff3333', '#ff0000', '#cc0000', '#990000']
    wedges, texts, autotexts = ax3.pie(ggml_values_before, labels=ggml_labels_before, autopct='%1.1f%%', 
                                      colors=colors_before, startangle=90)
    ax3.set_title('🔴 GGML Time Breakdown\n(ARM Features Disabled)', fontweight='bold', fontsize=11)
    
    # 4. GGML Time Breakdown - After
    ax4 = plt.subplot(2, 3, 4)
    ggml_labels_after = ['Dequant', 'GEMM', 'Attention', 'Norm', 'Activation', 'Other']
    ggml_values_after = [
        data_after['dequant_time_ms'],
        data_after['gemm_time_ms'],
        data_after['attention_time_ms'],
        data_after['norm_time_ms'],
        data_after['activation_time_ms'],
        data_after['other_ops_ms']
    ]
    
    colors_after = ['#99ffcc', '#66ffbb', '#33ff99', '#00ff88', '#00cc77', '#009966']
    wedges, texts, autotexts = ax4.pie(ggml_values_after, labels=ggml_labels_after, autopct='%1.1f%%',
                                      colors=colors_after, startangle=90)
    ax4.set_title('🟢 GGML Time Breakdown\n(ARM Features Enabled)', fontweight='bold', fontsize=11)
    
    # 5. Performance Improvement Ratios
    ax5 = plt.subplot(2, 3, 5)
    improvement_categories = ['Total Time', 'Time/Token', 'GGML Time', 'Dequant Ops', 'GEMM Ops']
    improvement_ratios = [
        data_before['total_time_ms'] / data_after['total_time_ms'],
        data_before['ms_per_token'] / data_after['ms_per_token'],
        data_before['ggml_time_ms'] / data_after['ggml_time_ms'],
        data_before['dequant_ops'] / data_after['dequant_ops'],
        float('inf') if data_after['gemm_ops'] == 0 else data_before['gemm_ops'] / data_after['gemm_ops']
    ]
    
    # Handle infinity for GEMM ops
    improvement_ratios[4] = 1000  # Cap at 1000x for visualization
    
    bars5 = ax5.bar(improvement_categories, improvement_ratios, color='#45b7d1', alpha=0.8)
    ax5.set_ylabel('Improvement Ratio (x times faster)')
    ax5.set_title('⚡ Performance Improvement Ratios', fontweight='bold', fontsize=12)
    ax5.tick_params(axis='x', rotation=45)
    
    # Add value labels
    for i, bar in enumerate(bars5):
        height = bar.get_height()
        label = f'{height:.1f}x' if i != 4 else '∞'
        ax5.annotate(label,
                    xy=(bar.get_x() + bar.get_width() / 2, height),
                    xytext=(0, 3),
                    textcoords="offset points",
                    ha='center', va='bottom', fontsize=10, fontweight='bold')
    
    # 6. Timeline Visualization
    ax6 = plt.subplot(2, 3, 6)
    
    # Create timeline bars
    scenarios = ['ARM Disabled', 'ARM Enabled']
    times = [data_before['total_time_ms'], data_after['total_time_ms']]
    
    bars6 = ax6.barh(scenarios, times, color=['#ff6b6b', '#4ecdc4'], alpha=0.8, height=0.6)
    
    # Add time labels
    for i, (bar, time) in enumerate(zip(bars6, times)):
        ax6.text(time + max(times) * 0.01, bar.get_y() + bar.get_height()/2, 
                f'{time:.1f} ms', va='center', fontweight='bold')
    
    ax6.set_xlabel('Total Execution Time (ms)')
    ax6.set_title('⏱️ Execution Time Comparison', fontweight='bold', fontsize=12)
    ax6.set_xlim(0, max(times) * 1.2)
    
    plt.tight_layout(pad=3.0)
    
    # Add main title
    fig.suptitle('🔥 ARM Features Performance Impact Analysis\n'
                'DOTPROD + MATMUL_INT8 + FP16_VA Optimization Results', 
                fontsize=16, fontweight='bold', y=0.98)
    
    return fig

def create_summary_table():
    """Create a summary comparison table"""
    fig, ax = plt.subplots(figsize=(12, 8))
    ax.axis('tight')
    ax.axis('off')
    
    # Create comparison data
    metrics = [
        'Total Execution Time (ms)',
        'Prompt Eval Time (ms)', 
        'Time per Token (ms)',
        'Tokens per Second',
        'GEMM Operations',
        'Dequantization Ops',
        'GGML Total Time (ms)',
        'Dequant Time (ms)',
        'GEMM Time (ms)',
        'Speedup Factor'
    ]
    
    before_values = [
        f"{data_before['total_time_ms']:.2f}",
        f"{data_before['prompt_eval_time_ms']:.2f}",
        f"{data_before['ms_per_token']:.2f}",
        f"{data_before['tokens_per_sec']:.2f}",
        f"{data_before['gemm_ops']}",
        f"{data_before['dequant_ops']}",
        f"{data_before['ggml_time_ms']:.2f}",
        f"{data_before['dequant_time_ms']:.2f}",
        f"{data_before['gemm_time_ms']:.2f}",
        "1.0x (baseline)"
    ]
    
    after_values = [
        f"{data_after['total_time_ms']:.2f}",
        f"{data_after['prompt_eval_time_ms']:.2f}",
        f"{data_after['ms_per_token']:.2f}",
        f"{data_after['tokens_per_sec']:.2f}",
        f"{data_after['gemm_ops']}",
        f"{data_after['dequant_ops']}",
        f"{data_after['ggml_time_ms']:.2f}",
        f"{data_after['dequant_time_ms']:.2f}",
        f"{data_after['gemm_time_ms']:.2f}",
        f"{data_before['total_time_ms']/data_after['total_time_ms']:.1f}x faster"
    ]
    
    table_data = []
    for i, metric in enumerate(metrics):
        table_data.append([metric, before_values[i], after_values[i]])
    
    # Create table
    table = ax.table(cellText=table_data,
                    colLabels=['Metric', 'ARM Features Disabled', 'ARM Features Enabled'],
                    cellLoc='center',
                    loc='center',
                    colWidths=[0.4, 0.3, 0.3])
    
    # Style the table
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1, 2)
    
    # Color code the headers
    for i in range(3):
        table[(0, i)].set_facecolor('#40466e')
        table[(0, i)].set_text_props(weight='bold', color='white')
    
    # Color code improvement rows
    for i in range(1, len(table_data) + 1):
        if i == len(table_data):  # Speedup row
            table[(i, 0)].set_facecolor('#e8f5e8')
            table[(i, 1)].set_facecolor('#ffe8e8')
            table[(i, 2)].set_facecolor('#e8f5e8')
        else:
            table[(i, 1)].set_facecolor('#fff2f2')
            table[(i, 2)].set_facecolor('#f2fff2')
    
    plt.title('📊 Detailed Performance Comparison Table\nARM DOTPROD + MATMUL_INT8 + FP16_VA Impact', 
              fontsize=14, fontweight='bold', pad=20)
    
    return fig

def main():
    print("🚀 Generating ARM Features Performance Analysis...")
    
    # Generate main comparison plots
    fig1 = create_comparison_plots()
    fig1.savefig('arm_performance_comparison.png', dpi=300, bbox_inches='tight')
    print("✅ Main comparison plots saved as 'arm_performance_comparison.png'")
    
    # Generate summary table
    fig2 = create_summary_table()
    fig2.savefig('arm_performance_table.png', dpi=300, bbox_inches='tight')
    print("✅ Summary table saved as 'arm_performance_table.png'")
    
    # Print key insights
    print("\n" + "="*60)
    print("🔥 KEY PERFORMANCE INSIGHTS")
    print("="*60)
    print(f"⚡ Total speedup: {data_before['total_time_ms']/data_after['total_time_ms']:.1f}x faster")
    print(f"🚀 Token processing: {data_before['ms_per_token']/data_after['ms_per_token']:.1f}x faster")
    print(f"🎯 Tokens/sec improvement: {data_after['tokens_per_sec']/data_before['tokens_per_sec']:.1f}x increase")
    print(f"📉 GEMM operations: {data_before['gemm_ops']} → {data_after['gemm_ops']} (eliminated!)")
    print(f"📉 Dequant operations: {data_before['dequant_ops']} → {data_after['dequant_ops']} ({data_before['dequant_ops']/data_after['dequant_ops']:.1f}x reduction)")
    print("\n🏆 ARM DOTPROD + MATMUL_INT8 + FP16_VA features successfully activated!")
    print("🔧 The code fix was successful - SO files needed updating with new optimizations!")
    
    plt.show()

if __name__ == "__main__":
    main() 