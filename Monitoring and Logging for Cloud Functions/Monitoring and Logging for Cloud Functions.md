# 🌐 [Monitoring and Logging for Cloud Functions || GSP092](https://www.cloudskillsboost.google/focuses/1833?parent=catalog)

--- 

🎥 Watch the full video walkthrough for this lab:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://youtu.be/arAgNA6D2Nw)

---
## ⚠️ **Important Note:**
This guide is provided to support your educational journey in this lab. Please open and review each step of the script to gain full understanding. Be sure to follow the terms of Qwiklabs and YouTube’s guidelines as you proceed.

---

## 🚀 Steps to Perform

Run in Cloudshell:  
```bash
curl -LO 'https://github.com/tsenart/vegeta/releases/download/v6.3.0/vegeta-v6.3.0-linux-386.tar.gz'

tar xvzf vegeta-v6.3.0-linux-386.tar.gz

gcloud logging metrics create CloudFunctionLatency-Logs --project=$DEVSHELL_PROJECT_ID --description="Subscribe to Arcade Crew" --log-filter='resource.type="cloud_function"
resource.labels.function_name="helloWorld"'
```
---

### 🏆 Congratulations! You've completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)

---
