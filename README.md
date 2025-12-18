# 👑 Disney Princess Recognition App 👸✨

A mobile image classification application built with **Flutter** and **TensorFlow Lite**.  
This intelligent app detects and classifies **10 Disney Princess characters** from images using deep learning and computer vision.

---

## 📋 Overview

The **Disney Princess Recognition App** leverages **Convolutional Neural Networks (CNNs)** to recognize Disney Princess characters from images. Users can capture photos using the device camera or select images from the gallery, and the app will instantly classify the princess with confidence scores.

---

## 🎯 Project Scope

This project provides:
- **Image-based princess recognition** from camera and gallery
- **10 Disney Princess classifications**
- **High-accuracy predictions** (>90%)
- **User-friendly Flutter interface**
- **Analytics dashboard** for model performance
- **Educational princess profiles**
- **Cloud integration** using Firebase

---

## 🎓 Project Objectives

1. Develop a real-world CNN-based image classification app  
2. Achieve high classification accuracy for Disney Princess characters  
3. Provide a simple and intuitive user interface  
4. Optimize inference speed for mobile devices  
5. Track model performance through analytics  
6. Demonstrate ethical and educational AI usage  

---

## 🛠️ Technology Stack

### Frontend & Mobile
- **Framework**: Flutter 3.x  
- **Language**: Dart  
- **UI**: Material Design 3  

### Machine Learning
- **Framework**: TensorFlow Lite (TFLite)
- **Model Type**: Convolutional Neural Network (CNN)
- **Model File**: `princess_model.tflite`

### Backend
- **Firebase Core**
- **Cloud Firestore**
- **Firebase Analytics**

---

## 📁 Project Structure

```
Disney_Princess_App/
├── lib/
│ ├── main.dart
│ ├── home_page.dart
│ ├── gallery_page.dart
│ ├── princess_classes_page.dart
│ ├── analytics.dart
│ ├── models/
│ │ └── princess_class.dart
│ ├── widgets/
│ │ ├── app_footer.dart
│ │ └── princess_image_widget.dart
│ └── theme/
├── assets/
│ ├── princess_model.tflite
│ ├── labels.txt
│ └── princess_images/
├── android/
├── ios/
├── web/
├── pubspec.yaml
└── test/
```

---

## 📊 Dataset Information

- **Total Images**: ~1,500  
- **Image Size**: 150 × 150 RGB  
- **Data Split**:
  - 60% Training
  - 20% Validation
  - 20% Testing  

### Princess Classes (10)

| ID | Princess |
|----|----------|
| 1 | Anna |
| 2 | Elsa |
| 3 | Ariel |
| 4 | Belle |
| 5 | Cinderella |
| 6 | Jasmine |
| 7 | Rapunzel |
| 8 | Merida |
| 9 | Moana |
| 10 | Snow White |

---

## 🧠 CNN Architecture

### Model Architecture Diagram
```
Input Layer (150×150×3)
↓
Conv2D + ReLU
↓
MaxPooling
↓
Conv2D + ReLU
↓
MaxPooling
↓
Conv2D + ReLU
↓
MaxPooling
↓
Flatten
↓
Dense (256) + Dropout
↓
Output Layer (10) + Softmax
```

---

## 📈 Performance Metrics

| Metric | Result |
|------|--------|
| Training Accuracy | ~96% |
| Validation Accuracy | ~94% |
| Testing Accuracy | ~93% |
| Precision | ~93% |
| Recall | ~94% |
| F1-Score | ~0.93 |
| Inference Time | ~250–400 ms |

### Insights
- Best classified: **Rapunzel, Merida**
- Most confused: **Elsa ↔ Anna**

---

## 🚀 Development Status

### ✅ Completed
- CNN training and TFLite conversion
- Image classification via camera & gallery
- Confidence score display
- Firebase integration
- Multi-platform Flutter support

### ⏳ Planned
- Transfer learning (MobileNet / ResNet)
- Real-time video classification
- Model quantization
- Mobile deployment enhancements

---

## 📚 Educational Value

- CNN-based image classification
- Dataset preprocessing & augmentation
- Model evaluation and analysis
- Edge AI deployment using TensorFlow Lite
- Cross-platform Flutter development

---

## 📄 License

This project is intended for **academic and educational purposes only**.

---

### 🧑‍💻 Author

**Ronela T. Alarcio**  
BS Information Technology  
Caraga State University  
December 2025
