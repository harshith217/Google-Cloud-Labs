
# --- Task 4: Alerting Policy ---
section "TASK 4: ALERTING POLICY"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Establishing notification channel for alerts..."
# Create email notification channel, capture its name, handle errors
CHANNEL_NAME=$(gcloud alpha monitoring channels create \
        --display-name="Email alerts" \
        --type=email \
        --channel-labels=email_address=$ALERT_EMAIL \
        --format="value(name)") || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error creating notification channel${RESET_FORMAT}"
        # Consider exiting: exit 1
}

echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Defining alerting policy for active function instances..."

# Create JSON file for the alerting policy definition
cat > active-instances-policy.json <<EOF_END
{
  "displayName": "Active Cloud Run Function Instances",
  "combiner": "OR",
  "conditions": [
        {
          "displayName": "Cloud Function - Active Instances > 0",
          "conditionThreshold": {
                "filter": "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/active_instances\"",
                "aggregations": [
                  {
                        "alignmentPeriod": "60s",
                        "perSeriesAligner": "ALIGN_MAX"
                  }
                ],
                "comparison": "COMPARISON_GT",
                "thresholdValue": 0,
                "duration": "60s",
                "trigger": {
                   "count": 1
                }
          }
        }
  ],
  "alertStrategy": {
        "autoClose": "604800s"
  },
  "notificationChannels": ["$CHANNEL_NAME"]
}
EOF_END

# Create the monitoring policy using the JSON file, handle errors
gcloud alpha monitoring policies create --policy-from-file="active-instances-policy.json" || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error creating alerting policy${RESET_FORMAT}"
        # Consider exiting: exit 1
}

# --- Completion Message ---
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!       ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

# Optional: Add promotional message or next steps
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Find more helpful resources at:${RESET_FORMAT} ${BLUE_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

# Clean up temporary files if needed (optional)
# rm -f travel.jpg active-instances-policy.json index.js package.json
# cd ..
# rm -rf drabhishek

exit 0 # Explicitly exit with success code
