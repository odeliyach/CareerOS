# Ollama Prompts - Job Search Automation

All prompts used by the N8N workflow when calling the Ollama API at `http://ollama:11434`.  
Variables shown as `${VARIABLE_NAME}` are substituted at runtime from the parsed job data.

---

## Tier 1 — Core Application

### Resume Generation

**Prompt:**
```
Generate a tailored resume for ${COMPANY_NAME} ${JOB_TITLE} position. Job requirements: ${JOB_REQUIREMENTS}. User skills: ${USER_SKILLS}. Match skills exactly to requirements. Use metrics and STAR method. Format as professional resume with sections: Summary, Experience, Skills, Education. Be specific and quantifiable.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |
| `${JOB_TITLE}` | Parsed from job details |
| `${JOB_REQUIREMENTS}` | Extracted from job description |
| `${USER_SKILLS}` | Set in "Set Job Details" node |

**Output file:** `resume.md`

---

### Cover Letter Generation

**Prompt:**
```
Write a compelling cover letter for ${COMPANY_NAME} ${JOB_TITLE} position. Show genuine interest in the company and role. Be personal, specific, and professional. Keep to 3-4 paragraphs. Explain why you're interested in this specific company and role, not generic application letter.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |
| `${JOB_TITLE}` | Parsed from job details |

**Output file:** `cover_letter.md`

---

## Tier 2 — Cold Outreach

### Introduction Email

**Prompt:**
```
Create a professional introduction email to ${COMPANY_NAME} for ${JOB_TITLE} position. Make it compelling, personalized, and specific. Under 150 words. Include: your value proposition, specific interest in company, call to action. Be authentic, not generic.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |
| `${JOB_TITLE}` | Parsed from job details |

**Output file:** `cold_email.md` (Introduction section)

---

### Follow-Up Email

**Prompt:**
```
Create a follow-up email for ${COMPANY_NAME} ${JOB_TITLE} position. Show genuine interest, reference previous contact/application. Build on introduction. Under 100 words. Be professional but personable.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |
| `${JOB_TITLE}` | Parsed from job details |

**Output file:** `cold_email.md` (Follow-up section)

---

### Company Research

**Prompt:**
```
Research and provide detailed information about ${COMPANY_NAME}. Include: industry/sector, recent news and achievements, company size and growth, key decision-makers if known, company culture indicators, recent funding/partnerships, growth metrics, hiring trends. Format as comprehensive bullet-point analysis.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |

**Output file:** `company_research.md`

---

### Personal Connection Angles

**Prompt:**
```
Identify personal connection angles for contacting ${COMPANY_NAME} for ${JOB_TITLE}. Look for: alumni connections, shared interests or values, industry events, mutual LinkedIn connections, shared projects or open source, content they've published, hiring manager information. Suggest specific outreach strategy for each angle.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |
| `${JOB_TITLE}` | Parsed from job details |

**Output file:** `personal_angle.md`

---

## Tier 3 — Interview Preparation

### Skills Gap Analysis

**Prompt:**
```
Analyze skills gap for ${JOB_TITLE} at ${COMPANY_NAME}. Required skills: ${JOB_REQUIREMENTS}. User current skills: ${USER_SKILLS}. Create detailed gap analysis with: missing skills, skill levels needed, learning priorities, estimated timeline to close gaps, resources for learning. Format as actionable plan.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |
| `${JOB_TITLE}` | Parsed from job details |
| `${JOB_REQUIREMENTS}` | Extracted from job description |
| `${USER_SKILLS}` | Set in "Set Job Details" node |

**Output file:** `interview_prep.md` (Skills Gap section)

---

### Interview Questions

**Prompt:**
```
Generate 10 interview questions for ${JOB_TITLE} at ${COMPANY_NAME}. Include: 5 technical depth questions specific to tech stack ${TECH_STACK}, 3 behavioral questions using STAR method, 2 company-specific culture questions. Provide follow-up prompts for deeper discussion.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |
| `${JOB_TITLE}` | Parsed from job details |
| `${TECH_STACK}` | Set in "Set Job Details" node |

**Output file:** `interview_prep.md` (Interview Questions section)

---

### Talking Points

**Prompt:**
```
Create comprehensive talking points for interviewing at ${COMPANY_NAME} for ${JOB_TITLE}. Include: your most relevant projects with metrics, key technical achievements, industry insights relevant to company, company-specific angles showing research, answers to likely questions, questions to ask interviewer. Format for easy reference during interviews.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |
| `${JOB_TITLE}` | Parsed from job details |

**Output file:** `interview_prep.md` (Talking Points section)

---

### Salary Guide & Negotiation

**Prompt:**
```
Research salary standards for ${JOB_TITLE} in ${LOCATION}. Provide: median salary, typical salary range (25th-75th percentile), negotiation tactics, benefits evaluation framework, total compensation breakdown (salary, bonus, stock, benefits), market trends, comparable companies. Include negotiation strategies and red flags.
```

**Variables:**
| Variable | Source |
|---|---|
| `${JOB_TITLE}` | Parsed from job details |
| `${LOCATION}` | Parsed from job details |

**Output file:** `interview_prep.md` (Salary Guide section)

---

## Tier 4 — Portfolio Matching

### Project Selection

**Prompt:**
```
From user's GitHub (username: odeliyach), identify and select the 5 projects most relevant to ${JOB_DESCRIPTION} for ${JOB_TITLE}. Explain why each project is relevant. Consider: technical skills match, complexity, business impact, recency, documentation quality.
```

**Variables:**
| Variable | Source |
|---|---|
| `${JOB_TITLE}` | Parsed from job details |
| `${JOB_DESCRIPTION}` | Full job description text |

**Output file:** `portfolio_matching.md` (Project Selection section)

---

### Project Metrics

**Prompt:**
```
For the selected projects, create quantifiable metrics showing impact. For each project include: performance improvements (%, ms, throughput), user growth metrics, cost savings, engagement metrics, scalability metrics, code quality metrics. Use specific numbers and percentages.
```

**Variables:** None — follows Project Selection naturally.

**Output file:** `portfolio_matching.md` (Metrics section)

---

### Project Context

**Prompt:**
```
For each selected project provide: original objectives/problem solved, technical challenges faced, your specific role and responsibilities, technologies/tools used, impact achieved, lessons learned. Be detailed and business-focused.
```

**Variables:** None — follows Project Selection naturally.

**Output file:** `portfolio_matching.md` (Project Context section)

---

### GitHub Visibility Strategy

**Prompt:**
```
Provide strategies to improve GitHub visibility for these projects to attract ${COMPANY_NAME} attention. Include: README improvements, demo links/videos, contribution stats highlighting, deployment links, relevant badges, documentation enhancement, community engagement, GitHub profile optimization.
```

**Variables:**
| Variable | Source |
|---|---|
| `${COMPANY_NAME}` | Parsed from job details |

**Output file:** `portfolio_matching.md` (GitHub Strategy section)

---

## Customizing Prompts

To change a prompt, edit the corresponding Code node in the N8N workflow:

1. Open the N8N workflow editor at `https://job-search-n8n.onrender.com`
2. Click on the relevant Tier node (e.g., "Tier 1 - Core Application")
3. Find the prompt variable (e.g., `const resumePrompt = \`...\``)
4. Edit the prompt text
5. Save the workflow

> **Tip:** Keep `${jobData.field_name}` references intact — they pull from your job details automatically.
