---
inclusion: fileMatch
fileMatchPattern: ["**/package.json", "**/requirements.txt", "**/go.mod", "**/Cargo.toml", "**/pom.xml", "**/build.gradle"]
---

# Technology Stack Evaluator

Evaluate and compare technologies with data-driven analysis and actionable recommendations. Apply when comparing frameworks, assessing migration paths, calculating total cost of ownership, or analyzing ecosystem viability.

---

## When to Apply

- Comparing two or more technologies for a specific use case
- Estimating migration effort and risk
- Assessing long-term viability of a dependency
- Calculating 5-year TCO for a stack decision

## When NOT to Apply

- Trivial choices between near-identical tools — defer to team preference
- Already-mandated technology decisions
- Emergency production incidents — use monitoring tools instead

---

## Evaluation Dimensions

Always weight criteria against the stated project priorities. Default weights if none provided:

| Dimension | Default Weight |
|-----------|---------------|
| Developer productivity | 30% |
| Ecosystem & community | 25% |
| Performance | 20% |
| Security & compliance | 15% |
| Long-term viability | 10% |

Adjust weights explicitly when the user provides priorities (e.g., "performance is most important").

---

## Analysis Depth

Choose depth based on decision stakes:

**Quick** — for low-stakes or time-constrained decisions:
- Weighted scores and winner
- Top 3 decision factors
- Confidence level

**Standard** — for most feature or architecture decisions:
- Comparison matrix across all dimensions
- TCO overview (3-year)
- Security summary
- Recommendation with rationale

**Full** — for major platform or migration decisions:
- All metrics with supporting data
- 5-year TCO with hidden costs (onboarding, tooling, ops overhead)
- Migration effort estimate (lines of code, team size, timeline)
- Risk register
- Ecosystem health signals (GitHub activity, npm/PyPI downloads, CVE history)

---

## Confidence Levels

| Level | Score | Meaning |
|-------|-------|---------|
| High | 80–100% | Clear winner, strong supporting data |
| Medium | 50–79% | Trade-offs present; context-dependent |
| Low | < 50% | Close call or insufficient data — flag uncertainty |

Always state confidence level and the primary reason for it.

---

## Reference Comparison Tables

Use these as starting baselines. Adjust based on current data when available.

### Frontend Frameworks

| Criteria | React | Vue | Angular | Svelte |
|----------|-------|-----|---------|--------|
| Ecosystem | ★★★★★ | ★★★★ | ★★★★ | ★★★ |
| Learning curve | Medium | Low | High | Low |
| Performance | High | High | Medium | Very High |
| Enterprise adoption | Very High | Medium | High | Low |
| TypeScript support | First-class | Good | First-class | Good |

### Backend Frameworks (Node.js)

| Criteria | Express | Fastify | NestJS | Hono |
|----------|---------|---------|--------|------|
| Performance | Medium | Very High | Medium | Very High |
| Structure | Minimal | Minimal | Opinionated | Minimal |
| TypeScript | Optional | Optional | First-class | First-class |
| Learning curve | Low | Low | High | Low |
| Enterprise fit | Medium | Medium | High | Low |

### Databases

| Criteria | PostgreSQL | MongoDB | MySQL | DynamoDB |
|----------|-----------|---------|-------|----------|
| ACID compliance | Full | Multi-doc | Full | Limited |
| Scalability | Vertical+ | Horizontal | Vertical+ | Horizontal |
| Query flexibility | Very High | High | High | Low |
| Managed options | RDS, Supabase | Atlas | RDS | Native AWS |

---

## Output Rules

- Always lead with the recommendation, not the analysis
- State confidence level and the single biggest factor driving the recommendation
- Flag any assumptions made (team size, traffic, budget)
- If data is outdated or unavailable, say so explicitly — do not fabricate metrics
