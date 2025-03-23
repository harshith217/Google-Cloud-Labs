# ✨ Monitoring in Google Cloud: Challenge Lab || ARC115

[![Lab Link](https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://www.cloudskillsboost.google/focuses/63855?parent=catalog)

---

## ⚠️ Disclaimer

<div style="padding: 15px; margin-bottom: 20px;">
<p><strong>Educational Purpose Only:</strong> This script and guide are intended solely for educational purposes to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.</p>

<p><strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—not to circumvent it.</p>
</div>

---

## ⚙️ Lab Environment Setup

<details open>

<div style="padding: 15px; margin: 10px 0;">
<p><strong>☁️ Run in Cloud Shell:</strong></p>

```bash
curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Monitoring%20in%20Google%20Cloud%20Challenge%20Lab/arcadecrew.sh
sudo chmod +x arcadecrew.sh
./arcadecrew.sh
```
</div>

</details>

---

<details>
<summary><h3>📊 Task 1: Set Up Monitoring Dashboards</h3></summary>

<div style="padding: 15px; margin: 10px 0;">

1. Navigate to the [Monitoring Dashboards Console](https://console.cloud.google.com/monitoring/dashboards)

2. Create a new custom dashboard with the following charts:

   | Chart Type | Metric | Filter |
   |------------|--------|--------|
   | 📈 Line Chart | CPU Load (1m) | VM Resource Metric |
   | 📉 Line Chart | Requests | Apache Web Server metrics |

</div>
</details>

---

<details>
<summary><h3>📝 Task 2: Create a Log-Based Metric</h3></summary>

<div style="padding: 15px; margin: 10px 0;">

1. Navigate to the [Log-Based Metrics Console](https://console.cloud.google.com/logs/metrics/edit)

2. Create a new user-defined metric with these specifications:
   - **Metric Name:** `arcadecrew`

3. Configure the log filter:
   ```bash
   resource.type="gce_instance"
   logName="projects/PROJECT_ID/logs/apache-access"
   textPayload:"200"
   ```
   > ⚠️ **Important:** Replace `PROJECT_ID` with your actual project ID

4. Configure field extraction:
   - **Regular Expression:**
   ```bash
   execution took (\d+)
   ```

5. Verify and create the metric

</div>
</details>

---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

<div align="center" style="padding: 5px;">
  <h3>📱 Join the Arcade Crew Community</h3>
  
  <a href="https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F">
    <img src="https://img.shields.io/badge/Join_WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="Join WhatsApp">
  </a>
  &nbsp;
  <a href="https://www.youtube.com/@Arcade61432?sub_confirmation=1">
    <img src="https://img.shields.io/badge/Subscribe-Arcade%20Crew-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel">
  </a>
  &nbsp;
  <a href="https://www.linkedin.com/in/gourav61432/">
    <img src="https://img.shields.io/badge/LINKEDIN-Gourav%20Sen-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
</a>


</div>

---

<div align="center">
  <p style="font-size: 12px; color: #586069;">
    <em>This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.</em>
  </p>
  <p style="font-size: 12px; color: #586069;">
    <em>Last updated: March 2025</em>
  </p>
</div>
