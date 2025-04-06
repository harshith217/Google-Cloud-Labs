<div align="center" style="background-color: #f0f8ff; padding: 20px; border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.1);">

  <h1 style="color: #2c3e50; font-family: 'Arial', sans-serif; font-size: 2.5em; margin-bottom: 10px; text-shadow: 1px 1px 2px rgba(0,0,0,0.1);">
    ✨ Deploy Go Apps on Google Cloud Serverless Platforms || GSP702 ✨
  </h1>

  <a href="https://www.cloudskillsboost.google/focuses/10532?parent=catalog" target="_blank" rel="noopener noreferrer" style="text-decoration: none;">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge" style="height: 35px; border-radius: 5px; transition: transform 0.2s ease-in-out;" onmouseover="this.style.transform='scale(1.05)'" onmouseout="this.style.transform='scale(1)'">
  </a>

</div>

---

<div style="background-color: #fff3cd; border: 1px solid #ffeeba; border-left: 5px solid #ffc107; padding: 20px; margin: 25px 0; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.05);">
  <h2 style="color: #856404; font-family: 'Georgia', serif; margin-top: 0; display: flex; align-items: center;">
    <span style="font-size: 1.5em; margin-right: 10px;">⚠️</span> Disclaimer
  </h2>
  <blockquote style="margin: 0 0 0 20px; padding: 10px; border-left: 3px solid #ffda6a; background-color: #fff9e4; border-radius: 4px;">
    <p style="margin: 0; line-height: 1.6; color: #555;">
      <strong style="color: #664d03;">Educational Purpose Only:</strong> This script and guide are intended <em style="color: #755d0c;">solely for educational purposes</em> to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.
    </p>
    <p style="margin: 10px 0 0; line-height: 1.6; color: #555;">
      <strong style="color: #664d03;">Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—<em style="color: #755d0c;">not</em> to circumvent it.
    </p>
  </blockquote>
</div>

---

<div style="background-color: #e9f5ff; border: 1px solid #b8dfff; border-left: 5px solid #007bff; padding: 20px; margin: 25px 0; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.05);">
  <h2 style="color: #0056b3; font-family: 'Verdana', sans-serif; margin-top: 0; display: flex; align-items: center;">
    <span style="font-size: 1.5em; margin-right: 10px;">⚙️</span> Lab Environment Setup
  </h2>
  <div style="background-color: #ffffff; border: 1px solid #d1d5da; padding: 15px; margin: 10px 0; border-radius: 6px; box-shadow: inset 0 1px 3px rgba(0,0,0,0.05);">
    <p style="margin: 0 0 10px 0; font-weight: bold; color: #333; display: flex; align-items: center;">
      <span style="font-size: 1.2em; margin-right: 8px;">☁️</span> Run in Cloud Shell:
    </p>
    <pre style="background-color: #f6f8fa; padding: 15px; border-radius: 5px; overflow-x: auto; border: 1px solid #eaecef;"><code style="font-family: 'Courier New', Courier, monospace; color: #24292e;">curl -LO https://github.com/gouravsen770/Arcade-Crew/raw/main/GSP702/arcadecrew.sh
sudo chmod +x arcadecrew.sh
./arcadecrew.sh</code></pre>
  </div>
</div>

---

<div align="center" style="background: linear-gradient(135deg, #e0f7fa 0%, #b2ebf2 100%); padding: 25px; margin: 25px 0; border-radius: 15px; border: 1px solid #80deea; box-shadow: 0 4px 15px rgba(0, 188, 212, 0.2);">
  <h2 style="color: #00796b; font-family: 'Tahoma', sans-serif; font-size: 2em; margin-top: 0; margin-bottom: 15px;">
    🎉 <strong>Congratulations! Lab Completed Successfully!</strong> 🏆
  </h2>
  
  <h3 style="color: #004d40; font-family: 'Verdana', sans-serif; margin-bottom: 20px; font-weight: normal; display: flex; align-items: center; justify-content: center;">
     <span style="font-size: 1.5em; margin-right: 10px;">📱</span> Join the Arcade Crew Community
  </h3>
  
  <div style="display: flex; justify-content: center; align-items: center; gap: 15px; flex-wrap: wrap;">
    <a href="https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F" target="_blank" rel="noopener noreferrer" style="text-decoration: none;">
      <img src="https://img.shields.io/badge/Join_WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="Join WhatsApp" style="height: 30px; border-radius: 5px; transition: transform 0.2s ease-in-out;" onmouseover="this.style.transform='translateY(-2px)'" onmouseout="this.style.transform='translateY(0)'">
    </a>
    <a href="https://www.youtube.com/@Arcade61432?sub_confirmation=1" target="_blank" rel="noopener noreferrer" style="text-decoration: none;">
      <img src="https://img.shields.io/badge/Subscribe-Arcade%20Crew-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel" style="height: 30px; border-radius: 5px; transition: transform 0.2s ease-in-out;" onmouseover="this.style.transform='translateY(-2px)'" onmouseout="this.style.transform='translateY(0)'">
    </a>
    <a href="https://www.linkedin.com/in/gourav61432/" target="_blank" rel="noopener noreferrer" style="text-decoration: none;">
      <img src="https://img.shields.io/badge/LINKEDIN-Gourav%20Sen-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn" style="height: 30px; border-radius: 5px; transition: transform 0.2s ease-in-out;" onmouseover="this.style.transform='translateY(-2px)'" onmouseout="this.style.transform='translateY(0)'">
    </a>
  </div>
</div>

---

<div align="center" style="margin-top: 30px; padding: 15px; border-top: 1px solid #e1e4e8;">
  <p style="font-size: 12px; color: #586069; font-family: 'Arial', sans-serif; line-height: 1.5;">
    <em>This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.</em>
  </p>
  <p style="font-size: 11px; color: #6a737d; font-family: 'Arial', sans-serif;">
    <em>Last updated: March 2025</em>
  </p>
</div>