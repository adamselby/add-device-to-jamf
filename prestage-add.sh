#!/bin/bash
# Created by Adam Selby for
# University of North Texas

# This directly builds on this script by talkingmoose at https://gist.github.com/talkingmoose/327427d23b422000f9d17183f8ef1d22

# INPUTS
# 1 - prestage ID
# 2 - device type as required by Jamf
# 3 - serial number X0XX234XYXYX
# 4 - asset tag 123456

# Server and API info
jamfServer="https://jamf.yourdomain.edu"
apiUser="jamfAPIuser"
apiPassword="jamfAPIpassword"

# Parse the submitted input into a PreStage ID
# PreStage IDs are the same across device types in our environment
# We pull this in via a web form labeled "Device Use"
prestageInput="$1"
if [ "$prestageInput" = "Faculty" ]
then
    prestageValue="2"
    echo "Device Use identified as faculty, which is Prestage ID $prestageValue, continuing…"
fi
if [ "$prestageInput" = "Labs" ]
then
    prestageValue="1"
    echo "Device Use identified as labs, which is Prestage ID $prestageValue, continuing…"
fi

# Parse the submitted input into a device type Jamf understands
# These are Computer or Mobile Device, but this simplifies things for our use case
# We pull this in via a web form labeled "Device Type"

deviceTypeInput="$2"
if [ "$deviceTypeInput" = "Mac" ]
then
    deviceTypeValue="Computer"
    echo "Device Type identified as Mac, which is a $deviceTypeValue, continuing… "
fi
if [ "$deviceTypeInput" = "iPad" ]
then
    deviceTypeValue="Mobile Device"
    echo "Device Type identified as iPad, which is a $deviceTypeValue, continuing…"
fi
if [ "$deviceTypeInput" = "iPod" ]
then
    deviceTypeValue="Mobile Device"
    echo "Device Type identified as iPod, which is a $deviceTypeValue, continuing…"
fi
if [ "$deviceTypeInput" = "iPhone" ]
then
    deviceTypeValue="Mobile Device"
    echo "Device Type identified as iPhone, which is a $deviceTypeValue, continuing…"
fi
if [ "$deviceTypeInput" = "Apple TV" ]
then
    deviceTypeValue="Mobile Device"
    echo "Device Type identified as Apple TV, which is a $deviceTypeValue, continuing…"
fi

# Pull in a single or list of serial numbers and asset tags
# We only allow one submission at a time, but this "should" work for multiple serial numbers or asset tags with minimal work
serialNumberList=($3)
assetTagList=($4)

echo "Serial identified as $serialNumberList, continuing…"
echo "Asset tag identified as $assetTagList, continuing…"

# this function was sourced from https://stackoverflow.com/a/26809278
function json_array() {
  echo -n '['
  while [ $# -gt 0 ]; do
    x=${1//\\/\\\\}
    echo -n \"${x//\"/\\\"}\"
    [ $# -gt 1 ] && echo -n ', '
    shift
  done
  echo ']'
}

# format lists for json
formattedSerialNumberList=$( json_array "${serialNumberList[@]}" )
formattedAssetTagList=$( json_array "${assetTagList[@]}" )

# create json data for submission
preloadData="{
  \"serialNumber\": \"$3\",
  \"deviceType\": \"$deviceTypeValue\",
  \"assetTag\": \"$4\"
}"

# create base64-encoded credentials
encodedCredentials=$( printf "$apiUser:$apiPassword" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token per Jamf API
authToken=$( /usr/bin/curl "$jamfServer/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic $encodedCredentials" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

if [ "$deviceTypeValue" = "Computer" ]
then
    echo "Device Type is $deviceTypeValue, adding to PreStage… "
    # get existing json for PreStage ID
    prestageJson=$( /usr/bin/curl "$jamfServer/uapi/v1/computer-prestages/$prestageValue/scope" \
    --silent \
    --request GET \
    --header "Authorization: Bearer $token" )

    # parse prestage json for current versionLock number
    versionLock=$( /usr/bin/awk '/\"versionLock\" : / { print $3 }' <<< "$prestageJson" )

    echo "Creating json data and submitting information to Jamf…"

    # create json data for submission
    prestageData="{
      \"serialNumbers\": $formattedSerialNumberList,
      \"versionLock\": $versionLock
    }"

    echo -e "\nScoping $3 to $prestageInput PreStage…"

    # submit new scope for PreStage ID
    /usr/bin/curl "$jamfServer/uapi/v1/computer-prestages/$prestageValue/scope" \
    --silent \
    --request POST \
    --header "Authorization: Bearer $token" \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --data "$prestageData"
fi

if [ "$deviceTypeValue" = "Mobile Device" ]
then
    echo "Device Type is $deviceTypeValue, adding to PreStage… "
    # get existing json for PreStage ID
    prestageJson=$( /usr/bin/curl "$jamfServer/uapi/v1/mobile-device-prestages/$prestageValue/scope" \
    --silent \
    --request GET \
    --header "Authorization: Bearer $token" )

    # parse prestage json for current versionLock number
    versionLock=$( /usr/bin/awk '/\"versionLock\" : / { print $3 }' <<< "$prestageJson" )

    echo "Creating json data and submitting information to Jamf…"

    # create json data for submission
    prestageData="{
      \"serialNumbers\": $formattedSerialNumberList,
      \"versionLock\": $versionLock
    }"

    echo -e "\nScoping $3 to $prestageInput PreStage…"

    # submit new scope for PreStage ID
    /usr/bin/curl "$jamfServer/uapi/v1/mobile-device-prestages/$prestageValue/scope" \
    --silent \
    --request POST \
    --header "Authorization: Bearer $token" \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --data "$prestageData"
fi

echo -e "\n\nAdding $3 ($deviceTypeValue) to Inventory Preload…"

# add device to Inventory Preload
/usr/bin/curl "$jamfServer/uapi/v2/inventory-preload/records/" \
--silent \
--request POST \
--header "Authorization: Bearer $token" \
--header "Accept: application/json" \
--header "Content-Type: application/json" \
--data "$preloadData"

echo -e "\n\nDone, expiring token and exiting…"

# expire the auth token
/usr/bin/curl "$jamfServer/uapi/auth/invalidateToken" \
--silent \
--request POST \
--header "Authorization: Bearer $token"

exit 0