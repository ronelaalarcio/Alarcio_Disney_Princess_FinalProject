# 👑 Disney Princess Image Classification – Machine Learning Final Project

A comprehensive machine learning project utilizing Convolutional Neural Networks (CNNs) and deep learning to automatically classify Disney Princess characters from images. This final project demonstrates an end-to-end ML pipeline with real-world computer vision applications.

---

## 📋 Overview

This project applies deep learning and computer vision techniques to classify images of 10 Disney Princess characters. The model learns visual features such as facial structure, hairstyle, clothing color, and accessories to accurately identify each princess.

### Project Scope
- **Type**: Supervised Learning – Image Classification  
- **Algorithm**: Convolutional Neural Networks (CNN)  
- **Dataset**: Custom-collected Disney Princess images  
- **Problem**: Multi-class image classification (10 classes)  
- **Accuracy Target**: 90%+  
- **Deployment Ready**: Yes (prediction scripts included)

---

## 🎯 Project Objectives

- 📌 Build a high-accuracy image classification model  
- 📌 Implement a complete ML pipeline (data → model → evaluation)  
- 📌 Apply CNNs to real-world image classification  
- 📌 Analyze and visualize model performance  
- 📌 Create reusable training and prediction scripts  
- 📌 Demonstrate production-ready ML practices  

---

## 🛠️ Technology Stack

| Component | Technology |
|----------|-----------|
| Language | Python 3.8+ |
| Deep Learning | TensorFlow / Keras |
| Data Processing | NumPy, Pandas |
| Image Processing | OpenCV, PIL |
| Visualization | Matplotlib, Seaborn |
| ML Utilities | Scikit-learn |
| Notebooks | Jupyter / Google Colab |

---

## 📂 Project Structure

```text
Alarcio_Disney_Princess_FinalProject/
│
├── data/
│   ├── raw/
│   │   └── princess_images/
│   │       ├── Anna/
│   │       ├── Ariel/
│   │       ├── Belle/
│   │       ├── Cinderella/
│   │       ├── Elsa/
│   │       ├── Jasmine/
│   │       ├── Merida/
│   │       ├── Moana/
│   │       ├── Mulan/
│   │       └── Rapunzel/
│   │
│   └── processed/
│       ├── train/
│       ├── val/
│       └── test/
│
├── models/
│   ├── trained_model.h5
│   ├── model_weights.h5
│   └── model_architecture.json
│
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   ├── 02_data_preprocessing.ipynb
│   ├── 03_model_development.ipynb
│   ├── 04_model_training.ipynb
│   └── 05_evaluation_analysis.ipynb
│
├── src/
│   ├── __init__.py
│   ├── preprocessing.py
│   ├── model.py
│   ├── train.py
│   ├── evaluate.py
│   └── predict.py
│
├── Images/
│   ├── AccuracyPerClass.png
│   ├── AccuracyPerEpoch_Loss.png
│   └── Confusion_matrix.png
│
├── results/
│   └── classification_report.txt
│
├── requirements.txt
├── README.md
└── LICENSE
📊 Dataset Information
Princess Classes
Anna

Ariel

Belle

Cinderella

Elsa

Jasmine

Merida

Moana

Mulan

Rapunzel

Dataset Details
Image Size: 150 × 150 pixels

Color Space: RGB

Data Split: 60% Train / 20% Validation / 20% Test

Normalization: Pixel values scaled to [0, 1]

Augmentation: Rotation, Flip, Zoom, Brightness

🧠 CNN Architecture
text
Copy code
Input Layer (150×150×3)
↓
Conv2D + ReLU + BatchNorm
↓
MaxPooling
↓
Conv2D + ReLU + BatchNorm
↓
MaxPooling
↓
Conv2D + ReLU + BatchNorm
↓
MaxPooling
↓
Flatten
↓
Dense (256) + Dropout
↓
Dense (128) + Dropout
↓
Output Layer (10) + Softmax
⚙️ Training Configuration
python
Copy code
optimizer = Adam(learning_rate=0.001)
loss = CategoricalCrossentropy()
metrics = ['accuracy']

model.fit(
    train_data,
    validation_data=val_data,
    epochs=50,
    batch_size=32,
    callbacks=[
        EarlyStopping(patience=5),
        ReduceLROnPlateau(patience=3)
    ]
)
📈 Performance Summary
Training Accuracy: ~96%

Validation Accuracy: ~94%

Test Accuracy: ~93%

Best Classified: Rapunzel, Merida

Most Confused: Elsa ↔ Anna

📊 Results Visualization

Figure 1: Accuracy per Disney Princess class.


Figure 2: Training and validation accuracy and loss.


Figure 3: Confusion matrix showing prediction results.

🚀 Usage
Train the Model
bash
Copy code
python src/train.py
Predict an Image
bash
Copy code
python src/predict.py --image path/to/image.jpg
Evaluate the Model
bash
Copy code
python src/evaluate.py
🚧 Known Limitations
Similar character appearances may cause confusion

Performance depends on image quality and lighting

Model trained only on selected princess classes

🔮 Future Improvements
Increase dataset size

Apply transfer learning (MobileNet / ResNet)

Convert model to TensorFlow Lite

Integrate with mobile application

Add real-time camera classification

🎓 Educational Value
This project demonstrates:

Complete machine learning pipeline

CNN-based image classification

Dataset preprocessing and augmentation

Model evaluation and analysis

Real-world ML application

📄 License
This project is intended for academic and educational purposes.

👤 Author
Rone La Alarcio
BS Information Technology (BSIT)
Final Project – Machine Learning
December 2025
