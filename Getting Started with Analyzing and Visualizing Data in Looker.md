# 🚀 **Getting Started with Analyzing and Visualizing Data in Looker**  
[![Open Lab](https://img.shields.io/badge/Open-Lab-brown?style=for-the-badge&logo=google-cloud&logoColor=blue)](https://www.cloudskillsboost.google/focuses/25305?parent=catalog) 
---

## ⚠️ **Important Notice**  
This guide is designed to enhance your learning experience during this lab. Please review each step carefully to fully understand the concepts. Ensure you adhere to **Qwiklabs** and **YouTube** policies while following this guide.  

---

### TASK 1:
```
explore: +airports { 
    query: ArcadeCrew_Task1 {
      measures: [average_elevation]
    }
  }
```


### TASK 2:
```
explore: +airports {
    query: ArcadeCrew_Task2 {
      dimensions: [facility_type]
      measures: [average_elevation, count]
  }
}
```



### TASK 3:
```
explore: +flights {
    query: ArcadeCrew_Task3 {
      dimensions: [depart_week]
      measures: [cancelled_count]
      filters: [flights.depart_date: "2004"]
  }
}
```


### TASK 4:
```
explore: +flights {
    query: ArcadeCrew_Task4 {
      dimensions: [depart_week, distance_tiered]
      measures: [count]
      filters: [flights.depart_date: "2003"]
  }
}
```
  
---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

---

## 🤝 **Join the Arcade Crew Community!**  

- **WhatsApp Group:** [Join Here](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  
- **YouTube Channel:** [![Subscribe to Arcade Crew](https://img.shields.io/badge/Youtube-Arcade%20Crew-red?style=for-the-badge&logo=google-cloud&logoColor=white)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)  
