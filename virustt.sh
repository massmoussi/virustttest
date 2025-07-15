#!/bin/bash

# Function to fetch and display undetected URLs for an IP address
fetch_undetected_urls_for_ip() {
  local ip=$1
  local api_key_index=$2
  local api_key

  if [ $api_key_index -eq 1 ]; then
    api_key="key-1"
  elif [ $api_key_index -eq 2 ]; then
    api_key="key-2"
  else
    api_key="key-3"
  fi

  local URL="https://www.virustotal.com/vtapi/v2/ip-address/report?apikey=$api_key&ip=$ip"

  echo -e "\nFetching data for IP: \033[1;34m$ip\033[0m (using API key $api_key_index)"
  response=$(curl -s "$URL")
  if [[ $? -ne 0 ]]; then
    echo -e "\033[1;31mError fetching data for IP: $ip\033[0m"
    return
  fi

  undetected_urls=$(echo "$response" | jq -r '.undetected_urls[][0]')
  if [[ -z "$undetected_urls" ]]; then
    echo -e "\033[1;33mNo undetected URLs found for IP: $ip\033[0m"
  else
    echo -e "\033[1;32mUndetected URLs for IP: $ip\033[0m"
    echo "$undetected_urls"
  fi
}

# Countdown function
countdown() {
  local seconds=$1
  while [ $seconds -gt 0 ]; do
    echo -ne "\033[1;36mWaiting for $seconds seconds...\033[0m\r"
    sleep 1
    : $((seconds--))
  done
  echo -ne "\033[0K"
}

# Check for input
if [ -z "$1" ]; then
  echo -e "\033[1;31mUsage: $0 <ip or file_with_ips>\033[0m"
  exit 1
fi

# API key rotation
api_key_index=1
request_count=0

# If input is a file
if [ -f "$1" ]; then
  while IFS= read -r ip; do
    ip=$(echo "$ip" | tr -d '[:space:]')
    if [[ -n "$ip" ]]; then
      fetch_undetected_urls_for_ip "$ip" $api_key_index
      countdown 20
      request_count=$((request_count + 1))
      if [ $request_count -ge 5 ]; then
        request_count=0
        if [ $api_key_index -eq 1 ]; then
          api_key_index=2
        elif [ $api_key_index -eq 2 ]; then
          api_key_index=3
        else
          api_key_index=1
        fi
      fi
    fi
  done < "$1"
else
  ip=$(echo "$1" | tr -d '[:space:]')
  fetch_undetected_urls_for_ip "$ip" $api_key_index
fi

echo -e "\033[1;32mAll done!\033[0m"
