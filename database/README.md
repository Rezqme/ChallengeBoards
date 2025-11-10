# Challenge Boards - Database Documentation

## Overview
This directory contains all database schema definitions, migrations, and seed data for the Challenge Boards application.

---

## Directory Structure

```
database/
├── README.md                           # This file
├── SCHEMA.md                           # Detailed schema documentation
├── migrations/
│   ├── 001_InitialSchema_UP.sql       # Create initial schema
│   └── 001_InitialSchema_DOWN.sql     # Rollback initial schema
└── seed/
    └── SeedData.sql                    # Test data for development
```

---

## Quick Start

### Using SQL Server LocalDB (Windows)

```bash
# 1. Create database
sqllocaldb create ChallengeBoards
sqllocaldb start ChallengeBoards

# 2. Run migration
sqlcmd -S (localdb)\ChallengeBoards -d master -Q "CREATE DATABASE ChallengeBoardsDb"
sqlcmd -S (localdb)\ChallengeBoards -d ChallengeBoardsDb -i migrations/001_InitialSchema_UP.sql

# 3. Seed data
sqlcmd -S (localdb)\ChallengeBoards -d ChallengeBoardsDb -i seed/SeedData.sql
```

### Using Docker SQL Server (Mac/Linux/Windows)

```bash
# 1. Start SQL Server container
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong@Password123" \
  -p 1433:1433 --name sql-server-dev \
  -d mcr.microsoft.com/mssql/server:2022-latest

# 2. Wait for SQL Server to start (30 seconds)
sleep 30

# 3. Create database
docker exec -it sql-server-dev /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "YourStrong@Password123" \
  -Q "CREATE DATABASE ChallengeBoardsDb"

# 4. Run migration
docker exec -it sql-server-dev /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "YourStrong@Password123" \
  -d ChallengeBoardsDb -i /sql/001_InitialSchema_UP.sql

# Note: You'll need to mount the migrations directory
# Alternative: Use Azure Data Studio or SQL Server Management Studio
```

### Using Azure Data Studio (Recommended for All Platforms)

1. **Install Azure Data Studio**
   - Download from: https://aka.ms/azuredatastudio
   - Available for Windows, Mac, Linux

2. **Connect to Database**
   - LocalDB: `(localdb)\MSSQLLocalDB`
   - Docker: `localhost,1433` (username: `sa`)

3. **Run Scripts**
   - Open `migrations/001_InitialSchema_UP.sql`
   - Click "Run" or press F5
   - Open `seed/SeedData.sql`
   - Click "Run" or press F5

---

## Connection Strings

### Development (LocalDB)
```
Server=(localdb)\\MSSQLLocalDB;Database=ChallengeBoardsDb;Integrated Security=true;TrustServerCertificate=true
```

### Development (Docker)
```
Server=localhost,1433;Database=ChallengeBoardsDb;User Id=sa;Password=YourStrong@Password123;TrustServerCertificate=true
```

### Production (Azure SQL)
```
Server=tcp:your-server.database.windows.net,1433;Database=ChallengeBoardsDb;User ID=your-admin;Password=your-password;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;
```

---

## Database Schema Summary

### Core Tables
| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| **Users** | User accounts and profiles | → HealthMetrics, ChallengeParticipants |
| **Challenges** | Challenge definitions | → Teams, ChallengeParticipants |
| **Teams** | Team information | ← Challenges, → TeamMembers |
| **TeamMembers** | Many-to-many: Users ↔ Teams | ← Teams, Users |
| **ChallengeParticipants** | Many-to-many: Users ↔ Challenges | ← Challenges, Users, Teams |

### Data Tables
| Table | Purpose | Size Estimate |
|-------|---------|---------------|
| **HealthMetrics** | Time-series health data | ~180K rows/year (500 users) |
| **DailySummaries** | Pre-aggregated summaries | ~15K rows/year (500 users × 30 days) |
| **Leaderboards** | Cached rankings | ~50 rows per challenge |

### System Tables
| Table | Purpose |
|-------|---------|
| **AuditLog** | Change tracking and accountability |
| **Notifications** | Email/notification queue |

See [SCHEMA.md](SCHEMA.md) for detailed table definitions.

---

## Seed Data Contents

The seed data script creates a complete test environment:

### Users (20)
- 1 Admin: `admin@challengeboards.com`
- 3 Captains: `john.smith@company.com`, `sarah.johnson@company.com`, `mike.williams@company.com`
- 16 Participants

**Default Password:** `Test123!` (all accounts)

### Challenges (3)
1. **October Step Challenge** (Completed)
   - Team-based
   - October 1-31, 2025
   - 2 teams, 10 participants

2. **November Fitness Challenge** (Active) ⭐
   - Team-based
   - November 1-30, 2025
   - 3 teams, 15 participants
   - **Has realistic health data for testing**

3. **Holiday Step Sprint** (Signup)
   - Individual-based
   - December 15-31, 2025
   - Signup phase

### Health Data
- **~140 records** for November challenge (Nov 1-10)
- Realistic patterns:
  - Weekdays: 6,000-10,000 steps
  - Weekends: 8,000-15,000 steps
  - Random gaps (simulates missed days)

### Leaderboards
- Pre-computed for November challenge
- Individual rankings (15 participants)
- Team rankings (3 teams)

---

## Common Tasks

### Reset Database
```sql
-- Run the DOWN migration, then UP migration, then seed
USE ChallengeBoardsDb;
GO

-- Execute migrations/001_InitialSchema_DOWN.sql
-- Execute migrations/001_InitialSchema_UP.sql
-- Execute seed/SeedData.sql
```

