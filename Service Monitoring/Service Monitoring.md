# 🌐 [Service Monitoring](https://www.cloudskillsboost.google/focuses/19476?parent=catalog)

--- 

🎥 Watch the full video walkthrough for this lab:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://www.youtube.com/watch?v=wjSrI-UHmM8)

---
## ⚠️ **Important Note:**
This guide is provided to support your educational journey in this lab. Please open and review each step of the script to gain full understanding. Be sure to follow the terms of Qwiklabs and YouTube’s guidelines as you proceed.

---

## 🚀 Steps to Perform
Perform the following step by step:  

## Task 1. Deploy a test application

```bash
curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Service%20Monitoring/arcadecrew.sh

sudo chmod +x arcadecrew.sh

./arcadecrew.sh
```

## Task 2. Use Service Monitoring to create an availability SLO

1. **Navigate to Monitoring**
  - Go to **Monitoring > SLOs** from [here](https://console.cloud.google.com/monitoring/slos).
2. **Define the Service**:
  - Notice that Service Monitoring already sees your default App Engine application. "If it doesn't, wait a minute, refresh the page and click `+Define a service`, select `default`, and submit it."
3. **Create SLO**:
   - Select `default` service.
   - Click **+Create SLO**.
   - Set the metric type to **`Availability`**.
   - Keep the evaluation method as **`Request-based`**.
   - Click **Continue**.
   - Define the SLO:
     - **Period type**: `Rolling`.
     - **Period length**: `7 days`.
     - **Goal**: `99.5%`.
   - Click **`Create SLO`**.
2. In your newly created SLO and click on the **`Alerts firing`** tab.
3. Click on **`CREATE SLO ALERT`**.
4. Set the following parameters:
   - **Display name**: `Really short window test`
   - **Lookback duration**: `10 minutes`
   - **Burn rate threshold**: `1.5`
5. Click **`Next`**.
6. Under **`Notification Channels`**, click **`Manage Notification Channels`**:
   - Select **`Email`** as the type.
   - Enter your `Username` as email address and give **Display Name** as `Arcade Crew`.
7. Return to the alert creation process, select the email notification channel you just created, and click **`Next`**.
8. Skip the **`Steps to fix the issue`** field and click **`Save`**.

9. Redeploy the change to App Engine
  ```bash
  gcloud app deploy
  ```

- Type `y` when prompted to confirm the deployment.
- Wait for the deployment to complete.


---

### 🏆 Congratulations! You've completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---
