import os
import torch
import sys

# Ensure the root of ml_service is on the python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import config
from models.architecture import DankFishNet, DankFishModel

def main():
    print("--- Starting ONNX Model Compiler ---")
    
    ckpt_path = os.path.join(config.MODEL_DIR, "dankfish_baseline.ckpt")
    onnx_path = os.path.join(config.MODEL_DIR, "dankfish_baseline.onnx")

    # 1. Initialize PyTorch model architecture
    net = DankFishNet()

    # 2. Check if a trained checkpoint exists
    if os.path.exists(ckpt_path):
        print(f"Loading trained weights from: {ckpt_path}")
        # Load state_dict (weights only)
        state_dict = torch.load(ckpt_path, map_location=torch.device('cpu'))
        # PyTorch Lightning prefixes parameters with "net.", strip them if needed
        clean_state_dict = {}
        for k, v in state_dict.items():
            key = k.replace("net.", "") if k.startswith("net.") else k
            clean_state_dict[key] = v
        net.load_state_dict(clean_state_dict)
    else:
        print(f"Warning: Checkpoint {ckpt_path} not found.")
        print("Compiling model with randomly initialized weights for baseline stub/dev use.")
        # Save a placeholder state_dict to registry for future convenience
        model = DankFishModel()
        torch.save(model.state_dict(), ckpt_path)

    # 3. Set model to evaluation mode
    net.eval()

    # 4. Define dummy input matching the 20-channel tensor shape (Batch=1, Channels=20, Rows=8, Cols=8)
    dummy_input = torch.randn(1, config.INPUT_CHANNELS, config.BOARD_ROWS, config.BOARD_COLS)

    # 5. Export PyTorch graph to ONNX binary
    print(f"Exporting model to ONNX format at: {onnx_path}")
    torch.onnx.export(
        net,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=15,  # Standard, robust opset version
        do_constant_folding=True,
        input_names=["input"],
        output_names=["policy", "attention"],
        # Enable dynamic batch sizing so we can predict single positions or batches
        dynamic_axes={
            "input": {0: "batch_size"},
            "policy": {0: "batch_size"},
            "attention": {0: "batch_size"}
        }
    )
    
    if os.path.exists(onnx_path):
        print(f"Successfully compiled ONNX binary! File size: {os.path.getsize(onnx_path) / 1024 / 1024:.2f} MB")
    else:
        print("Error: ONNX export failed.")

if __name__ == "__main__":
    main()
