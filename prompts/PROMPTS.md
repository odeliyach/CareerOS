# Ollama Prompts — Job Search Automation System

> All prompts below are used by the N8N workflow (`workflow-all-tiers.json`).  
> They are sent to the Ollama API at `http://ollama:11434/api/generate` using model **llama3**.  
> Placeholders in `{CURLY_BRACES}` are replaced at runtime with actual values from the webhook input.

---

## Tier 1: Core Application

### Resume Generation
```
Generate a tailored resume for this job: {JOB_DESCRIPTION}.
Match skills exactly. Use metrics and STAR method.
Format as professional resume.
```

### Cover Letter
```
Write a compelling cover letter for {COMPANY} position {JOB_TITLE}.
Be personal, specific, and show genuine interest.
Keep it to 3-4 paragraphs.
```

**Output files:** `metadata.md`, `resume.md`, `cover_letter.md`

---

## Tier 2: Cold Outreach

### Introduction Email (Email 1)
```
Create a professional introduction email to {COMPANY} for {JOB_TITLE} position.
Make it compelling but under 150 words.
Be specific and personalized.
```

### Follow-up Email (Email 2)
```
Create a follow-up email for {COMPANY} showing genuine interest.
Reference previous contact.
Keep under 100 words.
```

### Company Research
```
Research {COMPANY}. Provide: industry, recent news/achievements,
key decision-makers if known, company culture indicators, growth metrics.
Format as bullet points.
```

### Personal Connection Angle
```
Identify personal connection angles for contacting {COMPANY}.
Look for: alumni connections, shared interests, industry events, mutual connections.
Suggest outreach strategy.
```

**Output files:** `cold_email.md`, `company_research.md`, `personal_angle.md`

---

## Tier 3: Interview Preparation

### Skills Gap Analysis
```
Analyze skills gap.
Required skills: {JOB_REQUIREMENTS}.
User skills: {USER_SKILLS}.
Create detailed gap analysis with learning priorities and timeline.
```

### Interview Questions
```
Generate 10 technical and behavioral interview questions for {JOB_DESCRIPTION}.
Include depth questions and star method prompts.
```

### Talking Points
```
Create talking points for interviewing at {COMPANY} for {JOB_TITLE}.
Include: your relevant projects, key achievements, industry insights, company-specific angles.
```

### Salary Negotiation Guide
```
Research salary standards for {JOB_TITLE} in {LOCATION}.
Provide: median salary, typical range, negotiation tactics,
benefits evaluation, total compensation breakdown.
```

**Output file:** `interview_prep.md`

---

## Tier 4: Portfolio Matching

### Project Selection
```
From user's GitHub projects, select top 5 most relevant to {JOB_DESCRIPTION}.
Explain why each is relevant.
```

### Quantifiable Metrics
```
For each project, create quantifiable metrics:
efficiency improvements %, user growth, cost savings, performance gains, etc.
Use specific numbers.
```

### Project Context
```
For each project: original objectives, challenges faced,
user's specific role, impact achieved, technologies used.
```

### GitHub Showcase Strategy
```
Provide strategies to improve GitHub visibility for these projects:
README improvements, demo links, contribution stats highlighting.
```

**Output file:** `portfolio_matching.md`

---

## Tier 5: Tracking & Analytics

> Tier 5 does not use AI prompts. It performs:
> - SQLite database writes (follow-up scheduling, analytics update)
> - Obsidian vault file writes (`tracking.md`, `analytics.md`)
> - Git commit to `odeliyach/job-search-data` (private repo)
> - Gmail confirmation email to `odeliya.charitonova.dev@gmail.com`

**Output files:** `tracking.md`, `analytics.md` (vault root)

