# 👑 PrincessScan – Disney Princess Image Classification System

An intelligent **image classification system** powered by **Deep Learning and Convolutional Neural Networks (CNNs)** that accurately identifies **Disney Princess characters** from images. PrincessScan is designed for **academic projects, research demonstrations, and real-world image recognition applications**.

---

## 📋 Overview

**PrincessScan** is a supervised machine learning application that uses computer vision to classify Disney Princess characters from uploaded images. This project demonstrates a complete **end-to-end deep learning pipeline**, from dataset preparation and model training to evaluation and deployment readiness.

### Project Scope
- **Type**: Supervised Learning – Image Classification  
- **Algorithm**: Convolutional Neural Networks (CNN)  
- **Dataset**: Disney Princess Image Dataset  
- **Problem**: Multi-class classification  
- **Accuracy Target**: 90%+  
- **Deployment Ready**: Yes, with inference scripts

---

## 🎯 Project Objectives

- 👑 Accurately classify Disney Princess characters from images  
- 📌 Implement a complete deep learning workflow  
- 🧠 Apply CNNs to real-world image recognition problems  
- 📊 Analyze and visualize model performance  
- 📱 Prepare the model for mobile and web deployment  
- 🎓 Demonstrate practical AI & ML skills for academic use  

---

## 🛠️ Technology Stack

| Component                 | Technology              |
| ------------------------- | ---------------------- |
| **Language**              | Python 3.8+            |
| **Deep Learning**         | TensorFlow / Keras     |
| **Image Processing**      | OpenCV, PIL            |
| **Data Analysis**         | NumPy, Pandas          |
| **Visualization**         | Matplotlib, Seaborn    |
| **ML Utilities**          | Scikit-learn           |
| **Notebooks**             | Jupyter / Google Colab |
| **Deployment (Optional)** | Flask / TensorFlow Lite|

---

## 📂 Project Structure

Alarcio_Disney_Princess_FinalProject/
│
├── data/
│ ├── raw/
│ │ └── princess_images/
│ │ ├── Anna/
│ │ ├── Belle/
│ │ ├── Ariel/
│ │ ├── Cinderella/
│ │ ├── Jasmine/
│ │ ├── Mulan/
│ │ ├── Rapunzel/
│ │ ├── Moana/
│ │ ├── Elsa/
│ │ └── Merida/
│ └── processed/
│ ├── train/
│ ├── val/
│ └── test/
│
├── models/
│ ├── trained_model.h5
│ ├── model_weights.h5
│ └── model_architecture.json
│
├── notebooks/
│ ├── 01_data_exploration.ipynb
│ ├── 02_data_preprocessing.ipynb
│ ├── 03_model_development.ipynb
│ ├── 04_model_training.ipynb
│ └── 05_evaluation_analysis.ipynb
│
├── src/
│ ├── init.py
│ ├── preprocessing.py
│ ├── model.py
│ ├── train.py
│ ├── evaluate.py
│ └── predict.py
│
├── Images/ # All result images
│ ├── AccuracyPerClass.png
│ ├── AccuracyPerEpoch_Loss.png
│ └── Confusion_matrix.png
│
├── results/
│ └── classification_report.txt
│
├── requirements.txt
├── README.md
└── LICENSE

yaml
Copy code

---

## 📊 Dataset Information

### Princess Class Labels

| Class ID | Princess Name |
| -------- | ------------- |
| 0        | Anna          |
| 1        | Belle         |
| 2        | Ariel         |
| 3        | Cinderella    |
| 4        | Jasmine       |
| 5        | Mulan         |
| 6        | Rapunzel      |
| 7        | Moana         |
| 8        | Elsa          |
| 9        | Merida        |

### Dataset Characteristics

- **Total Classes**: 10 Disney Princesses  
- **Image Size**: 150 × 150 pixels  
- **Color Space**: RGB  
- **Format**: JPG / PNG  
- **Split Ratio**:  
  - Training: 60%  
  - Validation: 20%  
  - Testing: 20%  

**Data Augmentation:**

- Rotation (±20°)  
- Horizontal Flip  
- Zoom (0.2)  
- Brightness Adjustment  

---

## 🧠 CNN Architecture

INPUT (150×150×3)
↓
Conv2D (32) + ReLU
↓
MaxPooling
↓
Conv2D (64) + ReLU
↓
MaxPooling
↓
Conv2D (128) + ReLU
↓
MaxPooling
↓
Flatten
↓
Dense (256) + ReLU + Dropout(0.5)
↓
Dense (128) + ReLU
↓
Output (10 classes) + Softmax

yaml
Copy code

**Model Specifications:**

| Layer        | Configuration                    |
| ------------ | -------------------------------- |
| Input        | 150×150×3 RGB images             |
| Conv Block 1 | 32 filters, 3×3 kernel, ReLU    |
| Conv Block 2 | 64 filters, 3×3 kernel, ReLU    |
| Conv Block 3 | 128 filters, 3×3 kernel, ReLU   |
| Flatten      | Converts 2D to 1D               |
| Dense 1      | 256 units, ReLU, Dropout(0.5)  |
| Dense 2      | 128 units, ReLU                 |
| Output       | 10 units, Softmax               |
| Total Params | ~2.7M trainable parameters      |

---

## 📈 Performance Metrics

| Metric              | Result |
| ------------------- | ------ |
| Training Accuracy   | 96%    |
| Validation Accuracy | 94%    |
| Testing Accuracy    | 93%    |
| Precision           | 93%    |
| Recall              | 94%    |
| F1-Score            | 0.93   |

**Observations:**

- Best classified: **Rapunzel & Merida**  
- Most confused: **Elsa ↔ Anna**  
- Overall performance shows strong generalization

---

## 📸 Results Visualization

> *Images are located in the `Images/` folder.*

![Accuracy Per Class](Images/AccuracyPerClass.png)  
**Figure 1:** Accuracy for each Disney Princess class.

![Accuracy & Loss per Epoch](Images/AccuracyPerEpoch_Loss.png)  
**Figure 2:** Training & validation accuracy and loss per epoch.

![Confusion Matrix](Images/Confusion_matrix.png)  
**Figure 3:** Confusion matrix showing predictions vs actual labels.

---

## 🚧 Development Status

- [x] Dataset preparation  
- [x] Data preprocessing & augmentation  
- [x] CNN model design  
- [x] Model training & tuning  
- [x] Performance evaluation  
- [x] Prediction scripts  
- [ ] Transfer learning (VGG / ResNet)  
- [ ] Mobile optimization (TensorFlow Lite)  
- [ ] Web API deployment  

---

## 🔮 Future Enhancements

**Short-Term:**

- Increase dataset size  
- Try transfer learning (EfficientNet, MobileNet)  
- Hyperparameter tuning  

**Medium-Term:**

- Flask / FastAPI deployment  
- Web interface for image upload  
- REST API documentation  

**Long-Term:**

- Android app integration  
- Real-time camera classification  
- Explainable AI (Grad-CAM)  
- Model compression for edge devices  

---

## 🎓 Educational Value

- End-to-end CNN pipeline  
- Multi-class image classification  
- Deep learning model evaluation  
- Practical AI application design  
- Deployment-ready ML workflow  

---

## 📄 License

This project is developed for **academic and educational purposes** only.

---

## 👤 Author

**Ronela Alarcio**  
- **Program**: BS Information Technology (BSIT)  
- **Project Type**: Final Project  
- **Year**: 2025  

---

✨ *Classifying Disney Princesses with AI — one image at a time!* 👑🧠
