#!/usr/bin/env python3
"""
SmoothQuant GGUF Converter
Converts HuggingFace model with SmoothQuant scaling factors to GGUF format
Includes both weight migration and activation scaling factors for complete W8A8 SmoothQuant
"""

import sys
import json
import argparse
from pathlib import Path
import subprocess

def main():
    parser = argparse.ArgumentParser(description="Convert SmoothQuant model to GGUF with scaling factors")
    parser.add_argument("--model-dir", required=True, help="Directory containing the SmoothQuant model")
    parser.add_argument("--output", required=True, help="Output GGUF file path")
    parser.add_argument("--outtype", default="f16", help="Output tensor type (f16, bf16)")
    
    args = parser.parse_args()
    
    model_dir = Path(args.model_dir)
    output_path = Path(args.output)
    
    # 1. Check for SmoothQuant scaling factors
    scales_file = model_dir / "smoothquant_scales.json"
    if not scales_file.exists():
        print(f"❌ Error: SmoothQuant scales file not found: {scales_file}")
        print("   Make sure the model was processed with SmoothQuant preprocessing")
        sys.exit(1)
    
    print(f"✅ Found SmoothQuant scales: {scales_file}")
    
    # 2. Load scaling factors
    with open(scales_file, 'r') as f:
        smoothquant_scales = json.load(f)
    
    print(f"📊 Loaded {len(smoothquant_scales)} layer scaling factors")
    
    # 3. Convert to GGUF using original script
    print("🔄 Converting to GGUF with HF script...")
    
    cmd = [
        sys.executable, "convert_hf_to_gguf.py",
        str(model_dir),
        "--outfile", str(output_path),
        "--outtype", args.outtype
    ]
    
    result = subprocess.run(cmd, capture_output=False)
    if result.returncode != 0:
        print("❌ GGUF conversion failed")
        sys.exit(1)
    
    print("✅ Basic GGUF conversion completed")
    
    # 4. Add SmoothQuant metadata to GGUF
    print("🔧 Adding SmoothQuant scaling factors to GGUF...")
    
    # Import GGUF after subprocess to avoid conflicts
    import gguf
    
    # Re-open GGUF to add SmoothQuant metadata
    with open(output_path, 'r+b') as f:
        reader = gguf.GGUFReader(output_path, 'r')
        
        # Create new writer to append metadata
        writer = gguf.GGUFWriter(output_path.with_suffix('.tmp.gguf'), None)
        
        # Copy existing metadata
        for field in reader.fields.values():
            if field.name.startswith("general."):
                writer.add_string(field.name, field.parts[0])
            elif field.name.startswith("tokenizer."):
                if field.types[0] == gguf.GGUFValueType.STRING:
                    writer.add_string(field.name, field.parts[0])
                elif field.types[0] == gguf.GGUFValueType.ARRAY:
                    writer.add_array(field.name, field.parts)
        
        # Add SmoothQuant metadata
        writer.add_string("smoothquant.enabled", "true")
        writer.add_string("smoothquant.version", "1.0")
        
        # Convert scales to flat format for GGUF
        scale_data = []
        layer_names = []
        
        for layer_name, scales in smoothquant_scales.items():
            layer_names.append(layer_name)
            scale_data.extend(scales)
        
        writer.add_array("smoothquant.layer_names", layer_names)
        writer.add_array("smoothquant.scales", scale_data)
        
        print(f"📝 Added {len(layer_names)} layers with {len(scale_data)} total scale values")
        
        # Copy tensors
        for tensor in reader.tensors:
            writer.add_tensor(tensor.name, tensor.data, tensor.tensor_type)
        
        writer.close()
        reader.close()
    
    # Replace original with updated file
    output_path.unlink()
    output_path.with_suffix('.tmp.gguf').rename(output_path)
    
    print(f"🎉 Complete SmoothQuant GGUF created: {output_path}")
    print(f"📏 File size: {output_path.stat().st_size / 1024**3:.2f} GiB")
    
    # Verify metadata
    print("🔍 Verifying SmoothQuant metadata...")
    reader = gguf.GGUFReader(output_path, 'r')
    
    has_smoothquant = False
    for field_name in reader.fields:
        if field_name.startswith("smoothquant."):
            has_smoothquant = True
            field = reader.fields[field_name]
            if field_name == "smoothquant.enabled":
                print(f"  ✅ {field_name}: {field.parts[0]}")
            elif field_name == "smoothquant.layer_names":
                print(f"  ✅ {field_name}: {len(field.parts)} layers")
            elif field_name == "smoothquant.scales":
                print(f"  ✅ {field_name}: {len(field.parts)} scale values")
    
    if has_smoothquant:
        print("✅ SmoothQuant metadata successfully embedded!")
    else:
        print("❌ Warning: SmoothQuant metadata not found in output file")
    
    reader.close()

if __name__ == "__main__":
    main() 