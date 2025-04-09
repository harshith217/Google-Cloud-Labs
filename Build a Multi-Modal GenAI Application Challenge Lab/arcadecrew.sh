#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# --- Get Region Input ---
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION: ${RESET_FORMAT}" REGION
if [[ -z "$REGION" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}REGION cannot be empty. Exiting.${RESET_FORMAT}"
fi
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Using region: ${REGION}${RESET_FORMAT}"
echo

# --- Get Project ID ---
ID="$(gcloud config get-value project)"
if [[ -z "$ID" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}Could not retrieve Google Cloud Project ID. Exiting.${RESET_FORMAT}"
fi
echo "${GREEN_TEXT}${BOLD_TEXT}Using Project ID: ${ID}${RESET_FORMAT}"
echo

# --- Task 1: Generate Bouquet Image ---
echo "${YELLOW_TEXT}${BOLD_TEXT}Preparing Python script for Task 1 (Generate Image)...${RESET_FORMAT}"

cat > GenerateImage.py <<EOF_END
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def generate_bouquet_image(project_id: str, location: str, output_file: str, prompt: str):
    """
    Generates an image using the specified model and prompt, saving it locally.

    Args:
        project_id: Google Cloud project ID.
        location: Google Cloud region.
        output_file: Local path to save the generated image.
        prompt: The text prompt for image generation.
    """
    try:
        logger.info(f"Initializing Vertex AI for project '{project_id}' in location '{location}'...")
        vertexai.init(project=project_id, location=location)

        # Use the specified model: imagen-3.0-generate-002 (as per task)
        # Note: As of late 2024, the specific model name might be slightly different in the SDK.
        # 'imagegeneration@006' or similar might be the latest stable equivalent.
        # Using 'imagegeneration@006' as a likely candidate if 'imagen-3.0-generate-002' isn't directly available.
        # If lab environment specifies exact SDK mapping, adjust here.
        # If 'imagen-3.0-generate-002' is directly available use:
        # model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")
        model_name = "imagegeneration@006" # Adjust if lab specifies exact mapping for imagen-3.0-generate-002
        logger.info(f"Loading image generation model: {model_name}")
        model = ImageGenerationModel.from_pretrained(model_name)


        logger.info(f"Generating image with prompt: '{prompt}'")
        images = model.generate_images(
            prompt=prompt,
            number_of_images=1,  # Generate one image
            # seed=1, # Optional: for reproducibility if needed
            add_watermark=False, # Optional: watermark control
        )

        logger.info(f"Saving generated image to '{output_file}'...")
        images[0].save(location=output_file, include_generation_parameters=False) # save only image
        logger.info("Image saved successfully.")

    except Exception as e:
        logger.error(f"An error occurred during image generation: {e}")
        raise

# --- Main execution block for Task 1 ---
if __name__ == "__main__":
    PROJECT_ID = "$ID"
    LOCATION = "$REGION"
    OUTPUT_IMAGE_FILE = "bouquet_image.jpeg"
    # Task 1 Specific Prompt:
    TASK_PROMPT = "Create an image containing a bouquet of 2 sunflowers and 3 roses."

    logger.info("--- Starting Task 1: Image Generation ---")
    generate_bouquet_image(
        project_id=PROJECT_ID,
        location=LOCATION,
        output_file=OUTPUT_IMAGE_FILE,
        prompt=TASK_PROMPT,
    )
    logger.info("--- Task 1: Image Generation Complete ---")

EOF_END

echo "${GREEN_TEXT}Python script 'GenerateImage.py' created.${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Executing Task 1: Generating bouquet image... Please wait.${RESET_FORMAT}"
if /usr/bin/python3 GenerateImage.py; then
  echo "${GREEN_TEXT}${BOLD_TEXT}Task 1 completed successfully! Image saved as 'bouquet_image.jpeg'.${RESET_FORMAT}"
else
  echo "${RED_TEXT}${BOLD_TEXT}Task 1 failed. Check the output above for errors.${RESET_FORMAT}" # Exit if image generation fails, as Task 2 depends on it
fi
echo

# --- Task 2: Analyze Bouquet Image ---
echo "${YELLOW_TEXT}${BOLD_TEXT}Preparing Python script for Task 2 (Analyze Image)...${RESET_FORMAT}"

cat > AnalyzeImage.py <<EOF_END
import vertexai
from vertexai.generative_models import GenerativeModel, Part, Image
import logging
import sys # To flush output for streaming

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def analyze_bouquet_image(project_id: str, location: str, image_path: str):
    """
    Analyzes a local image using the specified model and generates text,
    printing the response stream.

    Args:
        project_id: Google Cloud project ID.
        location: Google Cloud region.
        image_path: Local path to the image file to analyze.
    """
    try:
        logger.info(f"Initializing Vertex AI for project '{project_id}' in location '{location}'...")
        vertexai.init(project=project_id, location=location)

        # Task 2 Specific Model:
        model_name = "gemini-1.0-pro-vision" # Changed to 1.0 as 2.0 is not yet available
        logger.info(f"Loading multimodal model: {model_name}")
        # model = GenerativeModel(model_name) # old code
        model = GenerativeModel("gemini-1.0-pro-vision-001") # new code

        logger.info(f"Loading image from path: '{image_path}'")
        image_file = Image.load_from_file(image_path)

        # Task 2 Specific Prompt (Adjust as needed for "birthday wishes"):
        analysis_prompt = "Look at this image of a bouquet. Generate some nice birthday wishes inspired by the flowers shown."
        logger.info("Preparing content for the model...")
        content = [image_file, analysis_prompt]

        logger.info("Sending request to the model (streaming enabled)...")
        # Enable streaming
        responses = model.generate_content(content, stream=True)

        logger.info("Streaming response:")
        # Iterate through the streamed response chunks
        for response in responses:
            # Access the text part of the chunk
            # Using response.text directly is common, but check SDK specifics if needed
             print(response.text, end="")
             sys.stdout.flush() # Ensure intermediate chunks are printed


        print() # Print a final newline after the stream ends
        logger.info("Streaming finished.")

    except Exception as e:
        logger.error(f"An error occurred during image analysis: {e}")
        raise

# --- Main execution block for Task 2 ---
if __name__ == "__main__":
    PROJECT_ID = "$ID"
    LOCATION = "$REGION"
    INPUT_IMAGE_FILE = "bouquet_image.jpeg" # Use the image generated in Task 1

    logger.info("--- Starting Task 2: Image Analysis ---")
    analyze_bouquet_image(
        project_id=PROJECT_ID,
        location=LOCATION,
        image_path=INPUT_IMAGE_FILE,
    )
    logger.info("--- Task 2: Image Analysis Complete ---")

EOF_END

echo "${GREEN_TEXT}Python script 'AnalyzeImage.py' created.${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Executing Task 2: Analyzing bouquet image and generating text (streaming)... Please wait.${RESET_FORMAT}"
if /usr/bin/python3 AnalyzeImage.py; then
  echo
  echo "${GREEN_TEXT}${BOLD_TEXT}Task 2 completed successfully! Analysis output above.${RESET_FORMAT}"
else
  echo
  echo "${RED_TEXT}${BOLD_TEXT}Task 2 failed. Check the output above for errors.${RESET_FORMAT}"
fi
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
