---
inclusion: fileMatch
fileMatchPattern: "**/{vision/**,detection/**,segmentation/**,models/**,*.ipynb,dataset.yaml}"
---

# Senior Computer Vision Engineer

Production computer vision engineering for object detection, segmentation, and visual AI deployment.

---

## Architecture Selection

| Requirement | Architecture | Rationale |
|-------------|-------------|-----------|
| Real-time (>30 FPS) | YOLOv8/v11, RT-DETR | Single-stage, speed-optimized |
| High accuracy | Faster R-CNN, DINO | Two-stage, better localization |
| Small objects | YOLO + SAHI, Faster R-CNN + FPN | Multi-scale feature pyramids |
| Edge deployment | YOLOv8n, MobileNetV3-SSD | Lightweight, quantization-friendly |
| Transformer-based | DETR, DINO, RT-DETR | End-to-end, no NMS required |
| Instance segmentation | Mask R-CNN, YOLACT | Per-instance masks |
| Semantic segmentation | SegFormer, DeepLabV3+ | Per-pixel class labels |

---

## Code Conventions

- Use `torch.no_grad()` for all inference paths — never skip this
- Always move tensors to the correct device explicitly; avoid implicit device assumptions
- Normalize inputs using dataset-specific mean/std, not hardcoded ImageNet values unless transfer learning
- Use `half=True` (FP16) for GPU inference unless precision is critical
- Validate `conf` and `iou` thresholds against your dataset — defaults are rarely optimal
- Log `mAP50` and `mAP50-95` together; never report only one
- Pin library versions in `requirements.txt` — CV dependencies break frequently across versions

---

## Detection Pipeline

### Training (YOLOv8)

```python
from ultralytics import YOLO

model = YOLO("yolov8n.pt")  # n=speed, x=accuracy
results = model.train(
    data="dataset.yaml",
    epochs=100,
    imgsz=640,
    batch=16,
    device="cuda",
    project="runs/detect",
    name="experiment_v1",
)

metrics = model.val()
print(f"mAP50: {metrics.box.map50:.3f}, mAP50-95: {metrics.box.map:.3f}")
```

### Dataset YAML

```yaml
path: /data/my_dataset
train: images/train
val: images/val
test: images/test
nc: 3
names: ["cat", "dog", "bird"]
```

### Inference

```python
from ultralytics import YOLO
import cv2

model = YOLO("runs/detect/experiment_v1/weights/best.pt")

# Image
results = model("image.jpg", conf=0.5, iou=0.45)
for r in results:
    boxes = r.boxes.xyxy.cpu().numpy()
    scores = r.boxes.conf.cpu().numpy()
    classes = r.boxes.cls.cpu().numpy().astype(int)

# Video with tracking
for result in model.track("video.mp4", stream=True, tracker="bytetrack.yaml"):
    cv2.imshow("Detection", result.plot())
```

---

## Data Augmentation

Use `albumentations` with bbox-aware transforms. Always pass `bbox_params` when augmenting detection data.

```python
import albumentations as A
from albumentations.pytorch import ToTensorV2

train_transform = A.Compose([
    A.RandomResizedCrop(640, 640, scale=(0.5, 1.0)),
    A.HorizontalFlip(p=0.5),
    A.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
    A.GaussNoise(p=0.1),
    A.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ToTensorV2(),
], bbox_params=A.BboxParams(format="yolo", label_fields=["class_labels"]))
```

---

## Production Export & Optimization

### ONNX

```python
model.export(format="onnx", opset=17, simplify=True, dynamic=False, imgsz=640)
```

### TensorRT (FP16)

```python
model.export(format="engine", device=0, half=True)
```

### Benchmark

```python
model.benchmark(data="dataset.yaml", imgsz=640, half=True, device=0)
# Reports: Format | mAP50-95 | Inference (ms) | FPS
```

---

## Performance Targets

| Deployment | Target FPS | Model |
|------------|-----------|-------|
| Cloud GPU (A100) | >200 | YOLOv8x or DINO |
| Edge GPU (Jetson) | >30 | YOLOv8s + TensorRT |
| Mobile (iOS/Android) | >15 | YOLOv8n + CoreML/TFLite |
| CPU only | >5 | YOLOv8n + ONNX |

---

## Tech Stack

| Category | Tools |
|----------|-------|
| Frameworks | PyTorch, torchvision, timm |
| Detection | Ultralytics (YOLO), Detectron2, MMDetection |
| Segmentation | SAM (segment-anything), mmsegmentation |
| Optimization | ONNX, TensorRT, OpenVINO, torch.compile |
| Image Processing | OpenCV, Pillow, albumentations |
| Annotation | CVAT, Label Studio, Roboflow |
| Experiment Tracking | MLflow, Weights & Biases |
| Serving | Triton Inference Server, TorchServe |
