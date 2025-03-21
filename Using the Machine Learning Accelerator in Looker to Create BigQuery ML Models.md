# ✨ Using the Machine Learning Accelerator in Looker to Create BigQuery ML Models
[![Lab Link](https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)

---

### ⚠️ Disclaimer  
- **This script and guide are intended solely for educational purposes to help you better understand lab services and advance your career. Before using the script, please review it carefully to become familiar with Google Cloud services. Always ensure compliance with Qwiklabs’ terms of service and YouTube’s community guidelines. The aim is to enhance your learning experience—not to circumvent it.**

---

## ⚙️ Lab Environment Setup

### Task 1: Explore Customer Churn Data
1. **Navigate to Data**: Click the main menu, select "**Telco Customer Churn**" from Explore.
2. **Calculate Churn Rate**: Add "**Churn Rate**" to the Data pane and run the query.
3. **Check Churn Rate by Service Calls**: Add "**Service Calls Group**" dimension, sort values, and run the query.

### Task 2: Create a Binary Classification ML Model
1. **Open ML Accelerator**: From the main menu, navigate to "**Browse**", then "**Applications**", and select "**Machine Learning Accelerator**".
2. **Create New Model**: Click "**Create New Model**".
3. **Select Objective**: Choose "**Classification**" for predicting churn.
4. **Select Input Data**: 
   - Choose "**Telco Customer Churn**" Explore.
   - Filter on "**Dataframe**" to "**train**".
   - Select "**Customer ID**", "**Churn**", and relevant features mentioned below.
| **Dimensions** | **Measures** |
|---------------|-------------|
| Account Duration Months | Total Day Calls |
| International Plan (Yes/No) | Total Day Charge |
| State | Total Day Minutes |
| Voice Mail Plan (Yes/No) | Total Eve Calls |
| | Total Eve Charge |
| | Total Eve Minutes |
| | Total Intl Calls |
| | Total Intl Charge |
| | Total Intl Minutes |
| | Total Night Calls |
| | Total Night Charge |
| | Total Night Minutes |
| | Total Service Calls |
| | Total Vmail Messages |

   - Run the query and continue.
5. **Model Options**: 
   - Name the model using your Project ID (replace hyphens with underscores).
   - Select the target field "**Customer Churn**".
   - Generate Summary.
6. **Advanced Settings**:
   - Adjust data split to 75% training and 25% testing.
7. **Create Model**: Click "**Create Model**" and wait for it to finish training.


---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

---

<div align="center">
  <p><strong>Visit Arcade Crew Community for more learning resources!</strong></p>
  
  <a href="https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F">
    <img src="https://img.shields.io/badge/Join_WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="Join WhatsApp">
  </a>
  &nbsp;
  <a href="https://www.youtube.com/@Arcade61432?sub_confirmation=1">
    <img src="https://img.shields.io/badge/Subscribe-YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel">
  </a>
</div>

<br>

> *Note: This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.*

---
