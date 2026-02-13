---
name: db-connect
description: Connect to Vayyar production or development PostgreSQL via Google Cloud SQL Proxy. Use when the user needs to query the DB, debug prod data, or run SQL in US/EU regions.
---

# Connect to PostgreSQL with IAM Authentication

## Choose the target

Ask for region (US/EU). **Always use read replicas** unless the user explicitly requests a primary instance.

| Instance | Database | Use Case |
|----------|----------|----------|
| walabot-home:us-central1:replica-300f61ef | vayyar | US Production |
| walabot-home:europe-west1:replica-d73e3ed7 | vayyar_eu | EU Production |
| vayyar-care-preprod:us-central1:replica-5a6d361f | vayyar | US Preprod |
| vayyar-care-preprod:europe-west1:replica-7a1bee7b | vayyar_eu | EU Preprod |
| walabothome-app-cloud:us-central1:rdbms-postgresql | vayyar | Development |

Primary instances (only when explicitly requested):

| Instance | Database | Use Case |
|----------|----------|----------|
| walabot-home:us-central1:rdbms-postgresql | vayyar | US Production (primary) |
| walabot-home:europe-west1:rdbms-postgresql-eu | vayyar_eu | EU Production (primary) |
| vayyar-care-preprod:us-central1:rdbms-postgresql | vayyar | US Preprod (primary) |
| vayyar-care-preprod:europe-west1:rdbms-postgresql-eu | vayyar_eu | EU Preprod (primary) |

## Start the proxy

```bash
~/cloud-sql-proxy <INSTANCE> --auto-iam-authn &
```

If port 5432 is taken, add `--port 5433`.

## Run queries

```bash
psql -h 127.0.0.1 -p 5432 -U "$(gcloud config get-value account)" -d <DATABASE> -c "SELECT ..."
```

## Stop the proxy

```bash
pkill -f cloud-sql-proxy
```

## Troubleshooting

- `connection refused`: proxy not running or wrong port
- `address already in use`: choose another port (`--port 5433`)
- `Not authorized` or `IAM principal ... not found`: run `gcloud auth login` and retry
