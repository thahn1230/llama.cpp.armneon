#!/usr/bin/env python3
"""
SmoothQuant implementation for Llama-2-7B
Applies activation scaling for weight-activation quantization
"""

import torch
import torch.nn as nn
import numpy as np
from transformers import LlamaForCausalLM, LlamaTokenizer
import os
import json
from tqdm import tqdm
import argparse

def get_activation_stats(model, tokenizer, dataset_path=None, n_samples=512, seq_len=128):
    """
    Collect activation statistics for SmoothQuant
    Returns scales for each linear layer
    """
    print("🔍 Collecting activation statistics...")
    
    # Simple calibration dataset
    if dataset_path is None:
        # Use model's own vocabulary as calibration data
        vocab_size = min(len(tokenizer), 32000)
        calibration_data = []
        for i in range(n_samples):
            # Generate random sequences for calibration
            tokens = torch.randint(1, vocab_size, (seq_len,))
            calibration_data.append(tokens)
    
    activation_scales = {}
    hooks = []
    
    def get_activation_hook(name):
        def hook(module, input, output):
            # Collect input activations (before the linear layer)
            if hasattr(input, '__len__') and len(input) > 0:
                x = input[0].detach()
                if len(x.shape) == 3:  # [batch, seq, hidden]
                    # Calculate per-channel max activation
                    act_max = x.abs().view(-1, x.shape[-1]).max(dim=0)[0]
                    
                    if name not in activation_scales:
                        activation_scales[name] = []
                    activation_scales[name].append(act_max.cpu().float())  # Convert to float
        return hook
    
    # Register hooks for all linear layers
    for name, module in model.named_modules():
        if isinstance(module, nn.Linear) and 'lm_head' not in name:
            hook = module.register_forward_hook(get_activation_hook(name))
            hooks.append(hook)
    
    model.eval()
    with torch.no_grad():
        for i, tokens in enumerate(tqdm(calibration_data[:n_samples//4], desc="Calibrating")):
            try:
                tokens = tokens.unsqueeze(0).to(model.device)
                model(tokens)
                if i > 0 and i % 10 == 0:
                    torch.cuda.empty_cache()  # Clear GPU memory
            except Exception as e:
                print(f"⚠️  Error in calibration sample {i}: {e}")
                continue
    
    # Remove hooks
    for hook in hooks:
        hook.remove()
    
    # Calculate final scales (95th percentile)
    final_scales = {}
    for name, scales in activation_scales.items():
        if scales:
            all_scales = torch.stack(scales).float()  # Ensure float dtype
            # Use 95th percentile for robustness
            scale = torch.quantile(all_scales, 0.95, dim=0)
            final_scales[name] = scale
            print(f"📊 {name}: scale range [{scale.min():.4f}, {scale.max():.4f}]")
    
    return final_scales

def apply_smoothquant(model, activation_scales, alpha=0.5):
    """
    Apply SmoothQuant scaling to the model
    alpha: smoothing factor (0.5 is good default)
    """
    print(f"🔧 Applying SmoothQuant with alpha={alpha}...")
    
    scale_dict = {}
    
    for name, module in model.named_modules():
        if isinstance(module, nn.Linear) and name in activation_scales:
            act_scales = activation_scales[name].to(module.weight.device).float()
            
            # Calculate smoothing scales: s = (max_act)^alpha / (max_weight)^(1-alpha)
            weight_scales = module.weight.abs().max(dim=0)[0].float()
            
            # Avoid division by zero
            act_scales = torch.clamp(act_scales, min=1e-5)
            weight_scales = torch.clamp(weight_scales, min=1e-5)
            
            smooth_scales = (act_scales ** alpha) / (weight_scales ** (1 - alpha))
            
            # Apply scaling to weights (divide weights by scale)
            with torch.no_grad():
                if module.weight.dtype == torch.float16:
                    # Work in float32 then convert back
                    weight_fp32 = module.weight.data.float()
                    weight_fp32 = weight_fp32 / smooth_scales.unsqueeze(0)
                    module.weight.data = weight_fp32.half()
                else:
                    module.weight.data = module.weight.data / smooth_scales.unsqueeze(0)
            
            # Store scales for later use
            scale_dict[name] = smooth_scales.cpu()
            
            print(f"✅ Applied SmoothQuant to {name}, scale range: [{smooth_scales.min():.4f}, {smooth_scales.max():.4f}]")
    
    return scale_dict

def save_smoothquant_model(model, tokenizer, scales, output_dir):
    """Save the SmoothQuant processed model"""
    print(f"💾 Saving model to {output_dir}...")
    
    os.makedirs(output_dir, exist_ok=True)
    
    # Save model and tokenizer
    model.save_pretrained(output_dir, safe_serialization=True, max_shard_size="2GB")
    tokenizer.save_pretrained(output_dir)
    
    # Save scaling factors for reference
    scales_dict = {}
    for name, scale_tensor in scales.items():
        if scale_tensor.dim() == 0:  # scalar tensor
            scales_dict[name] = scale_tensor.item()
        else:  # vector tensor
            scales_dict[name] = scale_tensor.tolist()
    
    with open(os.path.join(output_dir, "smoothquant_scales.json"), "w") as f:
        json.dump(scales_dict, f, indent=2)
    
    print(f"✅ Model saved successfully!")

def main():
    parser = argparse.ArgumentParser(description='Apply SmoothQuant to Llama-2-7B')
    parser.add_argument('--model_path', type=str, default='models/llama2-7b', 
                       help='Path to the original model')
    parser.add_argument('--output_path', type=str, default='models/llama2-7b-smoothquant',
                       help='Path to save the SmoothQuant model')
    parser.add_argument('--alpha', type=float, default=0.5,
                       help='SmoothQuant alpha parameter (default: 0.5)')
    parser.add_argument('--n_samples', type=int, default=64,
                       help='Number of calibration samples (default: 64)')
    
    args = parser.parse_args()
    
    print("🚀 Starting SmoothQuant for Llama-2-7B")
    print(f"📍 Model path: {args.model_path}")
    print(f"📍 Output path: {args.output_path}")
    print(f"📍 Alpha: {args.alpha}")
    
    # Load model and tokenizer
    print("📥 Loading model and tokenizer...")
    try:
        tokenizer = LlamaTokenizer.from_pretrained(args.model_path)
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token
    except:
        from transformers import AutoTokenizer
        tokenizer = AutoTokenizer.from_pretrained(args.model_path)
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token
    
    model = LlamaForCausalLM.from_pretrained(
        args.model_path,
        torch_dtype=torch.float16,
        device_map="auto",
        trust_remote_code=True,
        low_cpu_mem_usage=True
    )
    
    print(f"✅ Model loaded on: {next(model.parameters()).device}")
    
    # Collect activation statistics
    activation_scales = get_activation_stats(
        model, tokenizer, n_samples=args.n_samples
    )
    
    # Apply SmoothQuant
    smooth_scales = apply_smoothquant(model, activation_scales, alpha=args.alpha)
    
    # Save the processed model
    save_smoothquant_model(model, tokenizer, smooth_scales, args.output_path)
    
    print("🎉 SmoothQuant application completed!")
    print(f"📂 Output model saved to: {args.output_path}")

if __name__ == "__main__":
    main() 