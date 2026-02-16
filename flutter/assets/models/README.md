# Chess Vision Models

## Pre-trained YOLOv8 Model Setup

### Option 1: Download Pre-trained Model (Recommended for Quick Start)

**From Hugging Face:**
1. Visit: https://huggingface.co/dopaul/chess_piece_detection
2. Download: `best.tflite` or `chess_yolov8n.tflite`
3. Place in this folder

**From Roboflow Universe:**
1. Visit: https://universe.roboflow.com/models-mc3oh/chess-pieces-detection-v4fl1
2. Export as TensorFlow Lite
3. Download and place in this folder

### Option 2: Train Your Own Model

```python
# Install ultralytics
pip install ultralytics

# Export YOLOv8 to TFLite
from ultralytics import YOLO
model = YOLO('yolov8n.pt')  # or your trained model
model.export(format='tflite', imgsz=640, int8=False)
```

### Required Files

Place these files in this folder:
- `chess_yolov8.tflite` - The model file
- `labels.txt` - Class labels (see below)

### labels.txt Format

Create a file named `labels.txt` with these 12 classes:

```
white-king
white-queen
white-bishop
white-knight
white-rook
white-pawn
black-king
black-queen
black-bishop
black-knight
black-rook
black-pawn
```

### Quick Download Commands

**Using wget (Git Bash/Linux/Mac):**
```bash
# Navigate to this folder
cd assets/models/

# Download from a public URL (example)
wget https://github.com/your-username/chess-models/releases/download/v1.0/chess_yolov8.tflite
```

**Using PowerShell (Windows):**
```powershell
# Download pre-trained model
Invoke-WebRequest -Uri "YOUR_MODEL_URL" -OutFile "chess_yolov8.tflite"
```

### Model Specifications

- **Input size**: 640x640
- **Format**: TensorFlow Lite
- **Classes**: 12 (6 white pieces + 6 black pieces)
- **Quantization**: Float32 (for best accuracy) or Int8 (for speed)

### Testing Your Model

Once downloaded, the app will automatically load the model on initialization.
