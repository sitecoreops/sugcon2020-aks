# SUGCON 2020: Return of the Painless Sitecore Deployment

This repository demonstrates:

- Minimal Sitecore 9.3 XM solution with Unicorn.
- Local development environment with debugging and log streaming.
- Isolated solution build *inside* container using only Docker Compose.
- Azure DevOps [multi-stage pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/multi-stage-pipelines-experience?view=azure-devops) for complete CI/CD also using the [environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments-kubernetes?view=azure-devops) feature which is offering traceability, history and diagnostics of deployed resources.
- Dynamic deployment of *any* branch into a Kubernetes cluster namespace with auto generated DNS for ingress, secured with [Let's Encrypt](https://letsencrypt.org) TLS certificates.
- Unicorn sync during deployment.
- Rolling updates of Content Delivery pods.
- Helm 3 and public Sitecore charts used for doing deployments.

## Running the solution

1. Authenticate with the registry: `az acr login --name <YOUR REGISTRY>` or `docker login`.
1. Start with: `docker-compose up --build`.

## Azure DevOps Pipelines configuration

Before the first run the following needs to be in place.

### Service Connections

Add the following connections:

1. A administrative **Kubernetes** connection to your cluster:
    - Namespace: **default**
    - Use cluster admin credentials: **Checked**
    - Grant access permission to all pipelines: **Checked**
1. A *SOURCE* **Docker Registry** connection, this is the one that has the Sitecore base images:
    - Grant access permission to all pipelines: **Checked**
1. A *TARGET* **Docker Registry** connection, this should be accessible by your cluster:
    - Grant access permission to all pipelines: **Checked**

### YAML pipeline variables

You need to fill out these required variable values in [azure-pipelines.yml](azure-pipelines.yml):

| Name | Value |
| ---- | ----- |
| `project_name` | The name of your project, lowercase. Used in image names, namespaces, dns etc. |
| `source_docker_registry` | Name of the Docker Registry service connection with Sitecore base images |
| `target_docker_registry` | Name of the Docker Registry service connection that is accessible by your cluster|
| `k8s_admin_service_connection_testing` | Name of the Kubernetes service connection with **cluster admin** credentials |
| `k8s_admin_service_connection_production` | Name of the Kubernetes service connection with **cluster admin** credentials |
| `windows_poolname` | Name of an agent pool that can build Windows Server 2019 LTSC images |
| `dns_tld` | Some DNS name with a wildcard A record pointing to cluster loadbalancer IP.

### Environments

1. Add an **EMPTY** environment named `testing`:
    1. Add a **Kubernetes Resource** with a new namespace in your cluster named: `test-<project_name>-master`.
1. Add an **EMPTY** environment named `production`:
    1. Add a **Kubernetes Resource** with a new namespace in your cluster named: `prod-<project_name>-master`.

> For demo purposes we are using the *same* cluster for both testing and production but you can use a separate cluster for production if you need to.

### Library

1. Add your Sitecore license.xml as a secure file, name it `license.xml`.
1. Add a new variables group named `general` with the following variables (type secret):

| Name | Value |
| ---- | ----- |
| `SQL_SA_PASSWORD` | Strong password for the SQL `sa` account. |
| `SITECORE_ADMIN_PASSWORD` | Strong password for the Sitecore `admin` account |
| `UNICORN_SHARED_SECRET` | Some strong key |
| `TELERIK_ENCRYPTION_KEY` | Another strong key |

### Let's Encrypt

Update email address in `.\manifests\letsencrypt-issuer.yaml`.