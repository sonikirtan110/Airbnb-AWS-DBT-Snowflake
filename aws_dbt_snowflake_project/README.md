# Airbnb End-to-End Data Engineering Project

## Overview
This project implements an end-to-end Airbnb data pipeline using modern data engineering tools:
- Snowflake for cloud data warehousing
- dbt (Data Build Tool) for transformation and lineage
- AWS S3 (or equivalent object storage) as raw data landing zone

The current implementation follows a medallion architecture:
- Bronze -> Silver -> Gold

It includes incremental model patterns, reusable macros, Jinja-based SQL generation, and dbt metadata artifacts for observability.

## Architecture

### Architecture Diagram

![Architecture Diagram](../architecture.png)

### Data Flow
Source Data (CSV) -> AWS S3 -> Snowflake (Staging) -> Bronze -> Silver -> Gold

### Technology Stack
- Cloud Data Warehouse: Snowflake
- Transformation Layer: dbt Core (`dbt-core`, `dbt-snowflake`)
- Cloud Storage: AWS S3 (integration pattern documented)
- Python: 3.12+
- Version Control: Git

### Key dbt Features Used
- Incremental models (implemented in bronze and silver)
- Custom macros
- Jinja templating (`for` loop config pattern in `models/gold/obt.sql`)
- Source and ref lineage
- Documentation metadata artifacts (`manifest.json`, `run_results.json`)

### Planned dbt Features
- Snapshots (SCD Type 2)
- Additional model tests and quality gates
- Ephemeral intermediate models for complex logic decomposition

## Data Model

### Bronze Layer
- `bronze_bookings`
- `bronze_hosts`
- `bronze_listings`

### Silver Layer
- `silver_bookings`
- `silver_hosts`
- `silver_listings`

### Gold Layer
- `obt` (One Big Table) as denormalized analytics output

### Planned Gold Additions
- `fact` model for dimensional consumption
- `gold/ephemeral/` helper models

### Planned Snapshots (SCD Type 2)
- `dim_bookings`
- `dim_hosts`
- `dim_listings`

## Project Structure (Current + Planned)

```text
aws_dbt_snowflake_project/
|-- README.md
|-- dbt_project.yml
|-- profiles.yml
|-- models/
|   |-- sources/
|   |   `-- sources.yml
|   |-- bronze/
|   |   |-- bronze_bookings.sql
|   |   |-- bronze_hosts.sql
|   |   `-- bronze_listings.sql
|   |-- silver/
|   |   |-- silver_bookings.sql
|   |   |-- silver_hosts.sql
|   |   `-- silver_listings.sql
|   `-- gold/
|       `-- obt.sql
|-- macros/
|   |-- generate_schema_name .sql
|   |-- mulitply.sql
|   |-- tag.sql
|   `-- trimmer.sql
|-- analyses/
|   |-- explore.sql
|   |-- IF_ELSE.sql
|   `-- LOOP.sql
|-- snapshots/                # planned snapshot configs
|-- tests/                    # planned custom tests
|-- seeds/
`-- target/                   # dbt artifacts
```

## Getting Started

### Prerequisites
- Snowflake account and role with warehouse/database/schema privileges
- AWS account (if loading source files from S3)
- Python 3.12+

### Installation

```bash
git clone <repository-url>
cd AWS_DBT_Snowflake
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -e .
```

Alternative with uv:

```bash
cd AWS_DBT_Snowflake
uv sync
```

### Configure Snowflake Connection

Create `~/.dbt/profiles.yml` (recommended) or use project-level profile for local experiments.

```yaml
aws_dbt_snowflake_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      schema: "{{ env_var('SNOWFLAKE_SCHEMA') }}"
      threads: 4
```

### Set Up Snowflake Objects

Create database and schemas if needed:

```sql
create database if not exists AIRBNB;
create schema if not exists AIRBNB.STAGING;
create schema if not exists AIRBNB.BRONZE;
create schema if not exists AIRBNB.SILVER;
create schema if not exists AIRBNB.GOLD;
```

### Load Source Data

Typical mapping:
- `bookings.csv` -> `AIRBNB.STAGING.BOOKINGS`
- `hosts.csv` -> `AIRBNB.STAGING.HOSTS`
- `listings.csv` -> `AIRBNB.STAGING.LISTINGS`

## Usage

```bash
uv run dbt debug --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project
uv run dbt deps --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project
uv run dbt run --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project
uv run dbt test --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project
uv run dbt docs generate --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project
```

Run by layer:

```bash
uv run dbt run --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project --select bronze.*
uv run dbt run --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project --select silver.*
uv run dbt run --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project --select gold.*
```

Full build:

```bash
uv run dbt build --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project
```

Planned once snapshots are added:

```bash
uv run dbt snapshot --project-dir aws_dbt_snowflake_project --profiles-dir aws_dbt_snowflake_project
```

## Key Features

### 1. Incremental Loading
Bronze and silver models use incremental patterns to reduce reprocessing.

### 2. Custom Macros
- `tag()` for price categorization
- `multiply()` for reusable arithmetic
- `trimmer()` utility pattern

### 3. Dynamic SQL Generation
`models/gold/obt.sql` uses Jinja config loops to generate select/join logic.

### 4. Schema Organization
Configured in `dbt_project.yml`:
- Bronze -> schema `bronze`
- Silver -> schema `silver`
- Gold -> schema `gold`

## Metadata and Observability

dbt artifacts generated in `target/` include:
- `target/manifest.json`
- `target/run_results.json`
- `target/semantic_manifest.json`
- `target/perf_info.json`

Use these for:
- lineage and impact analysis
- execution monitoring and SLA checks
- CI/CD quality gates

## Data Quality Strategy

Current:
- lineage validation through `source()` and `ref()` dependencies

Planned:
- `unique`, `not_null`, and `relationships` tests in `schema.yml`
- business rule tests in `tests/`

## Security and Best Practices

- Never commit real credentials in `profiles.yml`
- Prefer environment variables and role-based access (RBAC)
- Rotate exposed credentials immediately
- Keep SQL style consistent and review model changes via pull requests

## Troubleshooting

### Connection errors
- verify Snowflake account/user/role/warehouse values
- run `dbt debug`

### Compilation errors
- check Jinja syntax and model references
- run `dbt compile`

### Incremental issues
- run `dbt run --full-refresh`
- validate source timestamp columns and incremental predicates

## Future Enhancements

- Add SCD Type 2 snapshots in `snapshots/`
- Add fact and ephemeral gold models
- Build CI/CD with `dbt build` checks
- Integrate BI layer (Power BI/Tableau)
- Add data quality dashboard and alerting

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

## Author
Project: Airbnb Data Engineering Pipeline

Technologies: Snowflake, dbt, AWS, Python

If this project helps you, please drop a star.

