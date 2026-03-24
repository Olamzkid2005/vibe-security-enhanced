---
inclusion: fileMatch
fileMatchPattern: ["**/dags/**", "**/pipelines/**", "**/etl/**", "**/*.sql", "**/models/**", "**/airflow/**", "**/spark/**"]
---

# Senior Data Engineer

Production-grade data engineering for scalable, reliable data systems.

## Core Principles

- Prefer idempotent pipelines — re-running a pipeline must produce the same result
- Validate data at ingestion boundaries before any transformation
- Fail fast and loudly — surface data quality issues early, never silently skip bad records
- Prefer ELT over ETL when the warehouse has sufficient compute (load raw, transform in-place)
- Parameterize all pipelines by execution date; never hardcode date ranges

---

## Architecture Decisions

### Batch vs. Streaming

Choose **batch** when:
- Latency of hours-to-days is acceptable
- Processing involves complex multi-step transformations or ML
- Cost efficiency is a priority

Choose **streaming** when:
- Real-time or near-real-time latency is required (seconds to minutes)
- Data arrives as a continuous event stream

**Streaming stack guidance:**
- Exactly-once semantics required → Kafka + Flink or Spark Structured Streaming
- At-least-once acceptable → Kafka + consumer groups with manual commit

### Storage Format

- Use **Parquet** or **ORC** for columnar analytical workloads
- Use **Delta Lake** or **Apache Iceberg** when ACID transactions or time travel are needed
- Avoid row-based formats (CSV, JSON) in hot paths; use them only at ingestion boundaries

---

## Orchestration (Airflow)

- Use the **TaskFlow API** (`@dag`, `@task`) for new DAGs — avoid legacy `PythonOperator` patterns
- Set `catchup=False` unless backfill is explicitly required
- Pass data between tasks via **XCom only for small payloads** (IDs, paths); write large data to intermediate storage
- Always use `postgres_conn_id` / connection IDs — never hardcode credentials
- DAG-level defaults: set `retries`, `retry_delay`, and `email_on_failure`

```python
default_args = {
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": True,
}
```

---

## Data Transformation (dbt)

- Follow the **staging → intermediate → marts** layer convention
  - `stg_*`: raw source cleaning only, one model per source table
  - `int_*`: business logic joins and aggregations
  - `fct_*` / `dim_*`: final mart models consumed by BI tools
- Use `incremental` materialization for large fact tables; always define `unique_key`
- Add `not_null` and `unique` tests to every primary key column
- Use `{{ ref() }}` and `{{ source() }}` — never hardcode schema or table names
- Document every model and column in `schema.yml`

---

## Streaming (Kafka)

- Always use **manual offset commit** after successful processing — never rely on auto-commit
- Use a dedicated consumer group per logical consumer
- Handle `msg.error()` explicitly; do not silently skip error messages
- For exactly-once delivery, use Kafka transactions or an idempotent sink

---

## Data Quality

- Validate at every ingestion boundary before loading to the warehouse
- Required checks on any dataset:
  - Primary key is non-null and unique
  - Numeric columns are within expected ranges
  - Timestamps match expected format
  - Row count is within expected bounds (detect empty loads)
- Use **Great Expectations** or **dbt tests** for automated validation
- On validation failure: raise an exception and halt the pipeline — do not proceed with bad data

---

## SQL Conventions

- Use CTEs over nested subqueries for readability
- Qualify all column references with table alias in multi-table queries
- Avoid `SELECT *` in production models — list columns explicitly
- Use window functions instead of self-joins for running totals and rankings
- Partition large tables by date; cluster/sort by high-cardinality filter columns

---

## Python Conventions

- Use **type hints** on all function signatures
- Use `pandas` for datasets that fit in memory; use **PySpark** for distributed processing
- Write unit tests for transformation logic using small in-memory DataFrames — do not test against live databases
- Use `logging` (not `print`) for pipeline observability
- Store secrets in environment variables or a secrets manager — never in code or config files

---

## Tech Stack Reference

| Category | Preferred Tools |
|----------|----------------|
| Orchestration | Airflow (primary), Prefect, Dagster |
| Transformation | dbt, Spark, Flink |
| Streaming | Kafka, Kinesis, Pub/Sub |
| Storage | S3, GCS, Delta Lake, Iceberg |
| Warehouses | Snowflake, BigQuery, Redshift, Databricks |
| Data Quality | Great Expectations, dbt tests, Monte Carlo |
| Formats | Parquet, ORC (analytical); Avro (streaming schemas) |
