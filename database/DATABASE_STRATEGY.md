# Challenge Boards - Database Strategy (Revised)

## Executive Summary

After reconsidering the requirements, we're adopting a **hybrid SQL approach with JSON flexibility** using **SQLite for local development** and **PostgreSQL for production**.

### Key Decisions

✅ **Use SQL (not pure NoSQL)** - Core domain is highly relational (teams, challenges, memberships)
✅ **Add JSON columns for flexibility** - Health metrics can vary by user/source
✅ **SQLite for local development** - Zero configuration, cross-platform
✅ **PostgreSQL for production** - Open source, excellent JSON support, cloud-ready
✅ **Docker Compose for testing** - Easy PostgreSQL testing before cloud deployment

---

## Why Not Pure NoSQL?

### Challenge Boards Domain Analysis

Our core domain is **highly relational**:

```
Users ──< Teams >── Challenges
  │
  └──< Health Data (this could be flexible)
```

**Relational Requirements:**
- Users belong to teams
- Teams belong to challenges
- Team membership has constraints (one team per user per challenge)
- Leaderboards require aggregations and rankings
- Need transactional consistency for team roster changes

**Where We Need Flexibility:**
- Health metrics (steps, heart rate, sleep, cycling, swimming, etc.)
- Different data sources (HealthKit, Google Fit, Fitbit, Garmin, Strava)
- Future-proofing for unknown metrics

### The Problem with Pure NoSQL

| Challenge | NoSQL Issue | SQL Solution |
|-----------|-------------|--------------|
| Team roster management | Complex application-level joins | Native JOIN support |
| Leaderboard rankings | Inefficient aggregations | Native ORDER BY, RANK() |
| Ensuring one team per user | Application-level validation | UNIQUE constraints |
| Audit trail | Difficult to query history | Relational queries |
| Transactions | Limited cross-document support | ACID transactions |

**Conclusion:** NoSQL would make our core domain harder while only benefiting one area (health metrics).

---

## Hybrid Approach: SQL + JSON

### Best of Both Worlds

Use **SQL for structure** and **JSON for flexibility**:

```sql
CREATE TABLE HealthMetrics (
    MetricId INTEGER PRIMARY KEY,
    UserId INTEGER NOT NULL,
    MetricDate DATE NOT NULL,
    Source TEXT,  -- 'HealthKit', 'GoogleFit', 'Garmin', etc.

    -- Flexible JSON field for varying metrics
    MetricsData JSON NOT NULL,
    -- Example: {"steps": 8500, "activeMinutes": 45, "heartRate": 72, "sleep": 7.5}

    SyncedAt DATETIME NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
```

### Benefits

✅ **Schema flexibility** - Add new metrics without migrations
✅ **Relational integrity** - Foreign keys, constraints still work
✅ **Efficient queries** - SQL for aggregations, JSON for flexibility
✅ **Easy evolution** - New data sources just add fields to JSON

### Example Evolution

**Week 1:** Track steps
```json
{"steps": 8500}
```

**Week 2:** Add active minutes
```json
{"steps": 8500, "activeMinutes": 45}
```

**Month 3:** Add heart rate and sleep
```json
{"steps": 8500, "activeMinutes": 45, "heartRate": 72, "sleepHours": 7.5}
```

**Year 2:** Add cycling and swimming
```json
{
  "steps": 8500,
  "activeMinutes": 45,
  "cycling": {"distanceKm": 15, "durationMin": 40},
  "swimming": {"laps": 20, "durationMin": 30}
}
```

**No schema migrations needed!** ✨

---

## SQLite for Local Development

### Why SQLite?

| Feature | SQL Server LocalDB | SQLite |
|---------|-------------------|--------|
| **Installation** | Requires download | None (embedded) |
| **Cross-platform** | Windows only | Mac, Linux, Windows |
| **Setup time** | 5-10 minutes | 0 seconds |
| **File-based** | No | Yes (easy to reset) |
| **Version control** | Difficult | Can commit test.db |
| **Docker needed** | No | No |
| **Learning curve** | Medium | Low |
| **Production use** | Azure SQL ($$$) | Not suitable |

