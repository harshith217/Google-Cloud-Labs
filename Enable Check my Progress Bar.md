# Enable Check My Progress Bar (https://youtu.be/JhDmIW77L7I)

## 👉 Tampermonkey Method

🔗 Install the [Tampermonkey Extension from here](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo).

### Script Code
```javascript
// ==UserScript==
// @name         Check My Progress Bar
// @namespace    http://tampermonkey.net/
// @version      1.1
// @description  Automatically show assessment panel and hide leaderboard.
// @author       Gourav Sen
// @match        https://www.cloudskillsboost.google/games/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Helper function to apply styles to an element
    const applyStyle = (selector, styles, elementName) => {
        const element = document.querySelector(selector);
        if (element) {
            Object.assign(element.style, styles);
            console.log(`${elementName} updated with styles: ${JSON.stringify(styles)}`);
        } else {
            console.warn(`${elementName} not found.`);
        }
    };

    // Wait for element and apply styles
    const waitForElement = (selector, callback, timeout = 5000) => {
        const startTime = Date.now();
        const interval = setInterval(() => {
            const element = document.querySelector(selector);
            if (element) {
                clearInterval(interval);
                callback(element);
            } else if (Date.now() - startTime > timeout) {
                clearInterval(interval);
                console.warn(`Timed out waiting for element: ${selector}`);
            }
        }, 100);
    };

    // Notify user
    const showNotification = (message, duration = 3000) => {
        const notification = document.createElement('div');
        notification.textContent = message;
        Object.assign(notification.style, {
            position: 'fixed',
            bottom: '10px',
            right: '10px',
            backgroundColor: '#28a745',
            color: '#fff',
            padding: '10px 15px',
            borderRadius: '8px',
            fontSize: '14px',
            boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
            zIndex: 9999,
        });
        document.body.appendChild(notification);
        setTimeout(() => notification.remove(), duration);
    };

    // Process elements
    waitForElement('.lab-assessment__tab.js-open-lab-assessment-panel', (el) => {
        el.style.display = 'block';
        console.log('Assessment Tab is now visible.');
    });
    waitForElement('ql-leaderboard-container', (el) => {
        el.style.display = 'none';
        console.log('Leaderboard is now hidden.');
    });
    waitForElement('.lab-assessment__panel.js-lab-assessment-panel', (el) => {
        el.style.display = 'block';
        console.log('Assessment Panel is now visible.');
    });

    // Notify user when script is executed
    showNotification('Script executed successfully!');
})();
```
---

## 👉 Bookmark Method

```javascript
javascript:(function(){'use strict';const applyStyle=(s,styles,name)=>{const e=document.querySelector(s);if(e){Object.assign(e.style,styles);console.log(`${name} updated with styles: ${JSON.stringify(styles)}`);}else console.warn(`${name} not found.`);};const waitForElement=(s,cb,timeout=5000)=>{const start=Date.now();const interval=setInterval(()=>{const el=document.querySelector(s);if(el){clearInterval(interval);cb(el);}else if(Date.now()-start>timeout){clearInterval(interval);console.warn(`Timed out waiting for element: ${s}`);}},100);};const showNotification=(msg,duration=3000)=>{const n=document.createElement('div');n.textContent=msg;Object.assign(n.style,{position:'fixed',bottom:'10px',right:'10px',backgroundColor:'#28a745',color:'#fff',padding:'10px 15px',borderRadius:'8px',fontSize:'14px',boxShadow:'0 4px 6px rgba(0,0,0,0.1)',zIndex:9999});document.body.appendChild(n);setTimeout(()=>n.remove(),duration);};waitForElement('.lab-assessment__tab.js-open-lab-assessment-panel',(el)=>{el.style.display='block';console.log('Assessment Tab is now visible.');});waitForElement('ql-leaderboard-container',(el)=>{el.style.display='none';console.log('Leaderboard is now hidden.');});waitForElement('.lab-assessment__panel.js-lab-assessment-panel',(el)=>{el.style.display='block';console.log('Assessment Panel is now visible.');});showNotification('Script executed successfully!');})();
```

---

## ⚠️ Note:
- These scripts are intended for **personal use** to improve the usability of the Google Cloud Skills Boost platform.
- Ensure you follow the video tutorial for complete steps to use either method.

---

### 🤝 Join the Community!

- [Whatsapp](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)

---