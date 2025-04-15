import os
import sys
import logging # Added for better feedback

# Import Google Cloud Library modules
from google.cloud import storage, bigquery, vision, translate_v2

# --- Configuration & Initialization ---
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

# Check for credentials
if 'GOOGLE_APPLICATION_CREDENTIALS' in os.environ:
   if not os.path.exists(os.environ['GOOGLE_APPLICATION_CREDENTIALS']):
       logging.error("The GOOGLE_APPLICATION_CREDENTIALS file does not exist.")
       exit()
else:
   logging.error("The GOOGLE_APPLICATION_CREDENTIALS environment variable is not defined.")
   exit()

# Check for command line arguments
if len(sys.argv) < 3:
   print('Usage: python3 analyze-images-v2.py [PROJECT_ID] [BUCKET_NAME]')
   print(' (Often PROJECT_ID and BUCKET_NAME are the same in labs)')
   exit()

project_id = sys.argv[1]
bucket_name = sys.argv[2]
output_bucket_name = bucket_name # Assuming results go to the same bucket

logging.info(f"Project ID: {project_id}")
logging.info(f"Bucket Name: {bucket_name}")

# Initialize Google Cloud clients
try:
    storage_client = storage.Client(project=project_id)
    bq_client = bigquery.Client(project=project_id)
    # Note: language client (nl_client) was in original but not needed for this task.

    # Set up client objects for the vision and translate_v2 API Libraries
    vision_client = vision.ImageAnnotatorClient()
    translate_client = translate_v2.Client()
    logging.info("Google Cloud clients initialized successfully.")
except Exception as e:
    logging.critical(f"Failed to initialize Google Cloud clients: {e}")
    exit()


# Setup the BigQuery dataset and table objects
bq_dataset_id = 'image_classification_dataset'
bq_table_id = 'image_text_detail'
try:
    dataset_ref = bq_client.dataset(bq_dataset_id)
    table_ref = dataset_ref.table(bq_table_id)
    table = bq_client.get_table(table_ref) # Verify table exists
    logging.info(f"Connected to BigQuery table: {project_id}.{bq_dataset_id}.{bq_table_id}")
except Exception as e:
    logging.critical(f"Failed to get BigQuery table '{bq_dataset_id}.{bq_table_id}': {e}")
    logging.critical("Please ensure the dataset and table exist and the service account has permissions.")
    exit()


# Create an array to store results data to be inserted into the BigQuery table
# The BigQuery table expects rows as tuples in the order: (image_uri, text, locale, translated_text)
rows_for_bq = []

# Get a list of the files in the Cloud Storage Bucket
try:
    bucket = storage_client.bucket(bucket_name)
    files = list(bucket.list_blobs()) # Get iterator and convert to list
    logging.info(f"Found {len(files)} files in bucket '{bucket_name}'.")
except Exception as e:
    logging.critical(f"Failed to list files in bucket '{bucket_name}': {e}")
    exit()

print('\nProcessing image files from GCS. This will take a few minutes...')

