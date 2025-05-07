<h1 align="center">
✨  Looker Functions and Operators || GSP857 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/17873?parent=catalog" target="_blank" rel="noopener noreferrer">
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

## 🛠️ Looker Configuration Steps

> ✅ **NOTE:** *Watch Full Video to get Full Scores on Check My Progress.*

---

### 🎯 Task 1: Pivot dimensions

> 👇 Copy the following code and paste it into the **`faa` model** in Looker.

```lookml
# Place in `faa` model
explore: +flights {
  query: start_from_here{
      dimensions: [depart_week, distance_tiered]
      measures: [count]
      filters: [flights.depart_date: "2003"]
    }
  }
```
> 💡 **Important:** After pasting the code, carefully follow the subsequent steps for Task 1 to ensure correct implementation.

* **Title the Look**
```
Flight Count by Departure Week and Distance Tier
```

---

### 🎯 Task 2: Reorder columns and remove fields

> 👇 Copy the following code and paste it into the **`faa` model** in Looker.

```lookml
# Place in `faa` model
explore: +flights {
  query: start_from_here{
      dimensions: [aircraft_origin.state]
      measures: [percent_cancelled]
      filters: [flights.depart_date: "2000"]
    }
  }
```
> 💡 **Important:** After pasting the code, carefully follow the subsequent steps for Task 2 to ensure correct implementation.

* **Title the Look**
```
Percent of Flights Cancelled by State in 2000
```

---

### 🎯 Task 3: Use table calculations to calculate simple percentages

> 👇 Copy the following code and paste it into the **`faa` model** in Looker.

```lookml
# Place in `faa` model
explore: +flights {
    query: start_from_here{
      dimensions: [aircraft_origin.state]
      measures: [cancelled_count, count]
      filters: [flights.depart_date: "2004"]
    }
}
```
> 💡 **Important:** After pasting the code, carefully follow the subsequent steps for Task 3 to ensure correct implementation.

* In the **Expression field**, add the following Table Calculation:
```
${flights.cancelled_count}/${flights.count}
```

* **Title the Look**
```
Percent of Flights Cancelled by Aircraft Origin 2004
```

---

### 🎯 Task 4: Use table calculations to calculate percentages of a total

> 👇 Copy the following code and paste it into the **`faa` model** in Looker.

```lookml
# Place in `faa` model
explore: +flights {
    query: start_from_here{
      dimensions: [carriers.name]
      measures: [total_distance]
    }
}
```
> 💡 **Important:** After pasting the code, carefully follow the subsequent steps for Task 4 to ensure correct implementation.

* Add the following in **Expression field**:
```
${flights.total_distance}/${flights.total_distance:total}
```

* **Title the Look:**
```
Percent of Total Distance Flown by Carrier
```

---

### 🎯 Task 5: Use functions in table calculations

> 👇 Copy the following code and paste it into the **`faa` model** in Looker.

```lookml
# Place in `faa` model
explore: +flights {
    query:start_from_here {
      dimensions: [depart_year, distance_tiered]
      measures: [count]
      filters: [flights.depart_date: "after 2000/01/01"]
    }
}
```
> 💡 **Important:** After pasting the code, carefully follow the subsequent steps for Task 5 to ensure correct implementation.

* Add the following **Table Calculation**, making use of the `pivot_offset` function:
```
(${flights.count}-pivot_offset(${flights.count}, -1))/pivot_offset(${flights.count}, -1)
```

* Title the Look:
```
YoY Percent Change in Flights flown by Distance, 2000-Present
```

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
