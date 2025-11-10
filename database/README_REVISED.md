# Challenge Boards - Database Setup (Revised)

## Overview

This project uses a **hybrid SQL + JSON approach** for maximum flexibility:
- **SQLite** for local development (zero configuration)
- **PostgreSQL** for staging/production (Docker or cloud)
- **JSON columns** for flexible health metrics

---

## Quick Start

### Option 1: SQLite (Recommended for Development)

**Zero configuration required!**

```bash
# Navigate to your project
cd ChallengeBoards

# Run migrations (will create app.db file)
sqlite3 app.db < database/migrations/sqlite/001_initial_up.sql

# Seed data
sqlite3 app.db < database/seed/seed_data_sqlite.sql

# Done! Your database is ready
```

**Browse the database:**
```bash
# Command line
sqlite3 app.db
.tables
.schema Users

# Or use a GUI tool:
# - DB Browser for SQLite (https://sqlitebrowser.org/)
# - TablePlus (https://tableplus.com/)
# - DBeaver (https://dbeaver.io/)
```

**Connection String for .NET:**
```
Data Source=app.db;Cache=Shared
```

---

### Option 2: PostgreSQL (Docker)

**For team development or production testing:**

```bash
# Start PostgreSQL + pgAdmin
docker-compose up -d

# Wait for PostgreSQL to be ready (15 seconds)
sleep 15

# Check status
docker-compose ps

# Connect to database
psql -h localhost -U dev -d challengeboards
# Password: devpass123

# Or use pgAdmin web UI
# Open: http://localhost:5050
# Email: admin@challengeboards.local
# Password: admin123
```

**Connection String for .NET:**
```
Host=localhost;Port=5432;Database=challengeboards;Username=dev;Password=devpass123
```

**Tear down:**
```bash
docker-compose down -v  # Removes containers and volumes
```

---

## Database Strategy

### Why SQLite for Development?

✅ **Zero setup** - No installation required
✅ **Cross-platform** - Mac, Linux, Windows
✅ **Fast** - Perfect for local development
✅ **File-based** - Easy to reset (just delete file)
✅ **Testable** - In-memory mode for unit tests
✅ **Version control** - Can commit test databases

### Why PostgreSQL for Production?

✅ **Excellent JSON support** - JSONB with indexing
✅ **Open source** - No licensing costs
✅ **Scalable** - Production-proven
✅ **Cloud-ready** - Azure, AWS, GCP support
✅ **Feature-rich** - Full-text search, arrays, etc.

### Why JSON for Health Metrics?

✅ **Flexibility** - Add new metrics without migrations
✅ **Future-proof** - Support unknown data sources
✅ **Easy evolution** - Steps → Heart rate → Sleep → etc.

**Example:**
```json
{
  "steps": 8500,
  "activeMinutes": 45,
  "distanceKm": 6.8,
  "heartRate": {"avg": 72, "max": 145},
  "sleep": {"hours": 7.5, "quality": "good"}
}
```

---

## Migration Path

### Phase 1: Local Development (SQLite)

```
┌─────────────────┐
│  Developer PC   │
│                 │
│  ├─ app.db      │  SQLite file
│  └─ .NET API    │
└─────────────────┘
```

**Pros:**
- Instant startup
- No dependencies
- Easy to reset

---

### Phase 2: Team Development (Docker PostgreSQL)

```
┌─────────────────┐        ┌──────────────────┐
│  Developer PC   │───────▶│  Docker          │
│                 │        │  ├─ PostgreSQL   │
│  └─ .NET API    │        │  └─ pgAdmin      │
└─────────────────┘        └──────────────────┘
```

**Usage:**
```bash
docker-compose up -d
export DB_PROVIDER=PostgreSQL
dotnet run
```

**Pros:**
- Multi-user development
- Test production database
- Easy to share state

---

### Phase 3: Production (Cloud PostgreSQL)

```
┌─────────────────┐        ┌──────────────────┐
│  Azure/AWS      │        │  PostgreSQL      │
│                 │───────▶│  (Managed)       │
│  ├─ App Service │        │                  │
│  └─ .NET API    │        └──────────────────┘
└─────────────────┘
```

**Cloud Options:**

| Provider | Service | Cost/Month | Notes |
|----------|---------|------------|-------|
| Azure | Database for PostgreSQL Flexible | $10-50 | Easy integration with Azure services |
| AWS | RDS PostgreSQL | $15-50 | Mature, reliable |
| DigitalOcean | Managed PostgreSQL | $15 | Simple, cheap |
| Heroku | Heroku Postgres | $9-50 | Easy deployment |

---

## Schema Design

### Core Tables (Relational)

```
Users
├── Challenges
│   ├── Teams
│   │   └── TeamMembers
│   └── ChallengeParticipants
├── HealthMetrics (with JSON)
├── DailySummaries (with JSON)
└── Leaderboards (with JSON)
```

### Example: HealthMetrics with JSON

