# Engineering Skills

18 senior engineering role skills for AI coding assistants (Kiro, Claude Code, Cursor).

## Quick Install

### Windows
```cmd
INSTALL-engineering.bat
```

### Mac / Linux
```bash
chmod +x INSTALL-engineering.sh
./INSTALL-engineering.sh
```

## Skills Included

### Core Engineering
| Skill | Activates When |
|-------|---------------|
| `senior-architect` | System design, ADRs, tech decisions, dependency analysis |
| `senior-frontend` | React/Next.js, components, bundle optimization, accessibility |
| `senior-backend` | REST APIs, database optimization, auth, microservices |
| `senior-fullstack` | Project scaffolding, stack selection, code audits |
| `senior-qa` | Test generation, coverage analysis, Playwright E2E |
| `senior-devops` | CI/CD pipelines, Terraform, Kubernetes, deployments |
| `senior-secops` | Security audits, CVE remediation, compliance (SOC2/HIPAA/GDPR) |
| `senior-security` | Threat modeling, STRIDE, secure architecture design |
| `code-reviewer` | PR analysis, code quality, SOLID violations, review reports |

### Cloud & Enterprise
| Skill | Activates When |
|-------|---------------|
| `aws-solution-architect` | AWS architecture, CloudFormation, CDK, cost optimization |
| `ms365-tenant-manager` | M365 admin, Conditional Access, Azure AD, PowerShell automation |

### Development Tools
| Skill | Activates When |
|-------|---------------|
| `tdd-guide` | TDD workflows, test generation (Jest/Pytest/JUnit/Vitest), coverage |
| `tech-stack-evaluator` | Framework comparisons, TCO analysis, migration assessment |

### AI / ML / Data
| Skill | Activates When |
|-------|---------------|
| `senior-data-scientist` | A/B testing, ML modeling, causal inference, experiment design |
| `senior-data-engineer` | ETL pipelines, Airflow, dbt, Kafka, data architecture |
| `senior-ml-engineer` | MLOps, model deployment, LLM integration, drift monitoring |
| `senior-prompt-engineer` | Prompt optimization, RAG systems, agent design, LLM evaluation |
| `senior-computer-vision` | YOLO, object detection, segmentation, TensorRT deployment |

## How to Use

Skills use `inclusion: manual` — they don't load automatically (to keep context lean).

Activate in chat using `#`:
```
#senior-backend help me design this REST API
#senior-devops set up a CI/CD pipeline for this project
#tdd-guide write tests for this function
```

## Tech Stack Coverage

ReactJS, NextJS, NodeJS, Express, React Native, Swift, Kotlin, Flutter, PostgreSQL, GraphQL, Go, Python, AWS, Azure, M365

## Installation Options

The installer supports:
- Kiro (user-level or project-level)
- Claude Code (user-level or project-level)
- Cursor (user-level)
- Custom path
- All assistants at once

## Manual Installation

```bash
# Copy all skills to Kiro global steering
cp engineering-skills/steering/*.md ~/.kiro/steering/

# Or for a specific project
cp engineering-skills/steering/*.md /path/to/project/.kiro/steering/
```
