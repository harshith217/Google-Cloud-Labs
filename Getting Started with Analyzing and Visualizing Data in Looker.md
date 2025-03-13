# 🚀 **Getting Started with Analyzing and Visualizing Data in Looker**  
[![Open Lab](https://img.shields.io/badge/Open-Lab-brown?style=for-the-badge&logo=google-cloud&logoColor=blue)](https://www.cloudskillsboost.google/focuses/25305?parent=catalog) 
---

## ⚠️ **Important Notice**  
This guide is designed to enhance your learning experience during this lab. Please review each step carefully to fully understand the concepts. Ensure you adhere to **Qwiklabs** and **YouTube** policies while following this guide.  

---

## Task 1: Single Value Visualization (Average Elevation)

```
explore: +airports { 
    query: ArcadeCrew_Task1 {
      measures: [average_elevation]
    }
  }
```

- **Explore** → **FAA** → **Airports**
- Select **Average Elevation** under Measures
- Click **Run**
- Customize Visualization:
  - Select **Single Value**
  - Set **Value Format**: `0.00`
  - Modify **Value Color** and **Title**
- Save to **New Dashboard** → **"Airports"**

## Task 2: Bar Chart (Top 5 Facility Types by Elevation)

```
explore: +airports {
    query: ArcadeCrew_Task2 {
      dimensions: [facility_type]
      measures: [average_elevation, count]
  }
}
```

- **Explore** → **FAA** → **Airports**
- Select **Facility Type (Dimension)**, **Average Elevation (Measure)**, **Count (Measure)**
- Set **Row Limit**: `5` → Click **Run**
- Customize Visualization:
  - Select **Bar Chart**
  - Enable **Value Labels**
  - Rename **Axes** and set **Value Format**: `0.00`
- Save to **Existing Dashboard** → **"Airports"**

## Task 3: Line Chart (Flights Cancelled Per Week in 2004)

```
explore: +flights {
    query: ArcadeCrew_Task3 {
      dimensions: [depart_week]
      measures: [cancelled_count]
      filters: [flights.depart_date: "2004"]
  }
}
```

- **Explore** → **FAA** → **Flights**
- Select **Cancelled Count (Measure)**
- Under **Depart Date (Dimension)**:
  - Select **Week**
  - Apply Filter: **Year = 2004**
- Click **Run**
- Customize Visualization:
  - Select **Line Chart**
  - Set **Filled Point Style**
  - Add **Reference Line**
- Save to **New Dashboard** → **"Airports and Flights"**

## Task 4: Line Chart (Flights Scheduled Per Week by Distance Tier in 2003)

```
explore: +flights {
    query: ArcadeCrew_Task4 {
      dimensions: [depart_week, distance_tiered]
      measures: [count]
      filters: [flights.depart_date: "2003"]
  }
}
```

- **Explore** → **FAA** → **Flights**
- Select **Count (Measure)**
- Under **Distance Tiered (Dimension)**:
  - Select **Pivot**
- Under **Depart Date (Dimension)**:
  - Select **Week**
  - Apply Filter: **Year = 2003**
- Click **Run**
- Customize Visualization:
  - Select **Stacked Line Chart**
  - Enable **Overlay Series Positioning**
- Save to **Existing Dashboard** → **"Airports and Flights"**
  
---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

---

## 🤝 **Join the Arcade Crew Community!**  

- **WhatsApp Group:** [Join Here](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  
- **YouTube Channel:** [![Subscribe to Arcade Crew](https://img.shields.io/badge/Youtube-Arcade%20Crew-red?style=for-the-badge&logo=google-cloud&logoColor=white)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)  