**Table Structure:**
```sql
CREATE TABLE HealthMetrics (
    MetricId INTEGER PRIMARY KEY,
    UserId INTEGER NOT NULL,
    MetricDate DATE NOT NULL,
    Source TEXT,

    -- Flexible JSON field
    MetricsData TEXT NOT NULL,  -- SQLite: TEXT, PostgreSQL: JSONB

    SyncedAt DATETIME NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
```

**Sample Data:**
```sql
INSERT INTO HealthMetrics (UserId, MetricDate, Source, MetricsData)
VALUES (
    1,
    '2025-11-10',
    'HealthKit',
    '{"steps":8500,"activeMinutes":45,"distanceKm":6.8,"heartRate":{"avg":72}}'
);
```

**Querying:**
```sql
-- SQLite
SELECT
    UserId,
    json_extract(MetricsData, '$.steps') AS Steps,
    json_extract(MetricsData, '$.heartRate.avg') AS AvgHeartRate
FROM HealthMetrics
WHERE UserId = 1;

-- PostgreSQL
SELECT
    UserId,
    MetricsData->>'steps' AS Steps,
    MetricsData->'heartRate'->>'avg' AS AvgHeartRate
FROM HealthMetrics
WHERE UserId = 1;
```

---

## Seeded Test Data

### Users (20)
- 1 Admin: `admin@challengeboards.com`
- 3 Captains
- 16 Participants

**Password:** `Test123!` (all accounts)

### Challenges (3)
1. **October Step Challenge** (Completed)
2. **November Fitness Challenge** (Active) ⭐ Has data!
3. **Holiday Step Sprint** (Signup)

### Health Data
- **November challenge**: 10 days of realistic data
- **Patterns**: Weekdays (6K-10K), Weekends (8K-15K)
- **Formats**: JSON with steps, activeMinutes, distanceKm

---

## Development Workflow

### Day-to-Day Development

```bash
# 1. Start with SQLite
sqlite3 app.db < database/migrations/sqlite/001_initial_up.sql
sqlite3 app.db < database/seed/seed_data_sqlite.sql

# 2. Run your API
dotnet run

# 3. Make changes, test

# 4. Reset if needed
rm app.db
sqlite3 app.db < database/migrations/sqlite/001_initial_up.sql
sqlite3 app.db < database/seed/seed_data_sqlite.sql
```

### Testing with PostgreSQL

```bash
# 1. Start Docker
docker-compose up -d

# 2. Configure app for PostgreSQL
export ConnectionStrings__DefaultConnection="Host=localhost;Port=5432;Database=challengeboards;Username=dev;Password=devpass123"
export DatabaseProvider="PostgreSQL"

# 3. Run migrations
psql -h localhost -U dev -d challengeboards < database/migrations/postgresql/001_initial_up.sql
psql -h localhost -U dev -d challengeboards < database/seed/seed_data_postgresql.sql

# 4. Run API
dotnet run
```

---

## JSON Schema Design

### HealthMetrics JSON Structure

```typescript
interface MetricsData {
  // Core metrics (most common)
  steps?: number;
  activeMinutes?: number;
  distanceKm?: number;

  // Optional extended
  floors?: number;
  calories?: number;

  // Nested objects
  heartRate?: {
    avg: number;
    max: number;
    min: number;
    resting: number;
  };

  sleep?: {
    hours: number;
    quality: 'poor' | 'fair' | 'good' | 'excellent';
    deepSleepMinutes?: number;
  };

  // Activity-specific
  running?: {
    distanceKm: number;
    pace: string;
    elevationGain?: number;
  };

  cycling?: {
    distanceKm: number;
    avgSpeed: number;
  };

  // Future expansion - any field allowed
  [key: string]: any;
}
```

### Challenge Configuration JSON

```typescript
interface ChallengeConfig {
  trackedMetrics: string[];  // ["steps", "activeMinutes"]
  primaryMetric: string;     // "steps"
  scoringMethod: "total" | "average";
  teamScoringMethod?: "teamTotal" | "teamAverage" | "topN";
  minTeamSize?: number;
  maxTeamSize?: number;
}
```

**Example:**
```json
{
  "trackedMetrics": ["steps", "activeMinutes", "distanceKm"],
  "primaryMetric": "steps",
  "scoringMethod": "total",
  "teamScoringMethod": "teamAverage",
  "minTeamSize": 3,
  "maxTeamSize": 8
}
```

---

## Common Queries

### Get User's Recent Activity
```sql
SELECT
    MetricDate,
    json_extract(MetricsData, '$.steps') AS Steps,
    json_extract(MetricsData, '$.activeMinutes') AS ActiveMinutes
FROM HealthMetrics
WHERE UserId = 2
    AND MetricDate >= '2025-11-01'
ORDER BY MetricDate DESC;
```

### Get Challenge Configuration
```sql
SELECT
    Name,
    json_extract(Configuration, '$.primaryMetric') AS PrimaryMetric,
    json_extract(Configuration, '$.scoringMethod') AS ScoringMethod
FROM Challenges
WHERE ChallengeId = 2;
```

