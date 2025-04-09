# ✨ ETL Processing on Google Cloud Using Dataflow and BigQuery (Python) || GSP290 ✨
<div align="center">
<a href="https://www.cloudskillsboost.google/focuses/3460?parent=catalog" target="_blank" rel="noopener noreferrer" style="text-decoration: none;">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab" style="height: 35px; border-radius: 5px;">
  </a>
</div>

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are intended *solely for educational purposes* to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—*not* to circumvent it.

---

## ⚙️ Lab Environment Setup

<div style="padding: 15px; margin: 10px 0;">
<p><strong>☁️ Run in Cloud Shell:</strong></p>

```bash
curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/ETL%20Processing%20on%20Google%20Cloud%20Using%20Dataflow%20and%20BigQuery%20Python/arcadecrew.sh
sudo chmod +x arcadecrew.sh
./arcadecrew.sh
```
* **After Pasting watch the video, to get full score.**
```
pip install apache-beam[gcp]==2.59.0

cd dataflow/

python dataflow_python_examples/data_ingestion.py \
  --project=$PROJECT \
  --region=$REGION \
  --runner=DataflowRunner \
  --machine_type=e2-standard-2 \
  --staging_location=gs://$PROJECT/test \
  --temp_location=gs://$PROJECT/test \
  --input=gs://$PROJECT/data_files/head_usa_names.csv \
  --save_main_session

python dataflow_python_examples/data_transformation.py \
  --project=$PROJECT \
  --region=$REGION \
  --runner=DataflowRunner \
  --machine_type=e2-standard-2 \
  --staging_location=gs://$PROJECT/test \
  --temp_location=gs://$PROJECT/test \
  --input=gs://$PROJECT/data_files/head_usa_names.csv \
  --save_main_session

sed -i "s/values = \[x.decode('utf8') for x in csv_row\]/values = \[x for x in csv_row\]/" ./dataflow_python_examples/data_enrichment.py

python dataflow_python_examples/data_enrichment.py \
  --project=$PROJECT \
  --region=$REGION \
  --runner=DataflowRunner \
  --machine_type=e2-standard-2 \
  --staging_location=gs://$PROJECT/test \
  --temp_location=gs://$PROJECT/test \
  --input=gs://$PROJECT/data_files/head_usa_names.csv \
  --save_main_session

# Note: worker_disk_type path looks potentially problematic, often it's just 'pd-ssd' or 'pd-standard'
# If the below fails, try removing the full path from worker_disk_type
python dataflow_python_examples/data_lake_to_mart.py \
  --worker_disk_type="compute.googleapis.com/projects/$PROJECT/zones/$REGION-a/diskTypes/pd-ssd" \ # Adjusted path, assuming zone 'a' exists - might still need tweaking
  --max_num_workers=4 \
  --project=$PROJECT \
  --runner=DataflowRunner \
  --machine_type=e2-standard-2 \
  --staging_location=gs://$PROJECT/test \
  --temp_location=gs://$PROJECT/test \
  --save_main_session \
  --region=$REGION
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
    <em>Last updated: April 2025</em>
  </p>
</div>
