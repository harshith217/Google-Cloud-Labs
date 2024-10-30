
# **Prepare Data for Looker Dashboards and Reports: Challenge Lab**
### 📖 LAB: [GSP346](https://www.cloudskillsboost.google/focuses/18116?parent=catalog)

--- 

Watch the full video walkthrough for this lab:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://www.youtube.com/watch?v=wjSrI-UHmM8)

---
## ⚠️ **Important Note:**
This guide is provided to support your educational journey in this lab. Please open and review each step of the script to gain full understanding. Be sure to follow the terms of Qwiklabs and YouTube’s guidelines as you proceed.

---

### **Task 1: Create Looks**

---

#### **Look #1: Most Heliports by State**

1. In the **Looker Navigation Menu**, click **Explore**.
2. Under **FAA**, click **Airports**.
3. Under **Airports > Dimensions**, click **City**.
4. Under **Airports > Dimensions**, click **State**.
5. Under **Airports > Measures**, click **Count**.
6. Under **Airports > Dimensions**, click the **Filter** button next to **Facility Type**.
7. In the **Filter Window**, set the **filter** to **`HELIPORT`**.
8. On the **Data Tab**, change **Row Limit** to **`YOUR LIMIT`**.
9. Click **Run**.
10. Click on **Airports Count** to sort the values in **descending order**.
11. Click the arrow next to **Visualization** to expand the window.
12. Change **Visualization Type** to **Table**.
13. Click **Run**.
14. Click on the **Settings Gear** icon next to **Run** and select **Save > As a Look**.
15. Title the Look with **`YOUR LOOK NAME`**.
16. Click **Save**.

---

#### **Look #2: Facility Type Breakdown**

1. In the **Looker Navigation Menu**, click **Explore**.
2. Under **FAA**, click **Airports**.
3. Under **Airports > Dimensions**, click **State**.
4. Under **Airports > Measures**, click **Count**.
5. Under **Airports > Dimensions**, click the **Pivot** button next to **Facility Type**.
6. On the **Data Tab**, change **Row Limit** to **`YOUR LIMIT`**.
7. Sort the values in **descending order** by **Airports Facility Type**.
8. Expand the **Visualization** window.
9. Change **Visualization Type** to **Table**.
10. Click **Run**.
11. Save the Look as described above, and give it a **unique name**.

---

#### **Look #3: Percentage Cancelled**

1. In the **Looker Navigation Menu**, click **Explore**.
2. Under **FAA**, click **Flights**.
3. Under **Aircraft Origin > Dimensions**, click **City**.
4. Under **Aircraft Origin > Dimensions**, click **State**.
5. Under **Flights Details > Measures**, click **Cancelled Count**.
6. Under **Flights > Measures**, click **Count**.
7. Set a **Filter** on **Flights Count**: `Flights Count > 10000`.
8. Click **Run**.
9. Create a **Custom Field** for percentage calculation: 
   ``` 
   ${flights.cancelled_count}/${flights.count}
   ```
10. Name the calculation **Percentage of Flights Cancelled**.
11. Format the result as **Percent (3)**.
12. Sort the data by **Percentage Cancelled**.
13. Hide unnecessary columns (**Flights Count** and **Cancelled Count**).
14. Change the **Visualization Type** to **Table** and run.
15. Save the Look with the title:
   ```
   States and Cities with Highest Percentage of Cancellations: Flights over 10,000
   ```

---

#### **Look #4: Smallest Average Distance**

1. In the **Looker Navigation Menu**, click **Explore**.
2. Under **FAA**, click **Flights**.
3. Under **Flights > Dimensions**, click **Origin and Destination**.
4. Create a **Custom Measure** for **Average Distance**.
5. Name the Custom Measure **Average Distance (Miles)**.
6. Apply a filter: **Average Distance (Miles) > 0**.
7. Sort the data in **Ascending Order** by **Average Distance**.
8. Adjust the **Row Limit** and change the **Visualization Type** to **Table**.
9. Click **Run** and save the Look with a unique name.

---

### **Task 2: Merge Results**

1. Explore **Flights** under **FAA**.
2. Select **City**, **State**, and **Code** under **Aircraft Origin > Dimensions**.
3. Set the **Row Limit** to `10` and click **Run**.
4. In the **Settings** (gear icon), select **Merge Results**.
5. Merge with the **Airports** dataset and select the appropriate fields (City, State, Code).
6. Set filters on **Control Tower (Yes/No)**, **Is Major (Yes/No)**, and **Joint Use (Yes/No)**.
7. Click **Run** and save the merged results as a **Bar Chart** visualization.
8. Save the query to a dashboard titled:
   ```
   Busiest, Major Joint-Use Airports with Control Towers
   ```

---

### **Task 3: Save Looks to a Dashboard**

1. Navigate to **Folders** and open **My Folder**.
2. Add all previously created Looks to your **Dashboard**.
3. Save the updated dashboard.

---

### 🏆 Congratulations!!! You completed the Lab! 🎉

---

### 🤝 Join the Community!

- [Whatsapp Group](https://chat.whatsapp.com/FbVg9NI6Dp4CzfdsYmy0AE)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---
