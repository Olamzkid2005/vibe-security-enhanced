---
inclusion: fileMatch
fileMatchPattern: ["**/{Dockerfile,docker-compose.*}", "**/.github/workflows/*", "**/*.tf", "**/*.hcl", "**/Makefile"]
---

# Senior DevOps Engineer

Guidelines for CI/CD, infrastructure as code, containerization, deployment strategies, and observability.

---

## Core Principles

- **Immutable artifacts** — build once, promote the same image through environments; never rebuild per environment.
- **Everything as code** — pipelines, infrastructure, and runbooks live in version control.
- **Least privilege** — IAM roles, service accounts, and secrets scoped to the minimum required.
- **Fail fast** — lint and unit tests run first; expensive steps (build, deploy) only run after they pass.
- **Rollback by default** — every deployment must have a tested rollback path before going live.

---

## CI/CD (GitHub Actions)

**Pipeline stage order:** lint → test (with coverage) → build image → push → deploy.

- Pin action versions to a full SHA or a major version tag (e.g. `actions/checkout@v4`), never `@latest`.
- Cache dependency installs (`cache: 'npm'` / `cache: 'pip'`) to keep pipelines fast.
- Gate the deploy job on `github.ref == 'refs/heads/main'` and require the build job to succeed first (`needs: build`).
- Tag images with the commit SHA (`${{ github.sha }}`), not `latest`, so every image is traceable.
- Store all secrets in GitHub Actions Secrets or an external vault; never hardcode credentials in workflow files.

**Deployment step pattern (ECS example):**
```yaml
- name: Deploy to ECS
  run: |
    aws ecs update-service \
      --cluster production \
      --service app-service \
      --force-new-deployment
```

---

## Infrastructure as Code (Terraform)

**Workflow — always follow this order:**
```bash
terraform init
terraform validate
terraform plan -out=tfplan   # review the diff before applying
terraform apply tfplan
```

- Never run `terraform apply` without reviewing `plan` output first.
- Use remote state (S3 + DynamoDB lock, or Terraform Cloud) — never commit `.tfstate` files.
- Organise resources into modules with a single responsibility; avoid monolithic root modules.
- Use `variable` blocks with `description` and `type` constraints; avoid bare strings for sensitive values — use `sensitive = true`.
- Tag all cloud resources with at minimum: `environment`, `service`, `owner`, `managed-by = terraform`.

**ECS task definition pattern:**
```hcl
container_definitions = jsonencode([{
  name      = var.service_name
  image     = var.container_image
  essential = true
  portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]
  logConfiguration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "/ecs/${var.service_name}"
      awslogs-region        = var.aws_region
      awslogs-stream-prefix = "ecs"
    }
  }
}])
```

---

## Containerisation

- Base images: prefer slim/distroless variants; pin to a specific digest or version tag.
- Multi-stage builds: compile/install in a builder stage, copy only the final artifact to the runtime stage.
- Run as a non-root user; set `USER` explicitly in the Dockerfile.
- Scan images for vulnerabilities in CI (Trivy, Snyk, or ECR scanning) before pushing.
- Never bake secrets into images; inject at runtime via environment variables or secrets manager.

---

## Deployment Strategies

### Blue/Green

- Run two identical environments (blue = live, green = staging).
- Deploy to green, run smoke tests, then switch the load balancer/service selector.
- Keep blue running until green is confirmed healthy; tear down blue after a soak period.

**Traffic switch (Kubernetes):**
```bash
kubectl patch service app-svc -p '{"spec":{"selector":{"slot":"green"}}}'
```

### Rollback

```bash
kubectl rollout undo deployment/app -n production
kubectl rollout status deployment/app -n production
curl -sf https://app.example.com/healthz || echo "ROLLBACK FAILED"
```

- Always include a `readinessProbe` on containers so traffic is only routed to healthy pods.
- Document the rollback procedure in a runbook and test it before the first production deployment.

---

## Observability

| Layer | Recommended tooling | Purpose |
|-------|---------------------|---------|
| Metrics | Prometheus + Grafana | System and application metrics |
| Logs | ELK stack or Loki + Grafana | Centralised log aggregation |
| Traces | Jaeger or Tempo | Distributed request tracing |
| Alerts | Alertmanager + PagerDuty | On-call notifications |
| Uptime | Blackbox exporter | Endpoint health checks |

**Minimum alerts to configure:**
- Error rate > 5% over 5 minutes (sustained 2 min)
- p95 latency > 1 s over 5 minutes (sustained 5 min)
- Pod crash-looping (any restart in 15 min window)

Alert expressions should use `for:` to avoid flapping on transient spikes.

---

## Secrets Management

- Use a secrets manager (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager) — never `.env` files in repos.
- Rotate secrets on a schedule; automate rotation where the provider supports it.
- Audit secret access; alert on unexpected access patterns.

---

## Pre-Deployment Checklist

- [ ] CI pipeline passes on every PR (lint, test, build)
- [ ] Docker image scanned for vulnerabilities; no critical CVEs unaddressed
- [ ] Secrets sourced from vault/secrets manager, not hardcoded
- [ ] `terraform plan` reviewed and approved before `apply`
- [ ] Health checks and readiness probes configured
- [ ] Rollback procedure documented and tested
- [ ] Monitoring and alerting in place for the new service/change
- [ ] Runbook exists for common failure scenarios
