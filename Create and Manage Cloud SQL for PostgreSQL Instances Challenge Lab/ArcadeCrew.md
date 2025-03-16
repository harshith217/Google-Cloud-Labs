# 🚀 **Create and Manage Cloud SQL for PostgreSQL Instances: Challenge Lab || GSP355**  
[![Open Lab](https://img.shields.io/badge/Open-Lab-brown?style=for-the-badge&logo=google-cloud&logoColor=blue)](https://www.cloudskillsboost.google/focuses/23465?parent=catalog) 
---

## ⚠️ **Important Notice**  
This guide is designed to enhance your learning experience during this lab. Please review each step carefully to fully understand the concepts. Ensure you adhere to **Qwiklabs** and **YouTube** policies while following this guide.  

---

## 🧪 Lab Environment Setup

### Step 1: Enable Required APIs

Before we begin, enable these Google Cloud APIs:

<details>
<summary><b>📌 Click to view required APIs</b></summary>

1. Navigate to API Library in your GCP Console
2. Search for and enable:
   * [Database Migration API](https://console.cloud.google.com/marketplace/product/google/datamigration.googleapis.com)
   * [Service Networking API](https://console.cloud.google.com/marketplace/product/google/servicenetworking.googleapis.com)

</details>

### Step 2: Configure PostgreSQL VM

Connect to your `postgresql-vm` instance via SSH and run the following commands:

<details>
<summary><b>📌 Install required extensions</b></summary>

```bash
sudo apt install postgresql-13-pglogical
```

</details>

<details>
<summary><b>📌 Configure PostgreSQL for migration</b></summary>

```bash
# Download and apply configuration files
sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/pg_hba_append.conf ."
sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/postgresql_append.conf ."
sudo su - postgres -c "cat pg_hba_append.conf >> /etc/postgresql/13/main/pg_hba.conf"
sudo su - postgres -c "cat postgresql_append.conf >> /etc/postgresql/13/main/postgresql.conf"

# Restart PostgreSQL service
sudo systemctl restart postgresql@13-main
```

</details>

## 🔧 Database Configuration Tasks

### Step 3: Configure Database for Migration

<details>
<summary><b>📌 Set up database privileges</b></summary>

```bash
# Switch to postgres user
sudo su - postgres
```
```
# Enter PostgreSQL console
psql
```

PostgreSQL commands:

```
-- Connect to postgres database and enable extensions
\c postgres;
```
```
CREATE EXTENSION pglogical;
```
```
-- Connect to orders database and enable extensions
\c orders;
```
```
CREATE EXTENSION pglogical;
```

</details>

### Open below websites:

- **[Online word replacer](https://codebeautify.org/word-replacer)**

- **[Online Notepad](https://www.rapidtables.com/tools/notepad.html)**

<details>
<summary><b>📌 Grant required permissions</b></summary>

```sql
-- Create migration admin user and configure permissions
CREATE USER migration_admin PASSWORD 'DMS_1s_cool!';
ALTER DATABASE orders OWNER TO migration_admin;
ALTER ROLE migration_admin WITH REPLICATION;


\c orders;


-- Add primary key to inventory items table
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'inventory_items' AND column_name = 'id';
ALTER TABLE inventory_items ADD PRIMARY KEY (id);


-- Grant pglogical schema permissions
GRANT USAGE ON SCHEMA pglogical TO migration_admin;
GRANT ALL ON SCHEMA pglogical TO migration_admin;
GRANT SELECT ON pglogical.tables TO migration_admin;
GRANT SELECT ON pglogical.depend TO migration_admin;
GRANT SELECT ON pglogical.local_node TO migration_admin;
GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
GRANT SELECT ON pglogical.node TO migration_admin;
GRANT SELECT ON pglogical.node_interface TO migration_admin;
GRANT SELECT ON pglogical.queue TO migration_admin;
GRANT SELECT ON pglogical.replication_set TO migration_admin;
GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
GRANT SELECT ON pglogical.sequence_state TO migration_admin;
GRANT SELECT ON pglogical.subscription TO migration_admin;

-- Grant public schema permissions
GRANT USAGE ON SCHEMA public TO migration_admin;
GRANT ALL ON SCHEMA public TO migration_admin;

-- Grant table-specific permissions
GRANT SELECT ON public.distribution_centers TO migration_admin;
GRANT SELECT ON public.inventory_items TO migration_admin;
GRANT SELECT ON public.order_items TO migration_admin;
GRANT SELECT ON public.products TO migration_admin;
GRANT SELECT ON public.users TO migration_admin;

-- Update table ownerships
ALTER TABLE public.distribution_centers OWNER TO migration_admin;
ALTER TABLE public.inventory_items OWNER TO migration_admin;
ALTER TABLE public.order_items OWNER TO migration_admin;
ALTER TABLE public.products OWNER TO migration_admin;
ALTER TABLE public.users OWNER TO migration_admin;

-- Switch to postgres database and set up permissions there as well
\c postgres;

-- Configure pglogical permissions in postgres database
GRANT USAGE ON SCHEMA pglogical TO migration_admin;
GRANT ALL ON SCHEMA pglogical TO migration_admin;
GRANT SELECT ON pglogical.tables TO migration_admin;
GRANT SELECT ON pglogical.depend TO migration_admin;
GRANT SELECT ON pglogical.local_node TO migration_admin;
GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
GRANT SELECT ON pglogical.node TO migration_admin;
GRANT SELECT ON pglogical.node_interface TO migration_admin;
GRANT SELECT ON pglogical.queue TO migration_admin;
GRANT SELECT ON pglogical.replication_set TO migration_admin;
GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
GRANT SELECT ON pglogical.sequence_state TO migration_admin;
GRANT SELECT ON pglogical.subscription TO migration_admin;
```

</details>

## 🔐 IAM Authentication Configuration

### Step 4: Implement Cloud SQL for PostgreSQL IAM Authentication

<details>
<summary><b>📌 Configure IAM Authentication</b></summary>

When prompted for a password, enter:
```
supersecret!
```

Connect to the orders database:
```sql
\c orders
```
* When prompted for a password, enter:
```
supersecret!
```

Grant privileges to the specified user (replace placeholders with values from lab instructions):
```sql
GRANT ALL PRIVILEGES ON TABLE [TABLE_NAME] TO "[USER_NAME]";
\q
```

</details>

## 🔄 Point-in-Time Recovery

### Step 5: Configure and Test Point-in-Time Recovery

<details>
<summary><b>📌 Create a recovery point</b></summary>

```bash
# Record the current time
date --rfc-3339=seconds
```

* ⚠️ **Important:** Copy and save this timestamp for later use in recovery

When prompted for a password, enter:
```
supersecret!
```
```
-- Connect to orders database (password: supersecret!)
\c orders
```
```
-- Insert test data to verify recovery later
INSERT INTO distribution_centers VALUES(-80.1918, 25.7617, 'Miami FL', 11);
\q
```

</details>

<details>
<summary><b>📌 Perform point-in-time recovery</b></summary>

```bash
# Login to gcloud
gcloud auth login --quiet

# View project permissions
gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID

# Set your instance ID (replace with the actual instance ID)
export INSTANCE_ID=your_instance_id

# Clone the instance to a specific point in time
gcloud sql instances clone $INSTANCE_ID postgres-orders-pitr --point-in-time 'YOUR_SAVED_TIMESTAMP'
```

</details>
---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

---

## 🤝 **Join the Arcade Crew Community!**  

- **WhatsApp Group:** [Join Here](https://chat.whatsapp.com/KkNEauOhBQXHdVcmqIlv9F)  
- **YouTube Channel:** [![Subscribe to Arcade Crew](https://img.shields.io/badge/Youtube-Arcade%20Crew-red?style=for-the-badge&logo=google-cloud&logoColor=white)](https://www.youtube.com/@Arcade61432?sub_confirmation=1)  
