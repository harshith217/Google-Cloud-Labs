# 🌐 [Using BigQuery and Cloud Logging to Analyze BigQuery Usage || GSP617](https://www.cloudskillsboost.google/focuses/6100?parent=catalog)

--- 

🎥 Watch the full video walkthrough for this lab:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://www.youtube.com/watch?v=wjSrI-UHmM8)

---
## ⚠️ **Important Note:**
This guide is provided to support your educational journey in this lab. Please open and review each step of the script to gain full understanding. Be sure to follow the terms of Qwiklabs and YouTube’s guidelines as you proceed.

---

## 🚀 Steps to Perform

Run in Cloudshell:  

```
bq mk bq_logs
bq query --use_legacy_sql=false "SELECT current_date()"
```
```
resource.type="bigquery_resource"
protoPayload.methodName="jobservice.jobcompleted"
```
### Create Sink name: `JobComplete`

```bash
curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Using%20BigQuery%20and%20Cloud%20Logging%20to%20Analyze%20BigQuery%20Usage/arcadecrew.sh

sudo chmod +x arcadecrew.sh

./arcadecrew.sh
```
---

### 🏆 Congratulations! You've completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)

---