### Verify Schema
```sql
-- List all tables
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Check row counts
SELECT 'Users' AS TableName, COUNT(*) AS Records FROM Users
UNION ALL SELECT 'Challenges', COUNT(*) FROM Challenges
UNION ALL SELECT 'Teams', COUNT(*) FROM Teams
UNION ALL SELECT 'HealthMetrics', COUNT(*) FROM HealthMetrics
UNION ALL SELECT 'Leaderboards', COUNT(*) FROM Leaderboards;
```

### Query Test Data
```sql
-- Get active challenge with teams
SELECT
    c.Name AS ChallengeName,
    t.TeamName,
    u.FirstName + ' ' + u.LastName AS Captain
FROM Challenges c
INNER JOIN Teams t ON c.ChallengeId = t.ChallengeId
INNER JOIN Users u ON t.CaptainUserId = u.UserId
WHERE c.Status = 'Active';

-- Get leaderboard for November challenge
SELECT
    l.Rank,
    u.DisplayName,
    l.TotalSteps,
    l.TotalActiveMinutes,
    l.TotalDistanceKilometers
FROM Leaderboards l
INNER JOIN Users u ON l.EntityId = u.UserId
WHERE l.ChallengeId = 2
    AND l.LeaderboardType = 'Individual'
ORDER BY l.Rank;

-- Get team leaderboard
SELECT
    l.Rank,
    t.TeamName,
    l.TeamMemberCount,
    l.TeamAverageSteps,
    l.TotalSteps
FROM Leaderboards l
INNER JOIN Teams t ON l.EntityId = t.TeamId
WHERE l.ChallengeId = 2
    AND l.LeaderboardType = 'Team'
ORDER BY l.Rank;
```

---

## Migration Strategy

### Creating New Migrations

When adding new features:

1. **Create UP migration**: `002_FeatureName_UP.sql`
2. **Create DOWN migration**: `002_FeatureName_DOWN.sql`
3. **Update schema documentation**: `SCHEMA.md`
4. **Test both UP and DOWN**

**Naming Convention:**
- `{number}_{FeatureName}_UP.sql`
- `{number}_{FeatureName}_DOWN.sql`

**Example:**
- `002_AddAchievementsTable_UP.sql`
- `002_AddAchievementsTable_DOWN.sql`

### Migration Best Practices

- ✅ Always create both UP and DOWN scripts
- ✅ Use transactions for multi-statement migrations
- ✅ Test on a copy of production data
- ✅ Include rollback plan
- ✅ Backup before running migrations
- ❌ Never modify existing migrations (create new ones)
- ❌ Never run migrations manually in production (use CI/CD)

---

## Entity Framework Core

When using EF Core, you can generate migrations from code-first models:

```bash
# Add migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update

# Generate SQL script (for review)
dotnet ef migrations script
```

However, for this project, we recommend **database-first** approach:
- Schema is version-controlled in SQL files
- EF Core models are scaffolded from database
- Better control over indexes and constraints

---

## Performance Considerations

### Indexes
All tables include appropriate indexes for:
- Primary keys (clustered)
- Foreign keys
- Commonly filtered columns
- Covering indexes for hot paths

### Query Optimization Tips

**For Leaderboard Queries:**
- Use cached `Leaderboards` table (recomputed every 5 min)
- Don't recompute from `HealthMetrics` on every request

**For Health Data Queries:**
- Filter by date range first
- Use `DailySummaries` for aggregations
- Avoid `SELECT *` - specify needed columns

**For Time-Series Data:**
- Consider partitioning `HealthMetrics` if > 10M rows
- Archive old challenges to separate tables

---

## Troubleshooting

### "Cannot open database" Error
```sql
-- Check if database exists
SELECT name FROM sys.databases WHERE name = 'ChallengeBoardsDb';

-- Create if missing
CREATE DATABASE ChallengeBoardsDb;
```

### "Object already exists" Error
```sql
-- Run DOWN migration first to clean up
-- Then run UP migration
```

### "Foreign key constraint" Error
- Ensure seed data is inserted in correct order
- Check that referenced IDs exist
- Disable constraints temporarily (not recommended):
  ```sql
  ALTER TABLE TableName NOCHECK CONSTRAINT ALL;
  -- Insert data
  ALTER TABLE TableName CHECK CONSTRAINT ALL;
  ```

### LocalDB Not Found (Windows)
```bash
# List LocalDB instances
sqllocaldb info

# Create new instance
sqllocaldb create MSSQLLocalDB

# Start instance
sqllocaldb start MSSQLLocalDB
```

---

## Backup and Restore

### Backup Database
```sql
BACKUP DATABASE ChallengeBoardsDb
TO DISK = 'C:\Backups\ChallengeBoardsDb.bak'
WITH FORMAT, MEDIANAME = 'ChallengeBoardsBackup', NAME = 'Full Backup';
```

### Restore Database
```sql
RESTORE DATABASE ChallengeBoardsDb
FROM DISK = 'C:\Backups\ChallengeBoardsDb.bak'
WITH REPLACE;
```

---

## Next Steps

1. ✅ Database schema designed
2. ✅ Migration scripts created
3. ✅ Seed data script created
4. ⏳ Create .NET solution with EF Core
5. ⏳ Scaffold EF Core models from database
6. ⏳ Build API with repository pattern
7. ⏳ Create React frontend

---

## Additional Resources

- [SQL Server LocalDB Documentation](https://docs.microsoft.com/sql/database-engine/configure-windows/sql-server-express-localdb)
- [Azure Data Studio Download](https://aka.ms/azuredatastudio)
- [Entity Framework Core Documentation](https://docs.microsoft.com/ef/core/)
- [SQL Server Best Practices](https://docs.microsoft.com/sql/relational-databases/best-practices)

---

**Questions or Issues?**
See [SCHEMA.md](SCHEMA.md) for detailed schema documentation.
