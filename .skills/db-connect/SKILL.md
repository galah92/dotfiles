---
name: db-connect
description: Connect to Vayyar production or development PostgreSQL via Google Cloud SQL Proxy. Use when the user needs to query the DB, debug prod data, or run SQL in US/EU regions.
---

# Connect to PostgreSQL via Cloud SQL Proxy

## Prerequisites

Confirm you are in `~` and these exist:

```bash
ls ./cloud-sql-proxy ./service-accounts
```

Confirm `psql` is available:

```bash
psql --version
```

## Choose the target

Ask for region and access type:

- Region: US or EU
- Access: read replica (preferred) or primary (write)

## Available instances

| Alias | Instance | Use Case | Credentials |
|-------|----------|----------|-------------|
| `sqlp_prod_us` | walabot-home:us-central1:rdbms-postgresql | US Production (primary) | `./service-accounts/walabot-home-62c43d769083.json` |
| `sqlp_prod_us_replica` | walabot-home:us-central1:replica-300f61ef | US Production (read replica) | `./service-accounts/walabot-home-62c43d769083.json` |
| `sqlp_prod_eu` | walabot-home:europe-west1:rdbms-postgresql-eu | EU Production (primary) | `./service-accounts/walabot-home-62c43d769083.json` |
| `sqlp_prod_eu_replica` | walabot-home:europe-west1:replica-d73e3ed7 | EU Production (read replica) | `./service-accounts/walabot-home-62c43d769083.json` |
| `sqlp_dev` | walabothome-app-cloud:us-central1:rdbms-postgresql | Development | `./service-accounts/walabothome-app-cloud-6cb6a16b1aa8.json` |

## Start the proxy

Run in background and wait for: `The proxy has started successfully and is ready for new connections!`

```bash
# Example: US read replica on default port 5432
./cloud-sql-proxy walabot-home:us-central1:replica-300f61ef \
  --credentials-file ./service-accounts/walabot-home-62c43d769083.json &
```

If another proxy is running, pick another port:

```bash
./cloud-sql-proxy walabot-home:us-central1:replica-300f61ef \
  --credentials-file ./service-accounts/walabot-home-62c43d769083.json \
  --port 5433 &
```

## Connect with psql

Prefer env var for the password and avoid sharing it in logs.

```bash
PGPASSWORD=Vayyar1234 psql -h 127.0.0.1 -p 5432 -U debug -d vayyar -c '\conninfo'
```

## Run queries

```bash
PGPASSWORD=Vayyar1234 psql -h 127.0.0.1 -p 5432 -U debug -d vayyar -c "SELECT ..."
```

## Stop the proxy

```bash
pkill -f cloud-sql-proxy
```

## Troubleshooting

- `connection refused`: proxy not running or wrong port
- `address already in use`: choose another port (`--port 5433`)
- `permission denied` or `invalid_grant`: credentials file mismatch or expired
