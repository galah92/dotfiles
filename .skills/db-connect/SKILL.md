---
name: db-connect
description: Connect to production or dev PostgreSQL database using cloud-sql-proxy. Use when user wants to connect to DB, query database, debug prod data, or run SQL.
---

# Database Connection Skill

Connect to Vayyar's PostgreSQL databases via Google Cloud SQL Proxy.

## Prerequisites

Run from home directory (`~`) which contains:
- `./cloud-sql-proxy` binary
- `./service-accounts/` with credential JSON files

## Available Databases

| Alias | Instance | Use Case |
|-------|----------|----------|
| `sqlp_prod_us` | walabot-home:us-central1:rdbms-postgresql | US Production (primary) |
| `sqlp_prod_us_replica` | walabot-home:us-central1:replica-300f61ef | US Production (read replica) |
| `sqlp_prod_eu` | walabot-home:europe-west1:rdbms-postgresql-eu | EU Production (primary) |
| `sqlp_prod_eu_replica` | walabot-home:europe-west1:replica-d73e3ed7 | EU Production (read replica) |
| `sqlp_dev` | walabothome-app-cloud:us-central1:rdbms-postgresql | Development |

## Connection Steps

### 1. Start the proxy

Ask user which database they need, then run the appropriate proxy command in the background:

```bash
# Example for US read replica (for debugging/read-only queries)
./cloud-sql-proxy walabot-home:us-central1:replica-300f61ef \
  --credentials-file ./service-accounts/walabot-home-62c43d769083.json &
```

Wait for: `The proxy has started successfully and is ready for new connections!`

### 2. Connect with psql

Default connection string format:
```
postgres://debug:Vayyar1234@127.0.0.1/vayyar
```

Test connection:
```bash
PGPASSWORD=Vayyar1234 psql -h 127.0.0.1 -U debug -d vayyar -c '\conninfo'
```

### 3. Run queries

Use psql with the password env var:
```bash
PGPASSWORD=Vayyar1234 psql -h 127.0.0.1 -U debug -d vayyar -c "SELECT ..."
```

## Important Notes

- **Read replicas** (`*_replica`) are preferred for debugging to avoid load on primary
- Proxy listens on `127.0.0.1:5432` by default
- Always ask user which region (US/EU) and whether they need read replica or primary
- The proxy runs in background; remember to kill it when done if needed

## Service Account Files

| File | For |
|------|-----|
| `walabot-home-62c43d769083.json` | Production (US & EU) |
| `walabothome-app-cloud-6cb6a16b1aa8.json` | Development |
