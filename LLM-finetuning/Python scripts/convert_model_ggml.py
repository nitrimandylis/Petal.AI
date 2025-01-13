import struct
import numpy as np
from safetensors.torch import load_file

# Define paths here
SAFETENSORS_PATH = "/Users/nick/Developer/Personal_Project/Python/Models/gpt2-trained/model.safetensors"  # Change to your .safetensors file path
OUTPUT_PATH = "/Users/nick/Developer/Personal_Project/Python/Models/gpt2-ggml/skills-bot.ggml"

def quantize_to_int8(tensor):
    """
    Quantize a float32 tensor to int8.
    """
    # Compute the scaling factor and quantize
    scale = np.max(np.abs(tensor)) / 127  # Scale to the range of int8
    quantized = np.round(tensor / scale).astype(np.int8)
    return quantized, scale


def convert_to_ggml(safetensors_path, output_path):
    # Load the model from the safetensors file
    print(f"Loading model from {safetensors_path}...")
    model_data = load_file(safetensors_path)
    
    # Open the output file for writing
    print(f"Saving to {output_path}...")
    with open(output_path, "wb") as ggml_file:
        for tensor_name, tensor_data in model_data.items():
            print(f"Processing tensor: {tensor_name}")
            
            # Convert tensor to numpy array
            tensor_array = tensor_data.cpu().numpy()
            
            # Quantize tensor to int8
            quantized_tensor, scale = quantize_to_int8(tensor_array)
            
            # Write tensor name length and name
            name_encoded = tensor_name.encode("utf-8")
            ggml_file.write(struct.pack("I", len(name_encoded)))  # Write name length
            ggml_file.write(name_encoded)  # Write name
            
            # Write tensor shape
            shape = quantized_tensor.shape
            ggml_file.write(struct.pack("I", len(shape)))  # Number of dimensions
            for dim in shape:
                ggml_file.write(struct.pack("I", dim))  # Write each dimension
            
            # Write the scale factor (float32) for dequantization
            ggml_file.write(struct.pack("f", scale))
            
            # Write the quantized tensor data (int8)
            ggml_file.write(quantized_tensor.tobytes())
    
    print("Quantized conversion complete!")


if __name__ == "__main__":
    # Run the conversion with the hardcoded paths
    convert_to_ggml(SAFETENSORS_PATH, OUTPUT_PATH)