# Sample Interview Prep (Tier 3)

## Role Snapshot
- **Company:** NovaGrid Labs  
- **Role:** Full-Stack Developer (React/Node, Observability focus)  
- **Risks to address:** Limited production GraphQL, k8s exposure mostly via compose.

## Company Context
- Recent blog post about latency reduction for data pipelines—expect questions on tracing and metrics.  
- Public roadmap mentions GraphQL gateway in Q3 and accessibility improvements to the console UI.  
- Values: pragmatic reliability, measurable customer impact, collaboration with SRE.

## Core Talking Points
1) **API Reliability Lift:** Added idempotent retries + structured logging, cutting 500s by 32% and shortening incident diagnosis.  
2) **Frontend Performance:** Implemented route-based code splitting + skeleton screens; improved FCP by 18% on the main dashboard.  
3) **Alert Fatigue Reduction:** Tuned thresholds and dedup rules to cut noisy alerts by 41%; partnered with SRE to redesign runbooks.

## Likely Technical Questions (with prep notes)
- Walk through a recent production incident you handled end-to-end.  
- How do you design rate limits and retries in a Node/Express API?  
- What’s your approach to measuring React performance and preventing regressions?  
- Explain how you’d introduce GraphQL alongside existing REST endpoints.  
- How do you keep DB queries efficient as data volume grows? Indexing strategy + EXPLAIN plans.

## Behavioral (STAR-ready)
- Pushed back on risky release with incomplete rollbacks → negotiated a canary + feature flag plan.  
- Disagreement on alert thresholds → ran a 2-week experiment and presented metrics to align the team.  
- Mentored a new hire on CI pipelines → reduced flakiness by 20% via deterministic fixtures.

## Rapid Refreshers
- GraphQL: persisted operations, cost analysis, N+1 mitigation (dataloaders).  
- Kubernetes basics: deployment/ingress concepts, health checks, resource requests/limits.  
- Accessibility: ARIA labels, focus traps, keyboard navigation, color contrast checks.

## Salary + Logistics
- Target range aligned to posting: ₪28,000–₪32,000 monthly gross.  
- Comfortable with on-call; prefer a documented runbook and clear ownership boundaries.
