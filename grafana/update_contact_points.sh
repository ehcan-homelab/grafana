#!/bin/bash

# Set variables
GRAFANA_URL="${GRAFANA_URL}"
GRAFANA_API_KEY="${GRAFANA_API_KEY}"
CONTACT_POINTS_DIR="${CONTACT_POINTS_DIR}"
SECRET_DISCORD_WEBHOOK_URL="${SECRET_DISCORD_WEBHOOK_URL}"

# Function to update a single contact point
update_contact_point() {
    local contact_point_file=$1

    # Read the contact_point JSON content
    contact_point_json=$(cat "$contact_point_file")

    # replace secrets
    payload="${contact_point_json//__DISCORD_WEBHOOK_URL__/$SECRET_DISCORD_WEBHOOK_URL}"

    response=$(curl --write-out "%{http_code}" --output /dev/null --location "$GRAFANA_URL/api/v1/provisioning/contact-points" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $GRAFANA_API_KEY" \
        --data "$payload")

    # Check if the response is 409 (Conflict)
    if [ "$response" -eq 409 ]; then
        uid=$(echo "$payload" | jq -r '.uid')
        echo "Updating contact point with UID: $uid"

        # Send PUT request
        curl --location "$GRAFANA_URL/api/v1/provisioning/contact-points/$uid" \
            --request PUT \
            --header 'Content-Type: application/json' \
            --header "Authorization: Bearer $GRAFANA_API_KEY" \
            --data "$payload"
    else
        echo "Contact point created successfully"
    fi
}

# Loop through all JSON files in the contact_points directory
for contact_point_file in "$CONTACT_POINTS_DIR"/*.json; do
    if [ -f "$contact_point_file" ]; then
        update_contact_point "$contact_point_file"
    fi
done
