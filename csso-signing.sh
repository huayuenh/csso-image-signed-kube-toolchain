#!/bin/bash
echo "VAULT_INSTANCE $VAULT_INSTANCE"
echo "KEY_NAME $KEY_NAME"
echo "REGION $REGION"
echo "RESOURCE_GROUP $RESOURCE_GROUP"
echo "IBM_CLOUD_API_KEY $IBM_CLOUD_API_KEY"
echo "IBM_CLOUD_API_KEY=$IBM_CLOUD_API_KEY" >> build.properties
cat build.properties
ibmcloud login --apikey "$IBM_CLOUD_API_KEY" -r "$IBMCLOUD_TARGET_REGION";

#target registry region
ibmcloud target -r $REGISTRY_REGION
REGISTRY_URL=$(ibmcloud cr info | grep -w 'Container Registry' | awk '{print $3;}' | grep -w 'icr')

ibmcloud target -r $IBMCLOUD_TARGET_REGION

#source <(curl -sSL "https://raw.githubusercontent.com/huayuenh/cssopoc/master/secrets_management.sh")
#source <(curl -sSL "https://raw.githubusercontent.com/huayuenh/cssopoc/master/signing_utils.sh")
#VAULT_DATA=$(buildVaultAccessDetailsJSON "$VAULT_INSTANCE" "$IBMCLOUD_TARGET_REGION" "$RESOURCE_GROUP")
#export result=$(readData "$KEY_NAME" "$VAULT_DATA" "$IBM_CLOUD_API_KEY")
#echo "RESULT DATA $result"

source <(curl -sSL "https://raw.githubusercontent.com/huayuenh/cssopoc/master/key_protect_utils.sh")
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

echo "CSSO service"
#ucl list

gpgconf --kill all
#ucl pgp-key -n 509Deloreandeloreanpfx
gpgconf --kill all
echo "note finger print of pgp"
fingerprint=$(gpg2 -k)
echo $fingerprint
echo "list keys"
gpg --list-keys
ls -a /root/.gnupg
mkdir testsign
echo "PULL IMAGE"
skopeo copy docker://us.icr.io/tektonhh/hello-containers-20200625115240818:1-master-972c9342-20200625115851 dir:testsign --src-creds iamapikey:$IBM_CLOUD_API_KEY
skopeo copy docker://${REGISTRY_URL}/${REGISTRY_NAMESPACE}/
echo "BEGIN SIGNING PUSH TO REPO"
skopeo copy dir:testsign docker://us.icr.io/tektonhh/hello-containers4-20200625115240818:1-master-signed-972c9342-20200625115851 --dest-creds iamapikey:$IBM_CLOUD_API_KEY  --sign-by C61C3D4568ED391949AB8FA3DBF84264585F8C9C

echo "SIGN LOCALLY" 
skopeo standalone-sign ./testsign/manifest.json tektonhh/hello-containers-20200625115240818:1-master-972c9342-20200625115851 C61C3D4568ED391949AB8FA3DBF84264585F8C9C  -output ./testsign/signature

echo "VERIFY LOCAL SIGN"
skopeo standalone-verify ./testsign/manifest.json tektonhh/hello-containers-20200625115240818:1-master-972c9342-20200625115851 C61C3D4568ED391949AB8FA3DBF84264585F8C9C ./testsign/signature

echo "verify remote"
rm -rf ./testsign
mkdir verify
skopeo copy docker://us.icr.io/tektonhh/hello-containers4-20200625115240818:1-master-signed-972c9342-20200625115851 dir:verify --src-creds iamapikey:$IBM_CLOUD_API_KEY
ls ./verify
skopeo standalone-verify ./verify/manifest.json us.icr.io/tektonhh/hello-containers4-20200625115240818:1-master-signed-972c9342-20200625115851 C61C3D4568ED391949AB8FA3DBF84264585F8C9C ./verify/signature-3

