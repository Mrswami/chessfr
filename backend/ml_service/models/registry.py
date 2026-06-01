import os
import numpy as np
import onnxruntime as ort
from typing import Tuple, Optional
import sys

# Ensure the root of ml_service is on the python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import config

class ModelRegistry:
    """
    Registry manager loading compiled ONNX models and running fast, 
    low-memory inference sessions for move predictions.
    """

    def __init__(self, model_filename: str = "dankfish_baseline.onnx"):
        self.model_path = os.path.join(config.MODEL_DIR, model_filename)
        self.session: Optional[ort.InferenceSession] = None
        self.input_name: Optional[str] = None
        
        # Load the session if the compiled binary is available
        if os.path.exists(self.model_path):
            self.load_model()
        else:
            print(f"Warning: ONNX model binary {self.model_path} not found on disk.")

    def load_model(self):
        """Initializes the ONNX Runtime session and gets input/output names."""
        print(f"Loading ONNX Model Session: {self.model_path}")
        # Run on CPU for cheap, highly compatible cloud hosting
        self.session = ort.InferenceSession(self.model_path, providers=["CPUExecutionProvider"])
        self.input_name = self.session.get_inputs()[0].name

    def predict(self, tensor: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Runs inference on a single 20-channel Hybrid Board Tensor.
        
        Args:
            tensor: numpy array of shape (20, 8, 8)
            
        Returns:
            policy_logits: flat numpy array of shape (4096,) representing move scores
            attn_probs: flat numpy array of shape (64,) representing square attention weights
        """
        if self.session is None:
            # Lazy loading fallback in case model was compiled after initialization
            if os.path.exists(self.model_path):
                self.load_model()
            else:
                raise RuntimeError("Cannot run prediction: ONNX model binary is missing.")

        # Add batch dimension: (20, 8, 8) -> (1, 20, 8, 8)
        input_data = np.expand_dims(tensor, axis=0).astype(np.float32)
        
        # Run inference session
        outputs = self.session.run(None, {self.input_name: input_data})
        
        # Extract batch index 0 outputs
        policy_logits = outputs[0][0]
        attn_probs = outputs[1][0]
        
        return policy_logits, attn_probs
