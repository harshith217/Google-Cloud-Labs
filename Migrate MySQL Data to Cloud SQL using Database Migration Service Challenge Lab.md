# 🚀 **Migrate MySQL Data to Cloud SQL using Database Migration Service: Challenge Lab || GSP351**  
[![Open Lab](https://img.shields.io/badge/Open-Lab-brown?style=for-the-badge&logo=google-cloud&logoColor=white)](https://www.cloudskillsboost.google/focuses/20393?parent=catalog)  

---

## ⚠️ **Important Notice**  
This guide is crafted to elevate your learning experience during this lab. Carefully follow each step to grasp the concepts fully. Ensure compliance with **Qwiklabs** and **YouTube** policies while using this guide.  

---

## **🔌 Connect to the MySQL Interactive Console**  

To connect to the MySQL interactive console, follow these steps:  

1. Open your terminal and execute the following command:  
   ```bash
   mysql -u admin -p
   ```  

2. When prompted for the password, enter:  
   ```bash
   changeme
   ```  

---

## **🛠️ Update Records in the Database**  

Once connected to the MySQL console:  

1. Switch to the `customers_data` database:  
   ```sql
   use customers_data;
   ```  

2. Update the `gender` field for a specific record using the following SQL command:  
   ```sql
   update customers set gender = 'FEMALE' where addressKey = 934;
   ```  

---

## 🎉 **Congratulations! You've Successfully Completed the Lab!** 🏆  

---

## 🤝 **Join the Arcade Crew Community!**  

Stay connected and explore more with our vibrant community:  

- **WhatsApp Group:** [Join Here](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  
- **YouTube Channel:** [![Subscribe to Arcade Crew](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)  

---