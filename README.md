# 👑 PrincessScan – Disney Princess Image Classification System

An intelligent **image classification system** powered by **Deep Learning and Convolutional Neural Networks (CNNs)** that accurately identifies **Disney Princess characters** from images. PrincessScan is designed for **academic projects, research demonstrations, and real-world image recognition applications**.

---

## 📋 Overview

**PrincessScan** is a supervised machine learning application that uses computer vision to classify Disney Princess characters from uploaded images. This project showcases a complete **end-to-end deep learning workflow**, from dataset preparation and CNN training to evaluation and deployment readiness.

### Project Scope

* **Type**: Supervised Learning – Image Classification
* **Algorithm**: Convolutional Neural Networks (CNN)
* **Dataset**: Disney Princess Image Dataset
* **Problem**: Multi-class classification
* **Accuracy Target**: 90%+
* **Deployment Ready**: Yes (with inference scripts)

---

## 🎯 Project Objectives

* 👑 Accurately classify Disney Princess characters from images
* 📌 Implement a complete deep learning pipeline
* 🧠 Apply CNNs to a real-world image recognition problem
* 📊 Analyze and visualize model performance
* 📱 Prepare the model for mobile and web deployment
* 🎓 Demonstrate practical AI & ML skills for academic use

---

## 🛠️ Technology Stack

| Component                 | Technology              |
| ------------------------- | ----------------------- |
| **Language**              | Python 3.8+             |
| **Deep Learning**         | TensorFlow / Keras      |
| **Image Processing**      | OpenCV, PIL             |
| **Data Analysis**         | NumPy, Pandas           |
| **Visualization**         | Matplotlib, Seaborn     |
| **ML Utilities**          | Scikit-learn            |
| **Notebooks**             | Jupyter / Google Colab  |
| **Deployment (Optional)** | Flask / TensorFlow Lite |

---

## 📂 Project Structure

Alarcio_Disney_Princess_FinalProject/
│
├── Images/
│ ├── AccuracyPerClass.png
│ ├── AccuracyPerEpoch_Loss.png
│ └── Confusion_matrix.png
│
├── models/
├── notebooks/
├── src/
├── requirements.txt
├── README.md
└── LICENSE

yaml
Copy code

---

## 📊 Dataset Information

### 🎭 Princess Class Labels

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

---

## 📈 Model Performance

| Metric              | Score |
| ------------------- | ----- |
| Training Accuracy   | 96%   |
| Validation Accuracy | 94%   |
| Testing Accuracy    | 93%   |
| F1-Score            | 0.93  |

---

## 📸 Sample Results Visualization

![Accuracy Per Class](Images/AccuracyPerClass.png)

**Figure 1:** Classification accuracy for each Disney Princess class.

![Training Accuracy and Loss](Images/AccuracyPerEpoch_Loss.png)

**Figure 2:** Training accuracy and loss per epoch during CNN training.

![Confusion Matrix](Images/Confusion_matrix.png)

**Figure 3:** Confusion matrix showing class-wise prediction performance of the model.

---

## 🚧 Development Status

* [x] Dataset preparation
* [x] Data preprocessing & augmentation
* [x] CNN model design
* [x] Model training & tuning
* [x] Performance evaluation
* [x] Prediction script
* [ ] Mobile optimization
* [ ] Web API deployment

---

## 🎓 Educational Value

This project demonstrates:
* End-to-end CNN pipeline
* Multi-class image classification
* Model evaluation and visualization
* Deployment-ready ML workflow

---

## 👤 Author

**Ronela Alarcio**  
**Program**: BS Information Technology (BSIT)  
**Project Type**: Final Project  
**Year**: 2025  

---

✨ *Classifying Disney Princesses with AI — one image at a time!* 👑🧠
