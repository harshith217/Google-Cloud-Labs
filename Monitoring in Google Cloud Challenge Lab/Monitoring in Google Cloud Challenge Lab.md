# 🌐 Monitoring in Google Cloud: Challenge Lab 

### 📖 Lab: [ARC115](https://www.cloudskillsboost.google/focuses/63855?parent=catalog)

--- 

🎥 Watch the full video walkthrough for this lab:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://www.youtube.com/watch?v=wjSrI-UHmM8)

---
## ⚠️ **Important Note:**
This guide is provided to support your educational journey in this lab. Please open and review each step of the script to gain full understanding. Be sure to follow the terms of Qwiklabs and YouTube’s guidelines as you proceed.

---

## 🚀 Quick Start Commands for CloudShell  
Run the following commands step by step:  

```bash
curl -LO 

sudo chmod +x arcadecrew.sh

./arcadecrew.sh
```

---

## 🛠️ Follow the Video Instructions  
Watch the video [here](https://youtu.be/bJmehGefeek) and follow these steps to complete the lab.  

### 1️⃣ **Create an Uptime Check**  
- Go to the [Uptime Check Console](https://console.cloud.google.com/monitoring/uptime/create?).  
- Set the Title to **`arcadecrew`**.  

---

### 2️⃣ **Set Up Dashboards**  
- Navigate to the [Dashboards Console](https://console.cloud.google.com/monitoring/dashboards?).  
- Add two line charts:  
  1. **CPU Load (1m)**: Filter by the VM’s Resource Metric.  
  2. **Requests**: Filter for Apache Web Server metrics.  

---

### 3️⃣ **Create a Log-Based Metric**  
- Go to the [Log-Based Metrics Console](https://console.cloud.google.com/logs/metrics/edit?).  
- Set the **Metric Name** to **`arcadecrew`**.  

#### Apply Filters:  
- **Build Filter**: Replace `PROJECT_ID` and paste this:  
  ```bash
  resource.type="gce_instance"
  logName="projects/PROJECT_ID/logs/apache-access"
  textPayload:"200"
  ```  

- **Regular Expression**:  
  ```bash
  execution took (\d+)
  ```

---

### 🏆 Congratulations! You've completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp Group](https://chat.whatsapp.com/FbVg9NI6Dp4CzfdsYmy0AE)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---