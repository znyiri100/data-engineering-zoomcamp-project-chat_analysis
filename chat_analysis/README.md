# Overview - End-to-End Chat Analysis Platform

This project guides you through building a **complete Chat Analysis data pipeline** using Bruin - a unified CLI tool for data ingestion, transformation, orchestration, and governance.

Checkout our [Zoomcamp Project Prize](https://getbruin.com/zoomcamp-project) to learn more about how you can win a free Claude subscription service.

Please reach out to us via our [Slack Community](https://join.slack.com/t/bruindatacommunity/shared_invite/zt-3oaskee9f-YbvwEEdMgQ1elmKzqmIHTg) to ask questions, share feedback, or report issues.

Register for [Bruin Cloud](https://cloud.getbruin.com/register) to deploy your pipelines: registration is free (no credit card required) and includes complimentary credits to get started.

### YouTube Video Tutorial Playlist
- [Video Tutorials Playlist](https://www.youtube.com/playlist?list=PLnRr-L-cuxO4lUUdkXV5YPHT5ZEcEeXQD)
- [Bruin Core Concepts Playlist](https://www.youtube.com/playlist?list=PLnRr-L-cuxO72ws5jYS8oyKMWs-AosgdP)

## Learning Goals

You'll learn to build a production-ready ELT pipeline that:
- **Ingests** chat logs from CSV files using Python
- **Transforms** and cleans raw data with SQL, applying incremental strategies and enrichment
- **Reports** aggregated user activity and message frequency with built-in quality checks
- **Deploys** to local storage (DuckDB) or cloud infrastructure (BigQuery)

This is a learn-by-doing experience with AI assistance available through Bruin MCP. Follow the comprehensive step-by-step tutorial section below.

## Pipeline Skeleton

The suggested structure separates ingestion, staging, and reporting.

The required parts of a Bruin project are:
- `.bruin.yml` in the root directory
- `pipeline.yml` in the `pipeline/` directory
- `assets/` folder next to `pipeline.yml` containing your Python, SQL, and YAML asset files

```text
chat_analysis/
├── .bruin.yml                              # Environments + connections (local DuckDB, BigQuery, etc.)
├── README.md                               # Learning goals, workflow, best practices
└── pipeline/
    ├── pipeline.yml                        # Pipeline name, schedule, variables
    └── assets/
        ├── ingestion/
        │   ├── chats.py                    # Python ingestion from CSV files
        │   ├── requirements.txt            # Python dependencies for ingestion
        │   ├── topic_lookup.asset.yml      # Seed asset definition
        │   └── topic_lookup.csv            # Seed data (topic names)
        ├── staging/
        │   └── chats.sql                   # Clean, filter, and enrich chats
        └── reports/
            └── chats_report.sql            # Aggregation for analytics
```

# Step-by-Step Tutorial

This module introduces Bruin as a unified data platform that combines **data ingestion**, **transformation**, and **quality** into a single CLI tool. You will build an end-to-end Chat Analysis data pipeline.

> **Prerequisites**: Familiarity with SQL, basic Python, and command-line tools. Prior exposure to orchestration and transformation concepts is helpful but not required.

---

## Part 1: What is a Data Platform?

### 1.1 The Modern Data Stack Components
- **Data extraction/ingestion**: Moving data from sources (CSV files) to your warehouse (DuckDB)
- **Data transformation**: Cleaning and modeling (SQL)
- **Data orchestration**: Scheduling and managing dependencies
- **Data quality/governance**: Ensuring accuracy through checks

### 1.2 Where Bruin Fits In
- Bruin = ingestion + transformation + quality + orchestration in one tool.
- Handles pipeline orchestration (dependency resolution, scheduling, retries).
- Runs locally, on VMs, or in CI/CD with no vendor lock-in.

---

## Part 2: Setting Up Your First Bruin Project

### 2.1 Installation

**Step 1: Install Bruin CLI**
```bash
curl -LsSf https://getbruin.com/install/cli | sh
```

**Step 2: Install IDE Extension (VS Code, Cursor)**
- Search "Bruin" in extensions and install.

---

## Part 3: End-to-End Chat Analysis ELT Pipeline

### Learning Goals
- Build a complete pipeline: ingestion → staging → reports
- Apply `time_interval` materialization strategy for efficient incremental processing
- Use parameters and variables (e.g., `chat_types`)

### 3.1 Data Source and Structure
The chat data is provided in CSV format, organized by month (e.g. `2024-01.csv`, `2024-02.csv`) in a `data/` directory at the project root.

- **Ingestion**: `chats.py` reads these CSVs based on the run date range (`BRUIN_START_DATE` to `BRUIN_END_DATE`).
- **Enrichment**: `topic_lookup.csv` provides human-readable names for topic IDs.

### 3.2 Running the Pipeline

To run the pipeline for a specific month (e.g., January 2026):

```bash
bruin run ./pipeline/pipeline.yml \
  --start-date 2026-01-01 \
  --end-date 2026-02-01 \
  --var chat_types='["free", "assessment_test"]'
```

### 3.3 Validating the Pipeline
Static analysis without execution catches errors in SQL/Python/YAML before running:
```bash
bruin validate ./pipeline/pipeline.yml
```

### 3.4 Ingestion Layer
- `pipeline/assets/ingestion/chats.py`: A Python asset fetching chat data from the `data/` directory. It uses `BRUIN_START_DATE` and `BRUIN_END_DATE` to partition the data.
- `pipeline/assets/ingestion/topic_lookup.asset.yml`: A seed asset loading topic names from `topic_lookup.csv`.

### 3.5 Staging Layer
- `pipeline/assets/staging/chats.sql`: Joins raw chats with topic names and applies basic filters. It uses `time_interval` strategy based on `createdAt`.

### 3.6 Reports Layer
- `pipeline/assets/reports/chats_report.sql`: Aggregates staging data into helpful metrics (e.g., message count per user per day).

### 3.7 Querying the Results
Once the pipeline has finished running, you can query your data directly through the CLI:
```bash
bruin query --connection duckdb-default --query "SELECT * FROM reports.chats_report LIMIT 10"
```

---

## Part 4: Data Engineering with AI Agent

Extend your AI assistants like Cursor or Claude with Bruin context using the Bruin MCP.

### 4.1 Example Prompts
- "Create a Python ingestion asset for chat data stored in CSVs"
- "Generate the SQL for aggregating chat messages by user and date"
- "Add a non_negative quality check to my message_count column"

---

## Part 5: Deploy to Cloud

Move from local DuckDB into BigQuery and schedule runs with Bruin Cloud.

Detailed docs:
- BigQuery: [getbruin.com/docs/bruin/platforms/bigquery](https://getbruin.com/docs/bruin/platforms/bigquery)
- Bruin Cloud: [getbruin.com/docs/bruin/getting-started/bruin-cloud](https://getbruin.com/docs/bruin/getting-started/bruin-cloud)

---

## Key Commands Reference

| Command | Purpose |
|---------|---------|
| `bruin validate <path>` | Check syntax and dependencies without running |
| `bruin run <path>` | Execute pipeline or asset |
| `bruin lineage <path>` | View asset dependencies |
| `bruin query` | Execute ad-hoc SQL queries |
| `bruin connections list` | List configured connections |

---

## Best Practices
- **Materialization**: Use `time_interval` for staging/reports to allow incremental re-runs.
- **Quality Checks**: Add `not_null` and `unique` checks to primary keys early.
- **Connections**: Use `.bruin.yml` for connection definitions and `pipeline.yml` for defaults.
- **Project organization**: Keep assets neatly organized in layers (`ingestion`, `staging`, `reports`).
