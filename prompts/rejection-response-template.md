# Rejection Response Templates

## Overview

Context-aware rejection response templates. The appropriate template is selected based on the stage of rejection: phone screen, technical interview, or final round. All responses MUST be approved by the user before sending.

---

## Template 1: After Phone Screen Rejection

**Subject:** Re: `{{job_title}}` at `{{company_name}}`

**Body:**
Hi [Recruiter/Hiring Manager Name],

Thank you for letting me know, and for taking the time to speak with me about the `{{job_title}}` role.

While I'm disappointed, I appreciate the transparency. Would you be willing to share any feedback on what I could improve for future opportunities?

I remain interested in `{{company_name}}` and would welcome the chance to be considered for future openings that might be a better fit.

Best,
Odeliya Charitonova
odeliya.charitonova.dev@gmail.com

---

## Template 2: After Technical Interview Rejection

**Subject:** Re: `{{job_title}}` application update

**Body:**
Hi [Interviewer/Recruiter Name],

Thank you for the update and for the time invested in the technical interview process. I genuinely enjoyed the technical discussion with your team about [specific topic if known].

I'd appreciate any feedback on the technical assessment — it would help me grow professionally. Understanding specific areas where I fell short would be invaluable.

I have great respect for `{{company_name}}`'s engineering culture and would love to stay in touch for future opportunities.

Best,
Odeliya Charitonova

---

## Template 3: After Final Round Rejection

**Subject:** Re: `{{job_title}}` — thank you

**Body:**
Hi [Hiring Manager Name],

Thank you for the update, and for the investment your team made throughout the interview process. Meeting [specific team members if known] and learning about [specific project/challenge discussed] was genuinely valuable.

I understand these decisions are difficult when multiple strong candidates are involved. If you'd be willing to share feedback on what differentiated the final candidates, I would be grateful.

I have deep respect for what `{{company_name}}` is building. I hope our paths cross again.

Best,
Odeliya Charitonova

---

## Context Variables

| Variable | Description |
|---|---|
| `{{company_name}}` | Company that rejected the application |
| `{{job_title}}` | Role applied for |
| `{{rejection_stage}}` | `phone_screen` / `technical` / `final_round` |
| `{{interviewer_name}}` | Name of the contact (if known) |
| `{{interview_topics}}` | Topics discussed (from communication log) |

---

## AI Generation Instructions

When generating a rejection response, the AI should:

1. **Detect the stage** from `rejection_stage` field
2. **Select appropriate template** based on stage
3. **Personalize** with:
   - Specific interviewer name if available
   - Specific topics from communication log
   - Any company-specific details from company research
4. **Tone adjustment:**
   - Phone screen: Brief and professional (they invested less)
   - Technical: Show appreciation for technical depth
   - Final round: Warmer, more personal (they invested most)
5. **Always request feedback** — this is valuable for improvement
6. **Keep bridge open** — you may reapply in 6-12 months

---

## Usage Notes

- **ZERO rejection responses are sent without manual user approval**
- Context-aware selection happens automatically based on `rejection_stage`
- User reviews the generated response in N8N before sending
- Communication log is updated automatically after sending
