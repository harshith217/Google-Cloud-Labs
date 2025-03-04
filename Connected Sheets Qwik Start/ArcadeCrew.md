# 🌐 **Connected Sheets: Qwik Start || GSP870**  
[![Open Lab](https://img.shields.io/badge/Open-Lab-orange?style=flat)](https://www.cloudskillsboost.google/focuses/18109?parent=catalog)  

---

## ⚠️ **Important Notice**  
This guide is designed to enhance your learning experience during this lab. Please review each step carefully to fully understand the concepts. Ensure you adhere to **Qwiklabs** and **YouTube** policies while following this guide.  

---

## 👉 **Task 1: Open Google Sheets in Incognito Mode**  
1. Open a new incognito window in your browser.  
2. Navigate to [Google Sheets](https://docs.google.com/spreadsheets/).  

---

## 👉 **Task 2: Connect to a BigQuery Dataset**  
1. In Google Sheets, go to **`Data`** > **`Data Connectors`** > **`Connect to BigQuery`**.  
2. Select **`YOUR PROJECT ID`** > **`Public datasets`** > **`chicago_taxi_trips`** > **`taxi_trips`**.  
3. Click **Connect**.  

---

## 👉 **Task 3: Use Formulas in Google Sheets**  

### Step 1: Count Unique Companies  
1. Select **`Function`** > **`COUNTUNIQUE`**.  
2. In **row 1, column A**, enter the following formula:  
   ```plaintext
   =COUNTUNIQUE(taxi_trips!company)
   ```  
3. Click **Apply**.  

### Step 2: Count Tips Greater Than 0  
1. In **row 1, column D**, enter the following formula:  
   ```plaintext
   =COUNTIF(taxi_trips!tips,">0")
   ```  
2. Click **Apply**.  

### Step 3: Count Fares Greater Than 0  
1. In **row 1, column E**, enter the following formula:  
   ```plaintext
   =COUNTIF(taxi_trips!fare,">0")
   ```  
2. Click **Apply**.  

### Step 4: Calculate Tip-to-Fare Ratio  
1. In **row 1, column F**, enter the following formula:  
   ```plaintext
   =D1/E1
   ```  
2. Click **Apply**.  

---

## 👉 **Task 4: Create Charts**  

### Step 1: Create a Pie Chart  
1. Go to the **`taxi_trips`** tab and click the **`Chart`** button.  
2. Ensure **`New Sheet`** is selected, then click **`Create`**.  
3. Under **`Chart Type`**, select **`Pie Chart`**.  
4. Set **`Label Field`** to **`payment_type`** and **`Value Field`** to **`fare`**.  
5. Change **`Sum`** to **`Count`** under **`Value`** > **`Fare`**.  
6. Click **Apply**.  

### Step 2: Create a Line Chart  
1. Return to the **`taxi_trips`** tab and click the **`Chart`** button.  
2. Ensure **`New Sheet`** is selected, then click **`Create`**.  
3. Under **`Chart Type`**, select **`Line Chart`**.  
4. Set **`X-axis Field`** to **`trip_start_timestamp`** and **`Group`** to **`Year-Month`**.  
5. Set **`Series Field`** to **`fare`**.  
6. Under **`Filter`**, click **`Add`** > **`payment_type`** and select **`Showing all items`**.  
7. Set **`Filter by Condition`** to **`Text contains`** and type **`mobile`** in the value field.  
8. Click **OK**, then **Apply**.  

---

## 👉 **Task 5: Create Pivot Tables**  

### Step 1: Build a Pivot Table  
1. Go to the **`taxi_trips`** tab and click the **`Pivot Table`** button.  
2. Ensure **`New Sheet`** is selected, then click **Create**.  
3. Set **`Rows Field`** to **`trip_start_timestamp`** and **`Group By`** to **`Hour`**.  
4. Set **`Values Field`** to **`fare`** and **`Summarize By`** to **`COUNTA`**.  
5. Set **`Columns Field`** to **`trip_start_timestamp`** and **`Group By`** to **`Day of the Week`**.  
6. Click **Apply**.  

### Step 2: Format the Pivot Table  
1. Select **`Format`** > **`Number`** > **`Number`**.  
2. Apply formatting to all values (from Sunday to Saturday).  
3. Click **`Format`** > **`Conditional Formatting`**.  
4. Select **`Color Scale`** and choose **`White to Green`**.  
5. Click **Done**.  

---

## 👉 **Task 6: Extract Data**  
1. Go to the **`taxi_trips`** tab and click the **`Extract`** button.  
2. Ensure **`New Sheet`** is selected, then click **`Create`**.  
3. In the **`Extract Editor`**, click **`Edit`** under **`Columns`** and select:  
   - **`trip_start_timestamp`**  
   - **`fare`**  
   - **`tips`**  
   - **`tolls`**  
4. Under **`Sort`**, click **`Add`** and select **`trip_start_timestamp`** in **Descending** order.  
5. Leave the **Row Limit** as **`25000`** and click **Apply**.  

---

## 👉 **Task 7: Add Calculated Columns**  
1. Go to the **`taxi_trips`** tab and click the **`Calculated Columns`** button.  
2. Name the column **`tip_percentage`**.  
3. Enter the following formula:  
   ```plaintext
   =IF(fare>0,tips/fare*100,0)
   ```  
4. Click **Add**, then **Apply**.  

---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

---

## 🤝 **Join the Arcade Crew Community!**  
- **WhatsApp Group:** [Join Here](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  
- **YouTube Channel:** [![Subscribe to Arcade Crew](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)  

---
