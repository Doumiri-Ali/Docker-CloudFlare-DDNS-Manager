#!/bin/bash

# Load environment variables
auth_email="$AUTH_EMAIL"
auth_key="$AUTH_KEY"
zone_identifier="$ZONE_IDENTIFIER"
record_names="$RECORD_NAMES"
ttl="${TTL:-3600}"  # Default to 3600 if not set
proxy="${PROXY:-false}"  # Default to false if not set
report_success="${REPORT_SUCCESS:-false}"
report_error="${REPORT_ERROR:-true}"
# Notification channels
slackuri="$SLACK_URI"
slackchannel="$SLACK_CHANNEL"
discorduri="$DISCORD_URI"
telegram_token="$TELEGRAM_BOT_TOKEN"
telegram_chat="$TELEGRAM_CHAT_ID"

# Function to send notifications
send_notification() {
    local message="$1"
    local is_error="$2"
    
    # Check if we should send this notification
    if [ "$is_error" = "true" ] && [ "$report_error" != "true" ]; then
        return
    fi
    if [ "$is_error" = "false" ] && [ "$report_success" != "true" ]; then
        return
    fi
    
    # Send to Slack
    if [[ $slackuri != "" && $slackchannel != "" ]]; then
        curl -s -L -X POST "$slackuri" \
        --data-raw "{\"channel\":\"$slackchannel\",\"text\":\"$message\"}" > /dev/null
    fi
    
    # Send to Discord
    if [[ $discorduri != "" ]]; then
        curl -s -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST \
        --data-raw "{\"content\":\"$message\"}" "$discorduri" > /dev/null
    fi
    
    # Send to Telegram
    if [[ $telegram_token != "" && $telegram_chat != "" ]]; then
        curl -s -X POST "https://api.telegram.org/bot${telegram_token}/sendMessage" \
        -d "chat_id=${telegram_chat}" \
        -d "text=${message}" \
        -d "parse_mode=HTML" > /dev/null
    fi
}

# Verify required variables
if [ -z "$auth_email" ] || [ -z "$auth_key" ] || [ -z "$zone_identifier" ] || [ -z "$record_names" ]; then
    echo "Error: Required environment variables are not set"
    exit 1
fi

###########################################
## Check if we have a public IP
###########################################
ipv4_regex='([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])'
ip=$(curl -s -4 https://api.ipify.org || curl -s https://ipv4.icanhazip.com)

# Use regex to check for proper IPv4 format.
if [[ ! $ip =~ ^$ipv4_regex$ ]]; then
    echo "DDNS Updater: Failed to find a valid IP."
    send_notification "❌ DDNS Updater: Failed to find a valid IP." true
    exit 2
fi

echo "DDNS Updater: Current public IP is $ip"

###########################################
## Process each record
###########################################

# Convert comma-separated string to array
IFS=',' read -ra RECORDS <<< "$record_names"

for record_name in "${RECORDS[@]}"; do
    # Trim whitespace
    record_name=$(echo "$record_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    echo "DDNS Updater: Processing record $record_name"
    
    ###########################################
    ## Seek for the A record
    ###########################################
    
    echo "DDNS Updater: Check Initiated for $record_name"
    record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name" \
         -H "X-Auth-Email: $auth_email" \
         -H "X-Auth-Key: $auth_key" \
         -H "Content-Type: application/json")
    
    echo "DEBUG: API Response for $record_name: $record"
    
    ###########################################
    ## Check if the domain has an A record
    ###########################################
    if [[ $record == *"\"count\":0"* ]]; then
        echo "DDNS Updater: Creating new record for $record_name with IP ${ip}"
        create=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" \
             -H "X-Auth-Email: $auth_email" \
             -H "X-Auth-Key: $auth_key" \
             -H "Content-Type: application/json" \
             --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":$ttl,\"proxied\":$proxy}")
        
        if [[ $create == *"\"success\":true"* ]]; then
            echo "DDNS Updater: Successfully created record for $record_name with IP: $ip"
            send_notification "✅ Record <b>$record_name</b> created with IP: $ip" false
        else
            echo "DDNS Updater: Failed to create record for $record_name. Response: $create"
            send_notification "❌ Failed to create record <b>$record_name</b>. Error: $create" true
        fi
        continue
    fi
    
    if [[ $record != *"\"success\":true"* ]]; then
        echo "DDNS Updater: Failed to get record for $record_name. Response: $record"
        send_notification "❌ Failed to get record <b>$record_name</b>. Error: $record" true
        continue
    fi
    
    ###########################################
    ## Get existing IP and record info
    ###########################################
    old_ip=$(echo "$record" | sed -E 's/.*"content":"([0-9.]+)".*/\1/')
    current_proxied=$(echo "$record" | sed -E 's/.*"proxied":([^,}]+).*/\1/')
    
    # Compare if they're the same
    if [[ $ip == $old_ip ]]; then
        echo "DDNS Updater: IP ($ip) for ${record_name} has not changed."
        continue
    fi
    
    echo "DDNS Updater: IP change detected for $record_name: $old_ip -> $ip"
    
    ###########################################
    ## Set the record identifier from result
    ###########################################
    record_identifier=$(echo "$record" | sed -E 's/.*"id":"([A-Za-z0-9_]+)".*/\1/')
    
    ###########################################
    ## Change the IP@Cloudflare using the API
    ###########################################
    update_data="{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":$ttl,\"proxied\":$proxy}"
    echo "DEBUG: Update request data: $update_data"
    
    update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
         -H "X-Auth-Email: $auth_email" \
         -H "X-Auth-Key: $auth_key" \
         -H "Content-Type: application/json" \
         --data "$update_data")
    
    echo "DEBUG: Update response: $update"
    
    ###########################################
    ## Report the status
    ###########################################
    if [[ $update == *"\"success\":true"* ]]; then
        echo "DDNS Updater: Successfully updated $record_name (ID: $record_identifier) to IP: $ip"
        send_notification "✅ Record <b>$record_name</b> updated to IP: $ip" false
    else
        echo "DDNS Updater: Failed to update $record_name. Response: $update"
        send_notification "❌ Failed to update <b>$record_name</b>. Error: $update" true
    fi
    
    # Add a small delay between updates
    sleep 2
done

# Exit successfully
exit 0
