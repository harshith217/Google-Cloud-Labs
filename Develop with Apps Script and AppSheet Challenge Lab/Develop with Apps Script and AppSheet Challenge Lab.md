# 🎓 **Develop with Apps Script and AppSheet: Challenge Lab**
### LAB: [ARC126](https://www.cloudskillsboost.google/focuses/66584?parent=catalog)
Watch the full video walkthrough:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://youtu.be/nTB6AWZpbaY)

---

## ⚠️ **Important Note:**
This guide is provided to support your educational journey in this lab. Please open and review each step of the script to gain full understanding. Be sure to follow the terms of Qwiklabs and YouTube’s guidelines as you proceed.

---

##  **Task 1: Building and Customizing an AppSheet App**

1. **Login** to **AppSheet**.
2. Access the **[ATM Maintenance App](https://www.appsheet.com/template/AppDef?appName=ATMMaintenance-925818016)** in **Incognito Mode**.
3. Use the left menu to select **Copy app**.
4. In the **Copy app** form, set the **App name** as:

   ```plaintext
   ATM Maintenance Tracker
   ```
   Leave other settings as they are.
5. Click **Copy app** to proceed.

---

##  **Task 2: Integrating Automation in AppSheet**

1. Open **My Drive** from **[this link](https://drive.google.com/drive/my-drive)**.
2. Download the required file **[here](https://gourav8959-my.sharepoint.com/:f:/g/personal/gourav8959_gourav8959_onmicrosoft_com/Ejr59_zDiNRGko-iuLIritwBBmt-46CjuTLVqWpfzy9QeA?e=icLCtw)**.

---

## **Task 3: Creating and Publishing a Google Chat Bot with Apps Script**

1. Start a new **Apps Script Chat App** project from **[this link](https://script.google.com/home/projects/create?template=hangoutsChat)**.

   <table style="width:100%; border:1px solid #cccccc t; border-collapse:collapse; text-align:center; font-family:Arial, sans-serif;">
    <tr style="background-color:#004080; color:#ffffff;">
        <th style="padding:12px; border:1px solid #cccccc;">Property</th>
        <th style="padding:12px; border:1px solid #cccccc;">Value</th>
    </tr>
    <tr style="background-color:#e6f2ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">Project name</td>
        <td style="padding:12px; border:1px solid #cccccc;">Helper Bot</td>
    </tr>
</table>


2. Replace the following code in **Code.gs**:

   ```javascript
   /**
    * Responds to a MESSAGE event in Google Chat.
    *
    * @param {Object} event the event object from Google Chat
    */
   function onMessage(event) {
     var name = "";

     if (event.space.type == "DM") {
       name = "You";
     } else {
       name = event.user.displayName;
     }
     var message = name + " said \"" + event.message.text + "\"";

     return { "text": message };
   }

   /**
    * Responds to an ADDED_TO_SPACE event in Google Chat.
    *
    * @param {Object} event the event object from Google Chat
    */
   function onAddToSpace(event) {
     var message = "";

     if (event.space.singleUserBotDm) {
       message = "Thank you for adding me to a DM, " + event.user.displayName + "!";
     } else {
       message = "Thank you for adding me to " +
           (event.space.displayName ? event.space.displayName : "this chat");
     }

     if (event.message) {
       message = message + " and you said: \"" + event.message.text + "\"";
     }
     console.log('Helper Bot added in ', event.space.name);
     return { "text": message };
   }

   /**
    * Responds to a REMOVED_FROM_SPACE event in Google Chat.
    *
    * @param {Object} event the event object from Google Chat
    */
   function onRemoveFromSpace(event) {
     console.info("Bot removed from ",
         (event.space.name ? event.space.name : "this chat"));
   }
   ```

---

## 🔑 **Configuring OAuth Consent Screen**

1. Go to the **OAuth consent screen** from **[here](https://console.cloud.google.com/apis/credentials/consent)**.

   <table style="width:100%; border:1px solid #cccccc t; border-collapse:collapse; text-align:center; font-family:Arial, sans-serif;">
    <tr style="background-color:#004080; color:#ffffff;">
        <th style="padding:12px; border:1px solid #cccccc;">Field</th>
        <th style="padding:12px; border:1px solid #cccccc;">Value</th>
    </tr>
    <tr style="background-color:#f5f9ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">App name</td>
        <td style="padding:12px; border:1px solid #cccccc;">Helper Bot</td>
    </tr>
    <tr style="background-color:#e9f3ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">User support email</td>
        <td style="padding:12px; border:1px solid #cccccc;">Your selected email</td>
    </tr>
    <tr style="background-color:#f5f9ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">Developer contact</td>
        <td style="padding:12px; border:1px solid #cccccc;">Your email address</td>
    </tr>
</table>


---

## 🛠️ **Setting Up Google Chat API**

1. Visit **Google Chat API Configuration [here](https://console.cloud.google.com/apis/api/chat.googleapis.com/hangouts-chat)**.

   <table style="width:100%; border:1px solid #cccccc; border-collapse:collapse; text-align:left; font-family:Arial, sans-serif;">
    <tr style="background-color:#004080; color:#ffffff;">
        <th style="padding:12px; border:1px solid #cccccc;">Field</th>
        <th style="padding:12px; border:1px solid #cccccc;">Value</th>
    </tr>
    <tr style="background-color:#f3f8ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">App name</td>
        <td style="padding:12px; border:1px solid #cccccc;">Helper Bot</td>
    </tr>
    <tr style="background-color:#e7f0ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">Avatar URL</td>
        <td style="padding:12px; border:1px solid #cccccc;">https://goo.gl/kv2ENA</td>
    </tr>
    <tr style="background-color:#f3f8ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">Description</td>
        <td style="padding:12px; border:1px solid #cccccc;">Helper chat bot</td>
    </tr>
    <tr style="background-color:#e7f0ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">Functionality</td>
        <td style="padding:12px; border:1px solid #cccccc;">Receive 1:1 messages and join spaces/group conversations</td>
    </tr>
    <tr style="background-color:#f3f8ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">Connection settings</td>
        <td style="padding:12px; border:1px solid #cccccc;">Check <b>Apps Script project</b> and add <b>Head Deployment ID</b></td>
    </tr>
    <tr style="background-color:#e7f0ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">Visibility</td>
        <td style="padding:12px; border:1px solid #cccccc;">Your email address</td>
    </tr>
    <tr style="background-color:#f3f8ff; color:#000;">
        <td style="padding:12px; border:1px solid #cccccc;">App Status</td>
        <td style="padding:12px; border:1px solid #cccccc;">LIVE – Available to users</td>
    </tr>
</table>


---

## 🔬 **Testing Your Helper Bot**

You can test your bot directly **[here](https://mail.google.com/chat/u/0/#chat/home)**.

---

### 🏆 Congratulations!!! You completed the Lab! 🎉

---

### **Join the Community!**

- [Whatsapp Group](https://chat.whatsapp.com/FbVg9NI6Dp4CzfdsYmy0AE)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)
