# Flyway Database Migration Project

Database migration management using Flyway for Oracle Database.

## Database Configuration

| Property | Value |
|----------|-------|
| Host | oracle-config.bsi.regla.cloud |
| Port | 1521 |
| DB Version | Oracle DB Enterprise 21.3.0.0 |
| SID | REGLA_DEV_BSI_CONFIG |

## Project Structure

```
flyway/
├── flyway.conf           # Flyway configuration file
├── sql/                  # SQL migration scripts
│   ├── V1__init_schema.sql
│   └── ... (add more migrations)
└── README.md

.gitlab-ci.yml            # GitLab CI/CD pipeline
```

## Migration Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Versioned | `V{version}__{description}.sql` | `V1__create_users_table.sql` |
| Repeatable | `R__{description}.sql` | `R__refresh_views.sql` |
| Undo | `U{version}__{description}.sql` | `U1__drop_users_table.sql` |

## GitLab CI/CD Variables Setup

Set these variables in **GitLab > Settings > CI/CD > Variables**:

### Development Environment
| Variable | Description | Masked |
|----------|-------------|--------|
| `FLYWAY_DB_HOST` | Database host | No |
| `FLYWAY_DB_PORT` | Database port (1521) | No |
| `FLYWAY_DB_SID` | Oracle SID | No |
| `FLYWAY_DB_USER` | Database username | No |
| `FLYWAY_DB_PASSWORD` | Database password | ✅ Yes |

### Staging Environment
| Variable | Description | Masked |
|----------|-------------|--------|
| `FLYWAY_DB_HOST_STAGING` | Staging DB host | No |
| `FLYWAY_DB_PORT_STAGING` | Staging DB port | No |
| `FLYWAY_DB_SID_STAGING` | Staging Oracle SID | No |
| `FLYWAY_DB_USER_STAGING` | Staging DB username | No |
| `FLYWAY_DB_PASSWORD_STAGING` | Staging DB password | ✅ Yes |

### Production Environment
| Variable | Description | Masked |
|----------|-------------|--------|
| `FLYWAY_DB_HOST_PROD` | Production DB host | No |
| `FLYWAY_DB_PORT_PROD` | Production DB port | No |
| `FLYWAY_DB_SID_PROD` | Production Oracle SID | No |
| `FLYWAY_DB_USER_PROD` | Production DB username | No |
| `FLYWAY_DB_PASSWORD_PROD` | Production DB password | ✅ Yes |

## Local Development

### Prerequisites
- Docker installed
- Access to Oracle Database

### Run Flyway Locally with Docker

```bash
# Validate migrations
docker run --rm \
  -v $(pwd)/flyway/sql:/flyway/sql \
  flyway/flyway:10.0.0 \
  -url="jdbc:oracle:thin:@oracle-config.bsi.regla.cloud:1521:REGLA_DEV_BSI_CONFIG" \
  -user="system" \
  -password="YOUR_PASSWORD" \
  validate

# Show migration info
docker run --rm \
  -v $(pwd)/flyway/sql:/flyway/sql \
  flyway/flyway:10.0.0 \
  -url="jdbc:oracle:thin:@oracle-config.bsi.regla.cloud:1521:REGLA_DEV_BSI_CONFIG" \
  -user="system" \
  -password="YOUR_PASSWORD" \
  info

# Run migrations
docker run --rm \
  -v $(pwd)/flyway/sql:/flyway/sql \
  flyway/flyway:10.0.0 \
  -url="jdbc:oracle:thin:@oracle-config.bsi.regla.cloud:1521:REGLA_DEV_BSI_CONFIG" \
  -user="system" \
  -password="YOUR_PASSWORD" \
  -baselineOnMigrate=true \
  migrate
```

### Using Environment Variables (Recommended)

```bash
# Set environment variables
export FLYWAY_DB_HOST=oracle-config.bsi.regla.cloud
export FLYWAY_DB_PORT=1521
export FLYWAY_DB_SID=REGLA_DEV_BSI_CONFIG
export FLYWAY_DB_USER=system
export FLYWAY_DB_PASSWORD=YOUR_PASSWORD

# Run with env vars
docker run --rm \
  -v $(pwd)/flyway/sql:/flyway/sql \
  -e FLYWAY_URL="jdbc:oracle:thin:@${FLYWAY_DB_HOST}:${FLYWAY_DB_PORT}:${FLYWAY_DB_SID}" \
  -e FLYWAY_USER="${FLYWAY_DB_USER}" \
  -e FLYWAY_PASSWORD="${FLYWAY_DB_PASSWORD}" \
  flyway/flyway:10.0.0 \
  info
```

## Pipeline Stages

| Stage | Job | Trigger | Description |
|-------|-----|---------|-------------|
| validate | `flyway-validate` | Auto on MR/develop/main | Validates pending migrations |
| info | `flyway-info` | Auto on MR/develop/main | Shows migration status |
| migrate | `flyway-migrate-dev` | Manual on develop | Runs migration on dev |
| migrate | `flyway-migrate-staging` | Manual on main/master | Runs migration on staging |
| migrate | `flyway-migrate-prod` | Manual on tag (v*.*.*) | Runs migration on production |
| migrate | `flyway-repair` | Manual | Repairs failed migrations |

## Common Flyway Commands

| Command | Description |
|---------|-------------|
| `migrate` | Migrates the database to the latest version |
| `info` | Prints the details and status of all migrations |
| `validate` | Validates applied migrations against local ones |
| `baseline` | Baselines an existing database |
| `repair` | Repairs the schema history table |
| `clean` | Drops all objects (**DANGEROUS**) |

## Best Practices

1. **Never modify applied migrations** - Create new ones instead
2. **Test migrations locally first** - Before pushing to CI/CD
3. **Use meaningful descriptions** - In migration file names
4. **Keep migrations small** - One logical change per migration
5. **Always include rollback plan** - Document how to revert changes
6. **Never commit credentials** - Use CI/CD variables

## Troubleshooting

### Migration Failed
```bash
# Check migration history
flyway info

# Repair schema history (removes failed entries)
flyway repair

# Re-run migration
flyway migrate
```

### Checksum Mismatch
A migration file was modified after being applied. Options:
1. Restore original file content
2. Run `flyway repair` to update checksum (not recommended for production)

## Support

For issues or questions, contact the DevOps team.
