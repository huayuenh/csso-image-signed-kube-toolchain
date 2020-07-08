#!/bin/bash
function retrieve_secret {

    VAULT_SERVICE_NAME=$1 #name of the Key-Protect instance
    VAULT_REGION=$2 #region where the Key-Instance was set up -> us-south
    RESOURCE_GROUP=$3 # Default
    SECRET_NAME=$4 
    APIKEY=$5 #access apikey

    #exit if any of these values are not set
    check_value ${VAULT_SERVICE_NAME}
    check_value ${VAULT_REGION}
    check_value ${RESOURCE_GROUP}
    check_value ${SECRET_NAME}
    check_value ${APIKEY}

    #Get the Key-Protect instance UUID    
    VAULT_INSTANCE_GUID=$(get_guid $VAULT_SERVICE_NAME)

    #Generate the IAM Bearer token
    VAULT_ACCESS_TOKEN=$(get_access_token $APIKEY)
    check_value $VAULT_ACCESS_TOKEN

    #Get list of all keys in specified instance
    LIST_OF_KEYS=$(get_keys "$VAULT_REGION" "$VAULT_ACCESS_TOKEN" "$VAULT_INSTANCE_GUID")
    check_value ${LIST_OF_KEYS}

    #Get Key UUID of named key
    KEY_UUID=$(echo "$LIST_OF_KEYS" | jq -e -r '.resources[] | select(.name=="'${SECRET_NAME}'") | .id')
    check_value ${KEY_UUID}

    KEY_DATA=$(get_key_value "$VAULT_REGION" "$VAULT_ACCESS_TOKEN" "$VAULT_INSTANCE_GUID" "$KEY_UUID")
    check_value ${KEY_DATA}
    KEY_VALUE=$(echo "$KEY_DATA" | jq -e -r '.resources[] | select(.name=="'${SECRET_NAME}'") | .payload')
    echo "$KEY_VALUE"
}

# returns an IAM access token given an API key
function get_access_token {
  IAM_ACCESS_TOKEN_FULL=$(curl -s -k -X POST \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --header "Accept: application/json" \
  --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
  --data-urlencode "apikey=$1" \
  "https://iam.cloud.ibm.com/identity/token")
  IAM_ACCESS_TOKEN=$(echo "$IAM_ACCESS_TOKEN_FULL" | \
    grep -Eo '"access_token":"[^"]+"' | \
    awk '{split($0,a,":"); print a[2]}' | \
    tr -d \")
  echo $IAM_ACCESS_TOKEN
}

#retrieves data for all keys in specified Key-Protect instance
function get_keys {
  REGION=$1
  IAMTOKEN=$2
  INSTANCE_ID=$3
  list=$(curl https://us-south.kms.cloud.ibm.com/api/v2/keys \
  -H "authorization: Bearer ${IAMTOKEN}"\
   -H "bluemix-instance: ${INSTANCE_ID}"\
   -H "accept: application/vnd.ibm.kms.key+json")
   echo $list
}

#retrieves a specific key payload
function get_key_value {
  REGION=$1
  IAMTOKEN=$2
  INSTANCE_ID=$3
  KEY_UUID=$4
  payload=$(curl https://us-south.kms.cloud.ibm.com/api/v2/keys/${KEY_UUID} \
  -H "authorization: Bearer ${IAMTOKEN}"\
   -H "bluemix-instance: ${INSTANCE_ID}"\
   -H "accept: application/vnd.ibm.kms.key+json")
   echo $payload
}

# returns a service GUID given a service name
function get_guid {
  OUTPUT=$(ibmcloud resource service-instance --id $1)
  if (echo $OUTPUT | grep -q "crn:v1" >/dev/null); then
    echo $OUTPUT | awk -F ":" '{print $8}'
  else
    echo "Failed to get GUID: $OUTPUT"
    exit 2
  fi
}

function check_value {
  if [ -z "$1" ]; then
    exit 1
  fi

  if echo $1 | grep -q -i "failed"; then
    exit 2
  fi
}
