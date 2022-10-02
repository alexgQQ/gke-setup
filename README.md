# GKE Setup

This repo is a collection of resources for running a low cost GKE cluster as an http backend with multi-service capability. This works by using cloudflare dns to route traffic to a k8s node and directing requests with an edge router. The motivation for this is to be able to use GKE instances with all the managed goodness but without having to use their expensive load balancers.

For starters getting an external ip for a cluster isn't difficult. GKE nodes get a public ip by default but they have this habbit of changing after auto updates occur, and I want those auto updates. To keep a consistent external ip we can reserve a static ip with Google and use [kubeip](https://kubeip.com/) to monitor and assign this ip to the node. Handling traffic into our cluster isn't difficult either. Aside from a load balancer, the [NodePort service](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) can be exposed to external traffic through a node's external ip. The caveat is that by default only ports within 30000-32767 are exposed and using lower ports is prohibited. Keep this in mind for later. To facilitate multiple services we can make use of [traefik](https://doc.traefik.io/traefik/) as an edge router. This will handle http traffic and will dynamically discover internal services and route them based on path mapping rules we defined. Finally we just need a DNS provider. Google Cloud DNS seems obvious but that also costs money and is lacking a specific feature. Instead we'll use Cloudflare, not only for the free tier usage on a single zone, but also for the ability to use Cloudflare [Origin Rules](https://developers.cloudflare.com/rules/origin-rules/) to do a port rewrite and direct http traffic to our specific node port.


## Install

This install requires the following software:
* [gcloud](https://cloud.google.com/sdk/docs/install)
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [helm](https://helm.sh/docs/intro/install/)
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

Additionally you will need:
* An active google cloud project with billing enabled
* A cloudflare account (free tier works fine)
* A domain available to register

If you have all that, authorize and configure your gcloud sdk client
```bash
export GCP_PROJECT=<gcp project id>
export GCP_ZONE=<gcp zone>

gcloud auth application-default login
gcloud config set project $GCP_PROJECT
```

### terraform

The `/terraform` directory contains the terraform for all the resources needed. You will need to populate a `terraform.tfvars` file in that directory with the following desired configuration. The [cloudlfare token](https://developers.cloudflare.com/api/get-started/create-token/) requires edit permissions for the zones origin ruls and dns configuration.
```bash
echo "
gke_project          = $GCP_PROJECT
gke_zone             = $GCP_ZONE
gke_region           = <gcp region>
cloudflare_api_token = <cloudflare token>
cloudflare_zone_id   = <cloudflare zone id>
cloudflare_domain    = <mydomain.com>
" > terraform/terraform.tfvars
```

Once that is in place you can initialize the module and apply it. This will create all our resources and sets up dns to route to `api.mydomain.com`.
```bash
terraform -chdir=terraform init
terraform -chdir=terraform plan  # If you want to check the resources
terraform -chdir=terraform apply
```

It takes 5-10 minutes to fully provision. After it is done you'll need to authenticate and connect to the cluster. By default the cluster name is primary-cluster.
```bash
gcloud container clusters get-credentials --region $GCP_ZONE primary-cluster
```

To remove the resources.
```bash
terraform -chdir=terraform destroy
```
As a note, destroying the resources through terraform doesn't always remove the cloudflare ruleset that is created. It must be manually removed via their api as free tier accounts are only allowed one ruleset. Using a cloudflare api token with read and write access to your account rulesets, get the ruleset id and then delete it.
```bash
# Grab the custom ruleset id and then delete
curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets" -H "Authorization: Bearer "$CLOUDFLARE_API_TOKEN"" -H "Content-Type: application/json"
curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESET_ID" -H "Authorization: Bearer "$CLOUDFLARE_API_TOKEN"" -H "Content-Type: application/json"
```

### kubeip

For kubeip to function you need to authorize a cluster admin role for the service with your end user and give it a specific service account to use. Update the `/kubeip/values.yaml` file with the `userEmail` of your end user account then generate a service account key to be deployed as a secret.
```bash
gcloud iam service-accounts keys create kubeip/key.json --iam-account kubeip@$GCP_PROJECT.iam.gserviceaccount.com
```

Deploy the kubeip resources.
```bash
helm install kubeip kubeip
```

### traefik

This doesn't need special configuration and can be deployed from the chart as is. This will expose traffic on port 30000 by default.
```bash
helm install traefik traefik
```

Go ahead and test it out by deploying the example service.
```bash
helm install whoami example
```
Traefik will detect the service and ingress rules and will route all traffic here. Hit your service and you should get a echo like who am I response.
```bash
$ curl -X GET "https://api.mydomain.com" -H "Content-Type: application/json"
Hostname: whoami-deployment-6b7bcddbfc-gf6pd
IP: 127.0.0.1
IP: 10.0.2.6
RemoteAddr: 10.0.2.5:56810
GET / HTTP/1.1
Host: api.mydomain.com
User-Agent: curl/7.68.0
Accept: */*
Accept-Encoding: gzip
Cdn-Loop: cloudflare
Cf-Connecting-Ip: 71.33.152.214
Cf-Ipcountry: US
Cf-Ray: 752a5b508ac4e95a-DFW
Cf-Visitor: {"scheme":"https"}
Content-Type: application/json
X-Forwarded-For: 10.0.2.1
X-Forwarded-Host: api.mydomain.com
X-Forwarded-Port: 80
X-Forwarded-Proto: http
X-Forwarded-Server: traefik-deployment-6c4475d897-ccfxw
X-Real-Ip: 10.0.2.1
```

If all that checks out then you are all set. Uninstall that whoami chart and start deploying whatever to your cluster.
