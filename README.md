# Intelligent Job Search System - N8N Workflow

## Description
This repository contains an N8N workflow for an intelligent job search system that automates the job application process across various platforms.

## Repository Structure

```
job-search-n8n/
├── Dockerfile                  # Docker image definition for N8N (in root for Render compatibility)
├── 📁 config/
│   ├── docker-compose.yml      # Docker Compose configuration
│   └── render.yaml             # Render.com deployment configuration
├── 📁 docs/
│   ├── SETUP.md                # Setup and installation instructions
│   ├── USAGE_GUIDE.md          # How to use the system
│   ├── CUSTOMIZATION.md        # Customization options
│   ├── TROUBLESHOOTING.md      # Common issues and solutions
│   ├── TIER1_CORE_APPLICATION.md
│   ├── TIER2_COLD_OUTREACH.md
│   ├── TIER3_INTERVIEW_PREP.md
│   ├── TIER4_PORTFOLIO_MATCHING.md
│   ├── TIER5_TRACKING.md
│   └── WORKFLOW_SPECIFICATION.md
├── 📁 prompts/
│   └── PROMPTS.md              # AI prompt templates
├── 📁 n8n-workflows/
│   └── workflow.json           # N8N workflow definition
├── 📁 sample-outputs/          # Example outputs from the system
├── .env.example                # Example environment variables
├── .gitignore
└── README.md
```

## Quick Start

1. **Clone the Repository**
   ```bash
   git clone https://github.com/odeliyach/job-search-n8n.git
   cd job-search-n8n
   ```

2. **Configure Environment Variables**
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

3. **Start with Docker Compose**
   ```bash
   docker-compose -f config/docker-compose.yml up -d
   ```

4. **Access N8N**
   - Open your browser at `http://localhost:5678`
   - Import the workflow from `n8n-workflows/workflow.json`

## Documentation

| Document | Description |
|----------|-------------|
| [Setup Guide](docs/SETUP.md) | Prerequisites and installation instructions |
| [Usage Guide](docs/USAGE_GUIDE.md) | How to use the job search system |
| [Customization](docs/CUSTOMIZATION.md) | How to customize the workflows |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [Workflow Specification](docs/WORKFLOW_SPECIFICATION.md) | Technical workflow details |

## System Tiers

| Tier | Document | Description |
|------|----------|-------------|
| Tier 1 | [Core Application](docs/TIER1_CORE_APPLICATION.md) | Core job application automation |
| Tier 2 | [Cold Outreach](docs/TIER2_COLD_OUTREACH.md) | Automated cold outreach to companies |
| Tier 3 | [Interview Prep](docs/TIER3_INTERVIEW_PREP.md) | Interview preparation assistance |
| Tier 4 | [Portfolio Matching](docs/TIER4_PORTFOLIO_MATCHING.md) | Matching your portfolio to job requirements |
| Tier 5 | [Tracking](docs/TIER5_TRACKING.md) | Application tracking and analytics |

## Deployment

### Render.com
The `config/render.yaml` file contains the Render.com deployment configuration. See [Setup Guide](docs/SETUP.md) for full deployment instructions.

### Docker
The `Dockerfile` in the root directory defines the Docker image (placed in root for Render compatibility). Use `config/docker-compose.yml` for local development with Docker Compose.

## AI Prompts

AI prompt templates used by the system are located in [`prompts/PROMPTS.md`](prompts/PROMPTS.md).

## License
This project is licensed under the MIT License.