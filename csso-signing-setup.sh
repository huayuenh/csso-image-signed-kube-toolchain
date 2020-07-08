#!/bin/bash
#Required parameters
#VAULT_INSTANCE - name of the Key-Protect instance
#KEY_NAME - name of the key entry in Key-Protect key name must match CSSO cert name
#REGION - region containing the Key-Protect instance
#RESOURCE_GROUP - "Default" by default. Resource Group of Key-Protect
#IBM_CLOUD_API_KEY - access ibm cloud apikey
#IMAGE_NAME - name of the image
#IMAGE_TAG - the required tag name
#REGISTRY_NAMESPACE - the namespace of the registry containing storing the images

ibmcloud login --apikey "$IBM_CLOUD_API_KEY" -r "$IBMCLOUD_TARGET_REGION";

ibmcloud target -r ${REGISTRY_REGION}
#REGISTRY_URL - the registry URL e.g. us.icr.io, de.icr.io
REGISTRY_URL=$(ibmcloud cr info | grep -w 'Container Registry' | awk '{print $3;}' | grep -w 'icr')
ibmcloud target -r ${IBMCLOUD_TARGET_REGION}



echo "VAULT_INSTANCE $VAULT_INSTANCE"
echo "KEY_NAME $KEY_NAME"
echo "REGION $REGION"
echo "RESOURCE_GROUP $RESOURCE_GROUP"
echo "IBM_CLOUD_API_KEY $IBM_CLOUD_API_KEY"
echo "IMAGE_NAME $IMAGE_NAME"
echo "IMAGE_TAG $IMAGE_TAG"
echo "REGISTRY_NAMESPACE $REGISTRY_NAMESPACE"
echo "REGISTRY_URL $REGISTRY_URL"

#Use utility script for reading from Key Protect
source <(curl -sSL "https://raw.githubusercontent.com/huayuenh/csso-image-signed-kube-toolchain/master/key_protect_utils.sh")
export secret=$(retrieve_secret "${VAULT_INSTANCE}" "${IBMCLOUD_TARGET_REGION}" "${RESOURCE_GROUP}" "${KEY_NAME}" "${IBM_CLOUD_API_KEY}")
export filename=${KEY_NAME}

#create python script for decoding base64 binary file
#handles binary data better than bash
cat << EOF > decode.py
#!/usr/bin/env python
import base64
import os
inputdata=os.environ["secret"]
outputname=os.environ["filename"]
result=base64.b64decode(inputdata)
f=open(outputname, 'wb')
f.write(result)
EOF

chmod 755 ./decode.py

echo "CHECK PYTHON3 version"
python3 --version
#run python script
echo "RESTORING KEY DATA"
python3 ./decode.py
ls -a /etc/ekm
mv ./$KEY_NAME /etc/ekm
echo "****************"
ls -a /etc/ekm

#extract alias
ALIAS=$(ucl list)
ALIAS=${ALIAS%"Private"*}
ALIAS=${ALIAS#*"Name="}
ALIAS="${ALIAS//\"}"
echo "Alias: $ALIAS"

gpgconf --kill all
ucl pgp-key -n ${ALIAS}
FINGERPRINT=$(gpg2 -k)
FINGERPRINT=${FINGERPRINT%"uid"*}
FINGERPRINT=${FINGERPRINT#*"[SCEA]"}
FINGERPRINT=$(echo ${FINGERPRINT} | sed 's/^[ \t]*//;s/[ \t]*$//')
echo "FINGERPRINT $FINGERPRINT"
gpg --list-keys
ls -a /root/.gnupg

SIGNING_DIR="signing"
mkdir ${SIGNING_DIR}

SIGNING_KEY=${FINGERPRINT}



#echo "SIGN LOCALLY" 
#skopeo standalone-sign ./${SIGNING_DIR}/manifest.json ${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG} ${SIGNING_KEY}  -output ./${SIGNING_DIR}/signature

#echo "VERIFY LOCAL SIGN"
#skopeo standalone-verify ./${SIGNING_DIR}/manifest.json ${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG} ${SIGNING_KEY} ./${SIGNING_DIR}/signature