### SQLite Advantages

✅ **Zero configuration** - Just a file
✅ **Cross-platform** - Works on Mac, Linux, Windows
✅ **Perfect for local dev** - Fast, simple, reliable
✅ **Easy reset** - Delete file and re-run migrations
✅ **Great for testing** - In-memory mode for unit tests
✅ **Works with EF Core** - Full support

### SQLite Limitations (Why Not Production)

❌ **No concurrent writes** - Single writer lock
❌ **Limited scalability** - Not for high traffic
❌ **Some SQL features missing** - No RIGHT JOIN, limited ALTER TABLE
❌ **No user management** - File permissions only

**Conclusion:** Perfect for development, not for production.

---

## PostgreSQL for Production

### Why PostgreSQL?

✅ **Excellent JSON support** - Native JSON/JSONB types with indexing
✅ **Open source** - No licensing costs
✅ **SQL compatible** - Easy migration from SQLite
✅ **Cloud-ready** - Azure, AWS, Google Cloud all support it
✅ **Scales well** - Production-proven
✅ **Rich feature set** - Full-text search, arrays, advanced types
✅ **Great tooling** - pgAdmin, DBeaver, Azure Data Studio

### PostgreSQL vs Azure SQL

| Feature | PostgreSQL | Azure SQL |
|---------|------------|-----------|
| **Cost** | Free (self-hosted), ~$10-50/mo (cloud) | ~$5-500/mo |
| **JSON support** | Excellent (JSONB) | Good (JSON) |
| **Cross-platform** | Yes | Windows-focused |
| **Cloud options** | Azure, AWS, GCP, DigitalOcean | Azure only |
| **Open source** | Yes | No |
| **Learning curve** | Low (SQL standard) | Medium |

**Verdict:** PostgreSQL is better for this use case.

---

## Migration Path

### Phase 1: Local Development (SQLite)

```
Developer machine
├── app.db (SQLite file)
├── SQLite browser for inspection
└── Entity Framework Core
```

**Connection String:**
```
Data Source=app.db;Cache=Shared
```

**Pros:**
- Instant startup
- No dependencies
- Cross-platform
- Easy to reset

---

### Phase 2: Team Development (PostgreSQL in Docker)

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: challengeboards
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
```

**Usage:**
```bash
docker-compose up -d
dotnet ef database update
```

**Pros:**
- Test production database locally
- Multi-user development
- Closer to production environment
- Easy to tear down and rebuild

---

### Phase 3: Production (Cloud PostgreSQL)

**Option 1: Azure Database for PostgreSQL**
```
Server: myapp.postgres.database.azure.com
Database: challengeboards
Port: 5432
SSL: Required
Cost: ~$10-50/month (Flexible Server)
```

**Option 2: AWS RDS PostgreSQL**
```
Endpoint: myapp.xxxx.us-east-1.rds.amazonaws.com
Database: challengeboards
Port: 5432
Cost: ~$15-50/month (db.t3.micro to db.t3.small)
```

**Option 3: DigitalOcean Managed PostgreSQL**
```
Host: myapp-do-user-xxx.db.ondigitalocean.com
Database: challengeboards
Port: 25060
Cost: ~$15/month (1GB RAM)
```

---

## Revised Schema with JSON

### Core Tables (No Change)

These remain relational:
- Users
- Challenges
- Teams
- TeamMembers
- ChallengeParticipants
- Leaderboards (computed)
- AuditLog
- Notifications

### Health Metrics (Revised with JSON)

```sql
CREATE TABLE HealthMetrics (
    MetricId INTEGER PRIMARY KEY AUTOINCREMENT,
    UserId INTEGER NOT NULL,
    MetricDate DATE NOT NULL,
    Source TEXT,  -- 'HealthKit', 'GoogleFit', 'Garmin', 'Manual', 'Mock'

    -- Flexible metrics as JSON
    MetricsData TEXT NOT NULL,  -- SQLite uses TEXT for JSON
    -- PostgreSQL will use JSONB

    -- Common fields extracted for efficient queries
    PrimaryMetricValue INTEGER,  -- Steps, or primary metric from challenge

    SyncedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    UNIQUE (UserId, MetricDate)
);

