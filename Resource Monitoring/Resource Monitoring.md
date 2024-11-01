
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
   - On the Google Cloud console title bar, type Monitoring in the Search field, then click Monitoring in the Products & Page section.

   - Wait for your workspace to be provisioned.

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

1. **Create a Monitoring Group:**

   ```bash
   gcloud alpha monitoring groups create        --display-name="VM instances"        --filter="resource.label.instance_id=~\"nginx\""
   ```

   

---

## Task 5: Uptime Monitoring

1. **Create an Uptime Check:**

   ```bash
   gcloud alpha monitoring uptime-checks create http        --display-name="My Uptime Check"        --http-check-path="/"        --timeout="10s"        --check-frequency="60s"        --resource-type="gce_instance"        --group="VM instances"
   ```

   

---

## Task 6: Disable the Alert

1. **Disable an Alert Policy:**

   

     ```bash
     POLICY_NAME=$(gcloud alpha monitoring policies list --filter="displayName:High CPU Utilization Alert" --format="value(name)")
     gcloud alpha monitoring policies update "$POLICY_NAME" --enabled=false
     ```

   

---

### 🏆 Congratulations! You've completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp Group](https://chat.whatsapp.com/FbVg9NI6Dp4CzfdsYmy0AE)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---
