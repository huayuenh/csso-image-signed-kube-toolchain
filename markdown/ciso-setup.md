**CISO Code Signing Service and Key Setup**

***Registering***

The compliance-ci-toolchain leverages the CISO services to sign images.
The toolchain admin needs to be registered as a team member on CISO.
Users can register here:

[[https://pgawdccosig01.sl.bluecloud.ibm.com/]{.ul}](https://pgawdccosig01.sl.bluecloud.ibm.com/)

![](https://github.ibm.com/one-pipeline/docs/blob/signingdocs/assets/signing-setup/ciso/landingpage.png)



Once registered visit the page again and log in.

At this point you can request a certificate or have an existing one
uploaded to the HSM (Hardware Security Module)

![](https://github.ibm.com/one-pipeline/docs/blob/signingdocs/assets/signing-setup/ciso/certrequest.png)

When ready click on the Local Sign button

![](https://github.ibm.com/one-pipeline/docs/blob/signingdocs/assets/signing-setup/ciso/localsign.png)

Select the following options:

![](https://github.ibm.com/one-pipeline/docs/blob/signingdocs/assets/signing-setup/ciso/installer.png)

Click Review Parameters and generate your client bundle.

Extract the contents of the generated .tar file and look for the .pfx
file. This certificate acts as the key to the users partition. This key
needs to be saved in a means that can be accessed by a pipeline run.

***Saving the certificate to Key Protect***

Visit
[[https://cloud.ibm.com/catalog/services/key-protect]{.ul}](https://cloud.ibm.com/catalog/services/key-protect)

Create a new Key Protect instance or use an existing one.

Select the region and specify the a service name for the instance.

Uploading the certificate to the Vault.

The certificate content must be converted to a base64 string and the
output captured.

This can be done with the following command

cat Client_XXXXXXXXXXXXXXXXX.pfx \| base64 or piped to a file. Make sure
to delete the file when finished with it.

Go to
[[https://cloud.ibm.com/resources]{.ul}](https://cloud.ibm.com/resources)
and click the Key Protect instance that was created.

Click the Add Key button

![](https://github.ibm.com/one-pipeline/docs/blob/signingdocs/assets/signing-setup/ciso/create_key.png)

On the following dialog, select Import Key and Standard Key.

Set a name for the key and paste the base64 encoded certificate into the
key material field.

Click import key

![](https://github.ibm.com/one-pipeline/docs/blob/signingdocs/assets/signing-setup/ciso/set_key_data.png)

Make note of the Key-protect service instance name as well as the key
name as these will be required when configuring the Compliance Template
