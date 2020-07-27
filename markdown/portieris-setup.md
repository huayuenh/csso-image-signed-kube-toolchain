Installing and configuring Portieris

Pre-requisites

Kubernetes 1.16 or above

Helm 3 is required to install Portieris. This needs to be installed on
your workstation.

Installing Helm 3

See <https://helm.sh/docs/intro/install/>

Removing Tiller

Tiller needs to be removed from the cluster. Ensure beforehand that
uninstalling Tiller will not affect any other services

kubectl delete deployment tiller-deploy -n kube-system

kubectl delete service tiller-deploy -n kube-system

(if there are secrets)

kubectl delete secret tiller-secret -n kube-system

Obtain the public key certificate associated with the GPG certificate
signing chain.

Connect to Cluster

Log into your account and ensure that you can run Kube commands. Please
see <https://cloud.ibm.com/kubernetes/clusters> for help

Portieris Installation

Portieris is the gatekeeper that the Compliance-CI-Toolchain leverages
to ensure that only signed images are deployed.

It can be configured to secure cluster-wide deployments or namespace
specific deployments. For this setup we will be using a namespace
specific set up

To get started clone the Protieris repository

<https://github.com/IBM/portieris.git>

Use the same namespace that will be used in the Compliance-CI-Template

Change directory into the Portieris Git repository.

Run **./helm/portieris/gencerts \<namespace\>**

The gencerts script generates new SSL certificates and keys for
Portieris. Portieris presents this certificates to the Kubernetes API
server when the API server makes admission requests. If you do not
generate new certificates, it could be possible for an attacker to spoof
Portieris in your cluster.

Run **kubectl create namespace \<namespace\>**

Run **helm install portieris \--set namespace=\<namespace\>
helm/portieris**

Provisioning the secrets key

With the public key on hand we need to use it to generate a Kubernetes
secret. For this illustration, we will call the public certificate key
from GPG key.asc

First change directory to the one containing the key

Run the following:

kubectl create secret generic **fskey** -n **\<namespace\>**
\--from-file=key=**key.asc**

where fskey will be the name of the secret generated

namespace: the namespace that was or will be used by the Compliance
Template deployment.

key.asc : the public key certificate.

Run:

kubectl get secret -n prod

to see that the secret has been created

Run:

kubectl edit secret fskey -n prod

We can inspect the secret to ensure that there is data under the data
field

Portieris Configuration

Portieris uses two type of resources to manage securing image
deployments to the cluster.

-   ClusterImagePolicy

-   ImagePolices

The ClusterImagePolicy is a cluster level enforcement. It will take
effect when no imagepolicy is available. For example, an image policy is
set up in a namespace called "prod" but an image gets deployed to
"default" in this case the ClusterImagePolicy will be applied.

To view the different policies

kubectl edit clusterimagepolicy

![A screenshot of a cell phone Description automatically
generated](media/image1.png){width="6.268055555555556in"
height="3.4569444444444444in"}

The important part of the above is

spec:

repositories:

-   Name: "\*"

This is the default setting when installed. Basically a wildcard on all
repositories allowing all deployments

kubectl edit imagepolicies default -n prod

![A screenshot of a cell phone Description automatically
generated](media/image2.png){width="6.268055555555556in"
height="3.433333333333333in"}

The "spec" here needs to be modified to enforce a signature constraint
on images from our designated registry namespace.

Edit the image policy to add the following

repositories:

\- name: us.icr.io/hhsigning/\*

policy:

simple:

requirements:

\- keySecret: fskey

type: signedBy

name: refers to the path to the image registry that we wish to check

policy: is the conditions that we which to enforce

type: signedBy requires a signature on the image

keySecret is a reference to the secret that we set up previously from
the GPG public key certificate

The above steps are all the requirements for setting up Portieris in
relation to the Compliant template usage.

Portieris can handle multiple signatures from different sources for
example

repositories:

\- name: us.icr.io/team1-namespace/\*

policy:

simple:

requirements:

\- type: signedBy

keySecret: team1-key

repositories:

\- name: us.icr.io/team2-namespace/\*

policy:

simple:

requirements:

\- type: signedBy

keySecret: team2-key

For more complex setups, please see

See <https://github.com/IBM/portieris> for more details
