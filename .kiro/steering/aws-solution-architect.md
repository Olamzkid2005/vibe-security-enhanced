---
inclusion: fileMatch
fileMatchPattern: "**/{*.tf,*.yaml,*.yml,cdk.json,serverless.yml,cloudformation/**,infra/**,infrastructure/**}"
---

# AWS Solution Architect

Design scalable, cost-effective AWS architectures using infrastructure-as-code. Default to serverless patterns unless workload characteristics justify otherwise.

---

## Architecture Pattern Selection

| Pattern | Services | Use When |
|---------|----------|----------|
| Serverless Web | S3 + CloudFront + API Gateway + Lambda + DynamoDB | Variable/low traffic, cost-sensitive, no persistent connections |
| Event-Driven | EventBridge + Lambda + SQS + Step Functions | Async workflows, decoupled services, fan-out |
| Three-Tier | ALB + ECS Fargate + Aurora + ElastiCache | Long-running processes, WebSockets, complex queries |
| GraphQL Backend | AppSync + Lambda + DynamoDB + Cognito | Mobile/SPA backends with real-time subscriptions |

Choose the simplest pattern that satisfies the requirements. Do not over-engineer.

---

## IaC Conventions

- Prefer **AWS SAM** for Lambda-heavy workloads; prefer **CDK (TypeScript)** for complex multi-service architectures.
- Use **CloudFormation parameters** for environment-specific values (stage, domain, etc.).
- Tag all resources with `Environment`, `Project`, and `Owner`.
- Never hardcode account IDs, region names, or ARNs — use `!Sub`, `!Ref`, or CDK tokens.
- Store secrets in **AWS Secrets Manager**. Never in environment variables, SSM plaintext, or source code.

### SAM Template Skeleton

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Parameters:
  AppName: { Type: String, Default: my-app }
  Stage:   { Type: String, Default: dev }

Globals:
  Function:
    Runtime: nodejs20.x
    Architectures: [arm64]   # Graviton — lower cost, same performance
    Environment:
      Variables:
        STAGE: !Ref Stage

Resources:
  ApiFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: index.handler
      MemorySize: 512
      Timeout: 30
      Environment:
        Variables:
          TABLE_NAME: !Ref DataTable
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref DataTable
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /{proxy+}
            Method: ANY

  DataTable:
    Type: AWS::DynamoDB::Table
    DeletionPolicy: Retain
    Properties:
      BillingMode: PAY_PER_REQUEST
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: true
      AttributeDefinitions:
        - { AttributeName: pk, AttributeType: S }
        - { AttributeName: sk, AttributeType: S }
      KeySchema:
        - { AttributeName: pk, KeyType: HASH }
        - { AttributeName: sk, KeyType: RANGE }
```

### CDK Skeleton (TypeScript)

```typescript
import * as ec2  from 'aws-cdk-lib/aws-ec2';
import * as ecs  from 'aws-cdk-lib/aws-ecs';
import * as rds  from 'aws-cdk-lib/aws-rds';

const vpc     = new ec2.Vpc(this, 'AppVpc', { maxAzs: 2, natGateways: 1 });
const cluster = new ecs.Cluster(this, 'AppCluster', { vpc });

const db = new rds.ServerlessCluster(this, 'AppDb', {
  engine: rds.DatabaseClusterEngine.auroraPostgres({
    version: rds.AuroraPostgresEngineVersion.VER_15_2,
  }),
  vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
  scaling: { minCapacity: 0.5, maxCapacity: 4 },
});
```

---

## Security Baseline

Apply these controls to every stack. No exceptions.

| Control | Rule |
|---------|------|
| IAM | Least privilege; no wildcard actions (`*`) in production policies |
| Secrets | AWS Secrets Manager only — never env vars, SSM plaintext, or source code |
| Encryption | KMS for data at rest; TLS 1.2+ in transit |
| Networking | Compute and databases in private subnets; only ALB/CloudFront in public |
| Logging | CloudTrail enabled; VPC Flow Logs; ALB/CloudFront access logs; set log retention (never infinite) |
| WAF | Attach to CloudFront or ALB for all public-facing endpoints |
| S3 | Block public access by default; enable versioning for critical buckets |

---

## Cost Optimization

| Service | Default Optimization |
|---------|---------------------|
| Lambda | ARM (Graviton2); right-size memory with Lambda Power Tuning |
| DynamoDB | On-demand for unpredictable traffic; provisioned + auto-scaling for steady-state |
| ECS Fargate | Spot capacity for non-critical or batch workloads |
| RDS / Aurora | Serverless v2 for variable workloads; stop dev instances outside business hours |
| S3 | Lifecycle policies to transition/expire objects; Intelligent-Tiering for unknown access patterns |
| CloudFront | Aggressive caching with cache-control headers; compress responses |
| NAT Gateway | Minimize cross-AZ traffic; use VPC endpoints for S3 and DynamoDB |

**Cost review checklist (run before every deploy to production):**
- [ ] No unused resources (idle EC2, unattached EBS, empty load balancers)
- [ ] Reserved Instances or Savings Plans for steady-state compute
- [ ] S3 lifecycle policies configured
- [ ] CloudWatch log retention set on all log groups
- [ ] NAT Gateway usage reviewed; VPC endpoints in place where applicable

---

## Deployment Workflow

```bash
# SAM
sam build
sam deploy --guided   # first deploy (creates samconfig.toml)
sam deploy            # subsequent deploys

# CDK
cdk diff              # always review before applying
cdk deploy

# Verify stack status
aws cloudformation describe-stacks \
  --stack-name <stack-name> \
  --query 'Stacks[0].StackStatus'
```

Always run `cdk diff` or review a SAM changeset before deploying to production. Treat infrastructure changes with the same review discipline as application code.