### Get Team Leaderboard with Scores
```sql
SELECT
    t.TeamName,
    l.Rank,
    json_extract(l.Scores, '$.primary') AS PrimaryScore,
    json_extract(l.Scores, '$.steps') AS TotalSteps
FROM Leaderboards l
JOIN Teams t ON l.EntityId = t.TeamId
WHERE l.ChallengeId = 2
    AND l.LeaderboardType = 'Team'
ORDER BY l.Rank;
```

---

## Migration: SQLite → PostgreSQL

### Automated Approach (Recommended)

Use Entity Framework Core - it handles the migration automatically:

```bash
# 1. Configure for PostgreSQL
export DatabaseProvider="PostgreSQL"
export ConnectionStrings__DefaultConnection="Host=...;Database=..."

# 2. Apply migrations
dotnet ef database update

# EF Core will create the schema in PostgreSQL
```

### Manual Approach

```bash
# 1. Export from SQLite
sqlite3 app.db .dump > backup.sql

# 2. Convert to PostgreSQL syntax (minor changes)
# - AUTOINCREMENT → SERIAL
# - TEXT → VARCHAR or TEXT
# - INTEGER → INT or BIGINT

# 3. Import to PostgreSQL
psql -h localhost -U dev -d challengeboards < backup_converted.sql
```

### Key Differences

| Feature | SQLite | PostgreSQL |
|---------|--------|------------|
| JSON Type | TEXT | JSONB |
| Auto-increment | AUTOINCREMENT | SERIAL |
| Boolean | INTEGER (0/1) | BOOLEAN |
| DateTime | TEXT (ISO 8601) | TIMESTAMP |
| JSON Extract | `json_extract(col, '$.field')` | `col->>'field'` |

---

## Troubleshooting

### SQLite Issues

**"database is locked"**
- SQLite doesn't support concurrent writes
- Use PostgreSQL for multi-user development

**"no such table"**
```bash
# Re-run migrations
sqlite3 app.db < database/migrations/sqlite/001_initial_up.sql
```

### PostgreSQL Issues

**"connection refused"**
```bash
# Check if container is running
docker-compose ps

# View logs
docker-compose logs postgres
```

**"password authentication failed"**
- Check connection string credentials
- Default: `dev` / `devpass123`

### JSON Issues

**"json_extract returns NULL"**
- Check JSON syntax is valid
- Field path is case-sensitive
- Use `.` for nested fields: `'$.heartRate.avg'`

---

## Tools & Resources

### SQLite Tools
- **DB Browser for SQLite**: https://sqlitebrowser.org/
- **TablePlus**: https://tableplus.com/
- **Command line**: `sqlite3 app.db`

### PostgreSQL Tools
- **pgAdmin** (included in Docker): http://localhost:5050
- **Azure Data Studio**: https://aka.ms/azuredatastudio
- **DBeaver**: https://dbeaver.io/
- **psql**: Command-line tool

### JSON Tools
- **JSON Viewer**: https://jsonviewer.stack.hu/
- **jq**: Command-line JSON processor

---

## Performance Considerations

### Indexing JSON Fields

**SQLite:**
```sql
CREATE INDEX idx_metrics_steps ON HealthMetrics(
    json_extract(MetricsData, '$.steps')
) WHERE json_extract(MetricsData, '$.steps') IS NOT NULL;
```

**PostgreSQL:**
```sql
CREATE INDEX idx_metrics_steps ON HealthMetrics
USING gin ((MetricsData->'steps'));
```

### Query Optimization

✅ **DO:**
- Index frequently queried JSON fields
- Use materialized views for complex aggregations
- Cache leaderboard results

❌ **DON'T:**
- Query deeply nested JSON in hot paths
- Recompute leaderboards on every request
- Use JSON for highly relational data

---

## Cost Estimates

### Development
- **SQLite**: $0 (free, embedded)
- **PostgreSQL (Docker)**: $0 (free, local)

### Production (500 users, ~180K records/year)

| Hosting | Cost/Month | Notes |
|---------|------------|-------|
| Self-hosted VPS | $5-10 | Full control, maintenance required |
| DigitalOcean Managed | $15 | Simple, reliable |
| Azure PostgreSQL | $10-30 | Flexible Server, auto-backups |
| AWS RDS | $15-40 | Mature platform |
| Heroku Postgres | $9-50 | Easy deployment |

**Recommended:** Start with DigitalOcean ($15/mo) or Azure Flexible Server ($10-20/mo)

---

## Next Steps

1. ✅ SQLite schema created
2. ✅ Docker Compose configured
3. ⏳ Create .NET solution
4. ⏳ Configure EF Core for both SQLite and PostgreSQL
5. ⏳ Build API with JSON support
6. ⏳ Create frontend

---

**Ready to start coding!** 🚀

See [DATABASE_STRATEGY.md](DATABASE_STRATEGY.md) for the full rationale behind this approach.
