# 🌐 Cloud Speech API 3 Ways Challenge Lab

### 📖 Lab: [ARC132](https://www.cloudskillsboost.google/course_templates/700/labs/461583)

--- 

Watch the full video walkthrough for this lab:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://www.youtube.com/watch?v=wjSrI-UHmM8)

---
## ⚠️ **Important Note:**
This guide is provided to support your educational journey in this lab. Please open and review each step of the script to gain full understanding. Be sure to follow the terms of Qwiklabs and YouTube’s guidelines as you proceed.

---

## 🛠️ Steps to Complete the Lab

1. **Log in with Username and Password** in the Google Cloud Console.

2. **Run the following commands** in **Cloud Shell** :

    ```bash
    export ZONE=$(gcloud compute instances list lab-vm --format 'csv[no-heading](zone)')
    gcloud compute ssh lab-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
    ```

    ### Open Credentials from [here](https://console.cloud.google.com/apis/credentials)

    ```bash
    export API_KEY=
    export task_2_file_name=""
    export task_3_request_file=""
    export task_3_response_file=""
    export task_4_sentence=""
    export task_4_file=""
    export task_5_sentence=""
    export task_5_file=""
    ```

    ```bash
    curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Multiple%20VPC%20Networks/arcadecrew.sh

    sudo chmod +x arcadecrew.sh

    ./arcadecrew.sh
    ```
---

### 🏆 Congratulations! You've completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp Group](https://chat.whatsapp.com/FbVg9NI6Dp4CzfdsYmy0AE)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---
