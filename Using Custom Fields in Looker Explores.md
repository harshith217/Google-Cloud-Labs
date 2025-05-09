<h1 align="center">
✨  Using Custom Fields in Looker Explores || GSP983 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/22212?parent=catalog" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are intended <em>solely for educational purposes</em> to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—<em>not</em> to circumvent it.
</blockquote>

---

## ⚙️ <ins>Setting Up Your Lab Environment</ins>

> ✅ **Pro Tip:** *Watch the full video guide to ensure you ace all "Check My Progress" steps!*

---

### 🚀 **Task 1: Create a custom measure**

1.  Toggle on **Development Mode** (find it at the bottom-left corner).
2.  Navigate to **Explore > E-Commerce Training > Order Items**.
3.  Expand the **Inventory Items** section.
4.  Click the **More options (⋮)** icon next to the **Cost** field.
5.  Choose **Aggregate > Average**.
6.  Expand **Custom Fields** to see your newly created measure.
7.  Alternatively, you can create it manually:
  *   In **Custom Fields**, click **+ Add > Custom Measure**.
  *   **Field to measure**: `Inventory Items > Cost`
  *   **Measure type**: `Average`
  *   **Name**: `Average of Cost`
  *   **Format**: `U.S. Dollars`
  *   **Decimals**: `2`
  *   Click **Save**.

---

### 📊 **Task 2: Create a custom grouping**

1.  In the **Custom Fields** section, select your **Average of Cost** measure (the one at the bottom if there are duplicates) to add it to your query.
2.  Add **Product Name** (from Inventory Items) to the query.
3.  Add **Country** (from Users), then click the filter icon:
  *   Set the filter to **is equal to** > **USA**.
4.  Click the **More options (⋮)** icon next to **State** (from Users) and select **Group**.
5.  Configure the **Group By State** settings:
  *   **Group name**: `Pacific Northwest`
  *   Add these values: **Oregon**, **Idaho**, **Washington**.
  *   Ensure **Group remaining values** is checked.
  *   Click **Save**.
6.  Select the newly created **State Groups** field to add it to your view.
7.  Click **Run**.

---

### 🔍 **Task 3: Adding a filter to a custom measure**

1.  In **Custom Fields**, find your **Average of Cost** measure (again, the bottom one if duplicated) and click its **Filter by field** icon.
2.  Set the filter condition to **is greater than** > **200**.
3.  Click **Run**.

---

### 🧮 **Task 4: Using table calculations**

1.  Add **Order Count** (from Order Items) to your query.
2.  Click the **Settings (⚙️)** icon on the **Order Count** column in your results table.
3.  Select **Calculations > % of column**.
4.  Click **Run**.

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
    <em>Last updated: May 2025</em>
  </p>
</div>
