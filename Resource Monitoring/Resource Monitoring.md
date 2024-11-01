
# 🌐 Resource Monitoring

### 📖 Lab: [Resource Monitoring](https://www.cloudskillsboost.google/paths/12/course_templates/49/labs/470060?locale=en)

--- 

Watch the full video walkthrough for this lab:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://www.youtube.com/watch?v=wjSrI-UHmM8)

---
## ⚠️ **Important Note:**
This guide is provided to support your educational journey in this lab. Please open and review each step of the script to gain full understanding. Be sure to follow the terms of Qwiklabs and YouTube’s guidelines as you proceed.

---
## Task 1: Create a Cloud Monitoring Workspace

1. **Verify Resources:**
   - In the Google Cloud Console, go to **Compute Engine > VM Instances**.
   - Confirm the existence of instances: `nginxstack-1`, `nginxstack-2`, and `nginxstack-3`.

2. **Create Monitoring Workspace:**
   - Run the following command in Cloud Shell:
     ```bash
     gcloud monitoring workspaces create --project=$(gcloud config get-value project)
     ```

---

## Task 2: Custom Dashboards

1. **Create Dashboard:**
   - In the Monitoring Console, go to **Dashboards** and click **+ Create Dashboard**.
   - Name the dashboard: **My Dashboard**.

2. **Add a Chart:**
   - Click **Add Widget** > **Line**.
   - Set **Widget Title** to a descriptive name.
   - In the **Metric** field, select **CPU usage** or **CPU utilization** from **VM Instance > Instance**.
   - If you don’t see it, uncheck **Active**.
   - Add a filter if needed, then click **Apply**.

3. **Metrics Explorer:**
   - Go to **Metrics Explorer** in the Monitoring Console.
   - Select **CPU usage** or a similar metric to recreate the chart from above.

---

## Task 3: Alerting Policies

### Create an Alerting Policy and Add First Condition:

1. Go to **Alerting** in the Monitoring Console and click **+ Create Policy**.
2. Select **CPU usage** or **CPU utilization** from **VM Instance > Instance**. 
   - If you don’t see it, uncheck **Active**.
3. Set **Rolling window** to **1 min** and **Threshold** to **Above Threshold** with a value of **20**.

### Add Second Condition:

1. Click **+ ADD ALERT CONDITION** and repeat the steps for another instance.
2. Set **Multi-condition trigger** to **All conditions are met**.

### Configure Notifications:

1. Open **Notification Channels** and add an email notification with your personal email.
2. Return to **Configure notifications and finalize alert** tab, refresh **Notification Channels**, and select your email.

### Save Alert Policy:

1. Enter a name for the alert policy.
2. Click **Create Policy**.

---

## Task 4: Resource Groups

### Create a Group:

1. Go to **Groups** in the Monitoring Console and click **+ Create Group**.
2. Enter a name, such as **VM instances**, and set criteria to contain **nginx**.

### Review Group Dashboard:

- After creating the group, a dashboard for this group will be displayed automatically.

---

## Task 5: Uptime Monitoring

### Create Uptime Check:

1. In **Monitoring**, go to **Uptime Checks** and click **+ Create Uptime Check**.
2. Set the following options:
   - **Protocol**: HTTP
   - **Resource Type**: Instance
   - **Applies To**: Group
   - **Group**: Select the group created in Task 4.
   - **Check Frequency**: 1 minute
3. Click **Continue** to use default settings for the other options.

### Configure Notifications:

1. Select the **Notification Channel** created in Task 3, then click **Continue**.

### Finalize and Test Uptime Check:

1. Enter a title, then click **Test** to verify the check.
2. Once verified with a green check, click **Create**.

---

### 🏆 Congratulations! You've completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp Group](https://chat.whatsapp.com/FbVg9NI6Dp4CzfdsYmy0AE)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---