-- SQLite JSON extraction (for queries)
CREATE INDEX idx_metrics_steps ON HealthMetrics(
    UserId,
    MetricDate,
    json_extract(MetricsData, '$.steps')
);
```

### Example Data

```json
{
  "steps": 8500,
  "activeMinutes": 45,
  "distanceKm": 6.8,
  "floors": 12,
  "heartRate": {
    "avg": 72,
    "max": 145,
    "resting": 58
  },
  "sleep": {
    "hours": 7.5,
    "quality": "good"
  }
}
```

### Querying JSON Data

**SQLite:**
```sql
SELECT
    UserId,
    MetricDate,
    json_extract(MetricsData, '$.steps') AS Steps,
    json_extract(MetricsData, '$.heartRate.avg') AS AvgHeartRate
FROM HealthMetrics
WHERE UserId = 1;
```

**PostgreSQL:**
```sql
SELECT
    UserId,
    MetricDate,
    MetricsData->>'steps' AS Steps,
    MetricsData->'heartRate'->>'avg' AS AvgHeartRate
FROM HealthMetrics
WHERE UserId = 1;
```

---

## Daily Summaries (Revised)

Instead of pre-defined columns, use JSON for flexibility:

```sql
CREATE TABLE DailySummaries (
    SummaryId INTEGER PRIMARY KEY AUTOINCREMENT,
    ChallengeId INTEGER NOT NULL,
    UserId INTEGER NOT NULL,
    SummaryDate DATE NOT NULL,

    -- Flexible aggregated metrics
    AggregatedMetrics TEXT NOT NULL,  -- JSON
    -- Example: {"totalSteps": 8500, "avgHeartRate": 72}

    -- Running totals for challenge
    CumulativeTotals TEXT NOT NULL,  -- JSON
    -- Example: {"steps": 245000, "activeMinutes": 1250}

    ComputedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    UNIQUE (ChallengeId, UserId, SummaryDate)
);
```

---

## Implementation Plan

### Step 1: Create SQLite Schema
```bash
database/
├── migrations/
│   ├── sqlite/
│   │   ├── 001_initial_up.sql
│   │   └── 001_initial_down.sql
│   └── postgresql/
│       ├── 001_initial_up.sql
│       └── 001_initial_down.sql
├── seed/
│   └── seed_data.sql (works on both)
└── docker-compose.yml
```

### Step 2: EF Core Support Both
```csharp
// appsettings.Development.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=app.db"
  },
  "DatabaseProvider": "SQLite"
}

// appsettings.Production.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=postgres;Database=challengeboards;..."
  },
  "DatabaseProvider": "PostgreSQL"
}
```

### Step 3: Database Context
```csharp
public void ConfigureServices(IServiceCollection services)
{
    var provider = Configuration["DatabaseProvider"];
    var connectionString = Configuration.GetConnectionString("DefaultConnection");

    if (provider == "SQLite")
    {
        services.AddDbContext<ChallengeDbContext>(options =>
            options.UseSqlite(connectionString));
    }
    else if (provider == "PostgreSQL")
    {
        services.AddDbContext<ChallengeDbContext>(options =>
            options.UseNpgsql(connectionString));
    }
}
```

---

## JSON Schema Design

### HealthMetrics JSON Structure

```typescript
interface MetricsData {
  // Core metrics (always present)
  steps?: number;
  activeMinutes?: number;
  distanceKm?: number;

  // Optional extended metrics
  floors?: number;
  calories?: number;

  // Heart rate (if available)
  heartRate?: {
    avg: number;
    max: number;
    min: number;
    resting: number;
  };

  // Sleep (if available)
  sleep?: {
    hours: number;
    quality: 'poor' | 'fair' | 'good' | 'excellent';
    deepSleepMinutes?: number;
    remSleepMinutes?: number;
  };

  // Activity-specific (if available)
  running?: {
    distanceKm: number;
    durationMinutes: number;
    pace: string;  // "5:30/km"
    elevationGain?: number;
  };

