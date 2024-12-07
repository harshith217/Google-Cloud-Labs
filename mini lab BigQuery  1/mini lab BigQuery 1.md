# 🌐 mini lab: BigQuery : 1

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
read -p "Enter BUCKET NAME: " BUCKET_NAME


bq mk work_day

bq mk --table work_day.employee \
    employee_id:INTEGER,device_id:STRING,username:STRING,department:STRING,office:STRING

bq load --source_format=CSV --skip_leading_rows=1 work_day.employee gs://$BUCKET_NAME/employees.csv employee_id:INTEGER,device_id:STRING,username:STRING,department:STRING,office:STRING

```

---

### 🏆 Congratulations! You've completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---
