# ✨ Creating a Gmail Add-on || GSP249

[![Lab Link](https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://www.cloudskillsboost.google/focuses/4049?parent=catalog)

---

## ⚠️ Disclaimer

<div style="padding: 15px; margin-bottom: 20px;">
<p><strong>Educational Purpose Only:</strong> This script and guide are intended solely for educational purposes to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.</p>

<p><strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—not to circumvent it.</p>
</div>

---

## ⚙️ Lab Environment Setup

<div style="padding: 15px; margin: 10px 0;">

* Code.gs
```bash
/**
 * Copyright Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Returns the array of cards that should be rendered for the current
 * e-mail thread. The name of this function is specified in the
 * manifest 'onTriggerFunction' field, indicating that this function
 * runs every time the add-on is started.
 *
 * @param {Object} e The data provided by the Gmail UI.
 * @return {Card[]}
 */
function buildAddOn(e) {
  // Activate temporary Gmail add-on scopes.
  var accessToken = e.messageMetadata.accessToken;
  GmailApp.setCurrentMessageAccessToken(accessToken);

  var messageId = e.messageMetadata.messageId;
  var message = GmailApp.getMessageById(messageId);

  // Get user and thread labels as arrays to enable quick sorting and indexing.
  var threadLabels = message.getThread().getLabels();
  var labels = getLabelArray(GmailApp.getUserLabels());
  var labelsInUse = getLabelArray(threadLabels);

  // Create a section for that contains all user Labels.
  var section = CardService.newCardSection()
    .setHeader("<font color=\"#1257e0\"><b>Available User Labels</b></font>");

  // Create a checkbox group for user labels that are added to prior section.
  var checkboxGroup = CardService.newSelectionInput()
    .setType(CardService.SelectionInputType.CHECK_BOX)
    .setFieldName('labels')
    .setOnChangeAction(CardService.newAction().setFunctionName('toggleLabel'));

  // Add checkbox with name and selected value for each User Label.
  for(var i = 0; i < labels.length; i++) {
    checkboxGroup.addItem(labels[i], labels[i], labelsInUse.indexOf(labels[i])!= -1);
  }

  // Add the checkbox group to the section.
  section.addWidget(checkboxGroup);

  // Build the main card after adding the section.
  var card = CardService.newCardBuilder()
    .setHeader(CardService.newCardHeader()
    .setTitle('Quick Label')
    .setImageUrl('https://www.gstatic.com/images/icons/material/system/1x/label_googblue_48dp.png'))
    .addSection(section)
    .build();

  return [card];
}

/**
 * Updates the labels on the current thread based on
 * user selections. Runs via the OnChangeAction for
 * each CHECK_BOX created.
 *
 * @param {Object} e The data provided by the Gmail UI.
*/
function toggleLabel(e){
  var selected = e.formInputs.labels;

  // Activate temporary Gmail add-on scopes.
  var accessToken = e.messageMetadata.accessToken;
  GmailApp.setCurrentMessageAccessToken(accessToken);

  var messageId = e.messageMetadata.messageId;
  var message = GmailApp.getMessageById(messageId);
  var thread = message.getThread();

  if (selected != null){
    var labels = GmailApp.getUserLabels();
    for (var i = 0; i < labels.length; i++) {
        var label = labels[i];
        if (selected.indexOf(label.getName()) !== -1) {
            thread.addLabel(label);
        } else {
            thread.removeLabel(label);
        }
    }
}
  else {
    var labels = GmailApp.getUserLabels();
    for (var i = 0; i < labels.length; i++) {
        var label = labels[i];
        thread.removeLabel(label);
}
  }
}

/**
 * Converts an GmailLabel object to a array of strings.
 * Used for easy sorting and to determine if a value exists.
 *
 * @param {labelsObjects} A GmailLabel object array.
 * @return {lables[]} An array of labels names as strings.
*/
function getLabelArray(labelsObjects){
  var labels = [];
  for(var i = 0; i < labelsObjects.length; i++) {
    labels[i] = labelsObjects[i].getName();
  }
  labels.sort();
  return labels;
}
```

* appsscript.json
```
{
  "oauthScopes": [
    "https://www.googleapis.com/auth/gmail.addons.execute",
    "https://www.googleapis.com/auth/gmail.addons.current.message.metadata",
    "https://www.googleapis.com/auth/gmail.modify"
  ],
  "gmail": {
    "name": "Gmail Add-on Quickstart - QuickLabels",
    "logoUrl": "https://www.gstatic.com/images/icons/material/system/1x/label_googblue_24dp.png",
    "contextualTriggers": [{
      "unconditional": {
      },
      "onTriggerFunction": "buildAddOn"
    }],
    "openLinkUrlPrefixes": [
      "https://mail.google.com/"
    ],
    "primaryColor": "#4285F4",
    "secondaryColor": "#4285F4"
  }
}
```
</div>

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
    <em>Last updated: March 2025</em>
  </p>
</div>