# --- Main Processing Loop ---
processed_image_count = 0
for blob in files:
   # Basic check for image file extensions
   if blob.name.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp')):
       processed_image_count += 1
       logging.info(f"\nProcessing image [{processed_image_count}]: {blob.name}")
       image_uri = f"gs://{bucket_name}/{blob.name}"

       # Initialize variables for this file
       text_data = ""
       locale = "und" # Default to undetermined
       translated_text = "" # Initialize translated text

       try:
           # Download image content - necessary for the vision.Image(content=...) approach
           file_content = blob.download_as_bytes()

           # 1. Create Vision API image object
           image = vision.Image(content=file_content)

           # 2. Detect text using Vision API
           response = vision_client.text_detection(image=image)

           # --- Extract Text and Locale (More Robustly) ---
           if response.error.message:
               logging.error(f"Vision API error for {blob.name}: {response.error.message}")
           elif response.full_text_annotation:
               text_data = response.full_text_annotation.text # Get the full detected text block
               logging.info(f"  Extracted text snippet: {text_data[:100].replace(os.linesep, ' ')}...")

               # Attempt to get locale from page properties first (more reliable)
               if response.full_text_annotation.pages:
                   page = response.full_text_annotation.pages[0]
                   if page.property and page.property.detected_languages:
                       locale = page.property.detected_languages[0].language_code
                       logging.info(f"  Detected locale (primary): {locale}")
               # Fallback: try locale from the first text annotation if primary not found
               elif response.text_annotations and response.text_annotations[0].locale:
                    locale = response.text_annotations[0].locale
                    logging.warning(f"  Using locale from text_annotations[0]: {locale}")
               else:
                   logging.warning(f"  Could not determine locale for {blob.name}. Using '{locale}'.")
                   locale = 'und' # Explicitly set to 'und' if undetected

           else:
               logging.info(f"  No text found in image {blob.name}.")

           # --- Save Original Text to GCS ---
           # (Optional based on requirements, but good practice)
           output_filename = f"results/{blob.name}.txt" # Store in results/ prefix
           output_blob = bucket.blob(output_filename)
           output_blob.upload_from_string(text_data, content_type='text/plain')
           # logging.info(f"  Saved extracted text to gs://{output_bucket_name}/{output_filename}") # Can uncomment if needed

           # --- Translate Text if Needed (Task 4 Logic) ---
           # If the locale is French ('fr'), save the original text as the translated_text
           if locale == 'fr':
               translated_text = text_data # No translation needed
               logging.info("  Locale is 'fr'. No translation needed.")
           elif text_data: # Only translate if locale is NOT 'fr' AND text exists
               logging.info(f"  Locale is '{locale}'. Translating to 'fr'...")
               # For non FR locales pass the description data to the translation API
               # Set the target_language locale to 'fr'
               try:
                   # Use the client initialized outside the loop
                   # Specify target_language='fr'
                   translation = translate_client.translate(
                       text_data,
                       target_language='fr', # <--- MODIFIED FOR TASK 4
                       source_language=locale if locale != 'und' else None # Help translation if locale is known
                   )
                   translated_text = translation['translatedText']
                   logging.info(f"  Translation successful. Snippet: {translated_text[:100].replace(os.linesep, ' ')}...")
               except Exception as trans_ex:
                   logging.error(f"  Translation API error for {blob.name}: {trans_ex}")
                   translated_text = text_data # Fallback to original text on translation error
           else:
               # No text was extracted, so nothing to translate
               translated_text = ""
               logging.info("  No text extracted, skipping translation.")


           # --- Prepare row for BigQuery ---
           # Ensure the order matches the table schema: (image_uri, text, locale, translated_text)
           # Use text_data (full original text), locale (detected), and translated_text (translated to 'fr' if needed)
           row_tuple = (image_uri, text_data, locale, translated_text)
           rows_for_bq.append(row_tuple)
           logging.debug(f"  Prepared BQ row: {row_tuple}") # Log row data for debugging if needed

       except Exception as e:
           logging.error(f"Error processing file {blob.name}: {e}", exc_info=True)
           # Optionally append a row with error indicators if needed for tracking failures
           # rows_for_bq.append((image_uri, "ERROR_PROCESSING", "err", "ERROR_PROCESSING"))

   else:
       logging.debug(f"Skipping non-image file: {blob.name}")


# --- Load Data into BigQuery ---
if rows_for_bq:
    logging.info(f"\nWriting {len(rows_for_bq)} rows of image data to BigQuery table {project_id}.{bq_dataset_id}.{bq_table_id}...")

    # The table object 'table' was fetched earlier and verified
    # insert_rows expects a list of tuples/lists where order matches table schema.
    # Ensure BQ table columns ARE: image_uri (STRING), text (STRING), locale (STRING), translated_text (STRING)

    # Ensure this line IS uncommented for the final run
    errors = bq_client.insert_rows(table, rows_for_bq)

    if errors == []:
        logging.info("Data successfully loaded into BigQuery.")
    else:
        logging.error("Errors occurred while inserting rows into BigQuery:")
        # Log details about the rows that failed
        for error_detail in errors:
            row_index = error_detail['index']
            row_content = rows_for_bq[row_index] if row_index < len(rows_for_bq) else "Row index out of bounds"
            logging.error(f"  Row index {row_index}: {error_detail['errors']}")
            logging.error(f"  Failed row data (approx): {row_content}") # Log the data that failed
else:
    logging.warning("No image data processed or available to load into BigQuery.")

logging.info("\nScript execution completed.")