  cycling?: {
    distanceKm: number;
    durationMinutes: number;
    avgSpeed: number;
  };

  swimming?: {
    laps: number;
    durationMinutes: number;
    distanceMeters?: number;
  };

  // Future expansion
  [key: string]: any;  // Allow arbitrary fields
}
```

### Challenge Configuration (Also Flexible)

```typescript
interface ChallengeConfig {
  // Which metrics to track
  trackedMetrics: string[];  // ["steps", "activeMinutes", "heartRate.avg"]

  // How to score
  primaryMetric: string;  // "steps"
  scoringMethod: "total" | "average" | "max";

  // Future: Custom scoring formulas
  customFormula?: string;  // "steps * 1.0 + activeMinutes * 10"
}
```

---

## Migration Strategy

### SQLite → PostgreSQL Migration

**Database Schema:**
- 95% compatible (minor syntax differences)
- JSON handling different but EF Core abstracts it
- Auto-increment vs SERIAL

**Migration Steps:**
1. Export data from SQLite
   ```bash
   sqlite3 app.db .dump > backup.sql
   ```

2. Convert to PostgreSQL format (minor edits)
   - `AUTOINCREMENT` → `SERIAL`
   - `TEXT` → `VARCHAR` or `TEXT`
   - `DATETIME` → `TIMESTAMP`

3. Import to PostgreSQL
   ```bash
   psql -U user -d challengeboards < backup.sql
   ```

**Or use Entity Framework Core:**
```bash
# Works automatically if models are database-agnostic
dotnet ef database update --connection "PostgreSQL connection string"
```

---

## Cost Comparison

### Local Development
- **SQLite**: $0 (free)
- **PostgreSQL (Docker)**: $0 (free)

### Production (500 users, ~180K health records/year)

| Option | Monthly Cost | Pros | Cons |
|--------|--------------|------|------|
| **Azure SQL Basic** | ~$5 | Familiar | Windows-focused, limited JSON |
| **Azure PostgreSQL Flexible** | ~$10-20 | Great JSON, scalable | Slightly more complex |
| **AWS RDS PostgreSQL** | ~$15-25 | Mature, reliable | AWS learning curve |
| **DigitalOcean Managed** | ~$15 | Simple, cheap | Smaller ecosystem |
| **Self-hosted (VPS)** | ~$5-10 | Full control | Maintenance burden |

**Recommendation:** Start with DigitalOcean or Azure PostgreSQL Flexible.

---

## Testing Strategy

### Unit Tests (In-Memory SQLite)
```csharp
services.AddDbContext<ChallengeDbContext>(options =>
    options.UseSqlite("Data Source=:memory:"));
```

### Integration Tests (Docker PostgreSQL)
```yaml
services:
  test-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: test_db
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
```

---

## Advantages of This Approach

✅ **Easy local development** - No setup, cross-platform
✅ **Schema flexibility** - JSON for health metrics
✅ **Relational integrity** - SQL for core domain
✅ **Clear migration path** - SQLite → PostgreSQL → Cloud
✅ **Cost-effective** - Free for dev, ~$15/mo production
✅ **Future-proof** - Can add any metrics without migrations
✅ **Best practices** - Hybrid approach, not dogmatic

---

## Summary

### Chosen Architecture

```
Development:
  SQLite (embedded) + JSON columns for flexibility

Testing/Staging:
  PostgreSQL (Docker) + JSON columns

Production:
  PostgreSQL (Cloud) + JSONB columns
```

### Database Design Philosophy

- **SQL for structure** - Users, teams, challenges, relationships
- **JSON for flexibility** - Health metrics that evolve
- **Start simple** - SQLite for local dev
- **Scale when needed** - PostgreSQL in Docker, then cloud

### Next Steps

1. ✅ Revise schema for SQLite + JSON
2. ⏳ Create SQLite migration scripts
3. ⏳ Create PostgreSQL migration scripts (for later)
4. ⏳ Create Docker Compose file
5. ⏳ Update seed data for JSON format
6. ⏳ Document JSON schema structure

---

**Ready to implement?** 🚀
