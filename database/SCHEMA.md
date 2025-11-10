# Challenge Boards - Database Schema
**Version:** 1.0
**Database:** SQL Server / Azure SQL Database
**Date:** November 10, 2025

---

## Schema Overview

### Entity Relationship Summary
```
Users ──< ChallengeParticipants >── Challenges
  │                                      │
  │                                      │
  └──< TeamMembers >── Teams ────────────┘
  │
  └──< HealthMetrics
  │
  └──< AuditLog

Leaderboards ── (computed from HealthMetrics + Challenges)
DailySummaries ── (aggregated from HealthMetrics)
```

### Table Categories
1. **Core Entities** - Users, Challenges, Teams
2. **Relationships** - TeamMembers, ChallengeParticipants
3. **Time-Series Data** - HealthMetrics, DailySummaries
4. **Computed Data** - Leaderboards
5. **System** - AuditLog, Notifications

---

## Table Definitions

### 1. Users

Stores user accounts, profiles, and authentication information.

```sql
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NULL, -- NULL for Azure AD users
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    DisplayName NVARCHAR(200) NULL, -- Optional nickname
    Role NVARCHAR(50) NOT NULL DEFAULT 'Participant', -- Admin, Captain, Participant
    ProfileImageUrl NVARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    DataSharingConsent BIT NOT NULL DEFAULT 0, -- Global consent flag
    OngoingVisibility BIT NOT NULL DEFAULT 0, -- Strava-style public record
    LastSyncDate DATETIME2 NULL, -- Last health data sync
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    INDEX IX_Users_Email (Email),
    INDEX IX_Users_Role (Role),
    INDEX IX_Users_IsActive (IsActive)
);
```

**Constraints:**
- Email must be unique
- Role must be one of: 'Admin', 'Captain', 'Participant'

**Notes:**
- PasswordHash is NULL for Azure AD-authenticated users (Phase 4)
- LastSyncDate tracks most recent health data submission
- OngoingVisibility allows users to opt into perpetual data visibility

---

### 2. Challenges

Defines fitness challenges with configuration and rules.

```sql
CREATE TABLE Challenges (
    ChallengeId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ChallengeType NVARCHAR(50) NOT NULL, -- Individual, Team, Mixed
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2 NOT NULL,
    SignupStartDate DATETIME2 NULL,
    SignupEndDate DATETIME2 NULL,

    -- Metrics Configuration
    TrackSteps BIT NOT NULL DEFAULT 1,
    TrackActiveMinutes BIT NOT NULL DEFAULT 1,
    TrackDistance BIT NOT NULL DEFAULT 1,

    -- Scoring Configuration
    PrimaryMetric NVARCHAR(50) NOT NULL DEFAULT 'Steps', -- Steps, ActiveMinutes, Distance
    ScoringMethod NVARCHAR(50) NOT NULL DEFAULT 'Total', -- Total, DailyAverage
    TeamScoringMethod NVARCHAR(50) NULL, -- TeamTotal, TeamAverage, TopN
    TeamScoringTopN INT NULL, -- For TopN scoring
    MinTeamSize INT NULL,
    MaxTeamSize INT NULL,

    -- Status
    Status NVARCHAR(50) NOT NULL DEFAULT 'Draft', -- Draft, Signup, Active, Completed, Archived

    -- Metadata
    CreatedBy INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_Challenges_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(UserId),
    CONSTRAINT CK_Challenges_Dates CHECK (EndDate > StartDate),
    CONSTRAINT CK_Challenges_SignupDates CHECK (SignupEndDate IS NULL OR SignupEndDate >= SignupStartDate),

    INDEX IX_Challenges_Status (Status),
    INDEX IX_Challenges_Dates (StartDate, EndDate),
    INDEX IX_Challenges_ChallengeType (ChallengeType)
);
```

**Constraints:**
- EndDate must be after StartDate
- Status must be one of: 'Draft', 'Signup', 'Active', 'Completed', 'Archived'
- ChallengeType must be: 'Individual', 'Team', 'Mixed'

**Notes:**
- Flexible metric tracking (can enable/disable each metric)
- Supports multiple scoring methods
- TeamScoringTopN: For "Top 5 team members count" scoring
- SignupDates can be NULL for immediate start challenges

---

### 3. Teams

Stores team information for team-based challenges.

```sql
CREATE TABLE Teams (
    TeamId INT IDENTITY(1,1) PRIMARY KEY,
    ChallengeId INT NOT NULL,
    TeamName NVARCHAR(200) NOT NULL,
    CaptainUserId INT NOT NULL,
    TeamImageUrl NVARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_Teams_Challenge FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    CONSTRAINT FK_Teams_Captain FOREIGN KEY (CaptainUserId) REFERENCES Users(UserId),

    INDEX IX_Teams_Challenge (ChallengeId),
    INDEX IX_Teams_Captain (CaptainUserId),
    INDEX IX_Teams_IsActive (IsActive),
    UNIQUE INDEX UX_Teams_ChallengeName (ChallengeId, TeamName) WHERE IsActive = 1
);
```

**Constraints:**
- Team name must be unique within a challenge
- Captain must be a valid user

**Notes:**
- ON DELETE CASCADE: When challenge is deleted, teams are deleted
- Team names are only unique within active teams in a challenge
- Can reuse team names across different challenges

---

### 4. TeamMembers

Many-to-many relationship between teams and users.

```sql
CREATE TABLE TeamMembers (
    TeamMemberId INT IDENTITY(1,1) PRIMARY KEY,
    TeamId INT NOT NULL,
    UserId INT NOT NULL,
    JoinedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    AddedBy INT NOT NULL, -- Who added this member (captain or admin)
    IsActive BIT NOT NULL DEFAULT 1, -- For soft deletes

    CONSTRAINT FK_TeamMembers_Team FOREIGN KEY (TeamId) REFERENCES Teams(TeamId) ON DELETE CASCADE,
    CONSTRAINT FK_TeamMembers_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_TeamMembers_AddedBy FOREIGN KEY (AddedBy) REFERENCES Users(UserId),

    INDEX IX_TeamMembers_Team (TeamId),
    INDEX IX_TeamMembers_User (UserId),
    UNIQUE INDEX UX_TeamMembers_Active (TeamId, UserId) WHERE IsActive = 1
);
```

**Constraints:**
- User can only be on one active team per challenge
- Soft delete with IsActive flag

**Notes:**
- AddedBy tracks who added the member (for audit purposes)
- Soft deletes allow historical reconstruction

---

### 5. ChallengeParticipants

Tracks user enrollment and consent for challenges.

```sql
CREATE TABLE ChallengeParticipants (
    ParticipantId INT IDENTITY(1,1) PRIMARY KEY,
    ChallengeId INT NOT NULL,
    UserId INT NOT NULL,
    TeamId INT NULL, -- NULL for individual participants

    -- Consent and Enrollment
    DataSharingConsent BIT NOT NULL DEFAULT 0,
    ConsentDate DATETIME2 NULL,
    JoinedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsActive BIT NOT NULL DEFAULT 1, -- Can leave challenge
    LeftAt DATETIME2 NULL,

    -- Metadata
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_ChallengeParticipants_Challenge FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    CONSTRAINT FK_ChallengeParticipants_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_ChallengeParticipants_Team FOREIGN KEY (TeamId) REFERENCES Teams(TeamId) ON DELETE SET NULL,

    INDEX IX_ChallengeParticipants_Challenge (ChallengeId),
    INDEX IX_ChallengeParticipants_User (UserId),
    INDEX IX_ChallengeParticipants_Team (TeamId),
    INDEX IX_ChallengeParticipants_IsActive (IsActive),
    UNIQUE INDEX UX_ChallengeParticipants_Active (ChallengeId, UserId) WHERE IsActive = 1
);
```

**Constraints:**
- User can only be enrolled once per challenge
- Must have data sharing consent to participate

**Notes:**
- TeamId can be NULL for individual challenges
- ON DELETE SET NULL for TeamId: If team is deleted, participant remains in challenge
- Tracks consent at challenge level (not just global)

---

### 6. HealthMetrics

Time-series health data from users.

**Design Considerations:**
- High volume (365+ rows per user per year)
- Frequent inserts during sync
- Read-heavy for leaderboard computation
- Need for date-range queries

```sql
CREATE TABLE HealthMetrics (
    MetricId BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    MetricDate DATE NOT NULL,

    -- Health Data
    Steps INT NOT NULL DEFAULT 0,
    ActiveMinutes INT NOT NULL DEFAULT 0,
    DistanceKilometers DECIMAL(10, 2) NOT NULL DEFAULT 0,

    -- Metadata
    Source NVARCHAR(50) NULL, -- 'HealthKit', 'GoogleFit', 'Manual', 'Mock'
    SyncedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_HealthMetrics_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT CK_HealthMetrics_Steps CHECK (Steps >= 0),
    CONSTRAINT CK_HealthMetrics_ActiveMinutes CHECK (ActiveMinutes >= 0 AND ActiveMinutes <= 1440), -- Max 24 hours
    CONSTRAINT CK_HealthMetrics_Distance CHECK (DistanceKilometers >= 0),

    -- Unique constraint: One entry per user per day
    UNIQUE INDEX UX_HealthMetrics_UserDate (UserId, MetricDate),
    INDEX IX_HealthMetrics_User (UserId),
    INDEX IX_HealthMetrics_Date (MetricDate),
    INDEX IX_HealthMetrics_UserDateRange (UserId, MetricDate) INCLUDE (Steps, ActiveMinutes, DistanceKilometers)
);
```

**Constraints:**
- One record per user per day
- Steps and ActiveMinutes must be non-negative
- ActiveMinutes cannot exceed 1440 (24 hours)

**Partitioning Strategy (Future):**
```sql
-- For production at scale, partition by date
-- Partition by month or quarter for efficient archival
-- Example: Partition on MetricDate
```

**Notes:**
- BIGINT for primary key (high volume expected)
- DATE type for MetricDate (not DATETIME2) for uniqueness
- Covering index on UserDateRange for leaderboard queries
- Source tracks data origin for debugging

---

### 7. DailySummaries

Pre-aggregated daily summaries for performance optimization.

```sql
CREATE TABLE DailySummaries (
    SummaryId INT IDENTITY(1,1) PRIMARY KEY,
    ChallengeId INT NOT NULL,
    UserId INT NOT NULL,
    SummaryDate DATE NOT NULL,

    -- Aggregated Metrics
    Steps INT NOT NULL DEFAULT 0,
    ActiveMinutes INT NOT NULL DEFAULT 0,
    DistanceKilometers DECIMAL(10, 2) NOT NULL DEFAULT 0,

    -- Running Totals (within challenge)
    CumulativeSteps BIGINT NOT NULL DEFAULT 0,
    CumulativeActiveMinutes BIGINT NOT NULL DEFAULT 0,
    CumulativeDistanceKilometers DECIMAL(12, 2) NOT NULL DEFAULT 0,

    -- Metadata
    ComputedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_DailySummaries_Challenge FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    CONSTRAINT FK_DailySummaries_User FOREIGN KEY (UserId) REFERENCES Users(UserId),

    UNIQUE INDEX UX_DailySummaries_ChallengeDateUser (ChallengeId, SummaryDate, UserId),
    INDEX IX_DailySummaries_Challenge (ChallengeId),
    INDEX IX_DailySummaries_User (UserId),
    INDEX IX_DailySummaries_Date (SummaryDate)
);
```

**Purpose:**
- Avoid recalculating from raw HealthMetrics
- Store running totals for quick leaderboard access
- Updated by background job when new health data arrives

**Notes:**
- CumulativeSteps: Total steps since challenge start
- Recomputed when challenge dates or participant joins

---

### 8. Leaderboards

Materialized leaderboard rankings for fast access.

```sql
CREATE TABLE Leaderboards (
    LeaderboardId INT IDENTITY(1,1) PRIMARY KEY,
    ChallengeId INT NOT NULL,
    LeaderboardType NVARCHAR(50) NOT NULL, -- 'Individual', 'Team'
    EntityId INT NOT NULL, -- UserId or TeamId

    -- Rankings
    Rank INT NOT NULL,
    PreviousRank INT NULL,

    -- Scores
    PrimaryScore DECIMAL(18, 2) NOT NULL, -- Based on challenge PrimaryMetric
    TotalSteps BIGINT NOT NULL DEFAULT 0,
    TotalActiveMinutes BIGINT NOT NULL DEFAULT 0,
    TotalDistanceKilometers DECIMAL(12, 2) NOT NULL DEFAULT 0,

    -- Team-specific
    TeamMemberCount INT NULL, -- For team leaderboards
    TeamAverageSteps DECIMAL(18, 2) NULL,

    -- Metadata
    ComputedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_Leaderboards_Challenge FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,

    INDEX IX_Leaderboards_Challenge (ChallengeId),
    INDEX IX_Leaderboards_Type (LeaderboardType),
    INDEX IX_Leaderboards_ChallengeTypeRank (ChallengeId, LeaderboardType, Rank),
    UNIQUE INDEX UX_Leaderboards_ChallengeTypeEntity (ChallengeId, LeaderboardType, EntityId)
);
```

**Purpose:**
- Cache computed rankings
- Avoid real-time computation on every page load
- Store historical rank changes

**Notes:**
- EntityId is UserId for individual leaderboards, TeamId for team leaderboards
- PrimaryScore is computed based on challenge's PrimaryMetric setting
- PreviousRank tracks movement (up/down arrows in UI)
- Recomputed by background job every 5 minutes

---

### 9. AuditLog

Tracks all changes to critical entities.

```sql
CREATE TABLE AuditLog (
    AuditId BIGINT IDENTITY(1,1) PRIMARY KEY,
    EntityType NVARCHAR(50) NOT NULL, -- 'Challenge', 'Team', 'TeamMember', 'Participant'
    EntityId INT NOT NULL,
    Action NVARCHAR(50) NOT NULL, -- 'Create', 'Update', 'Delete', 'Reassign'
    ChangedBy INT NOT NULL,
    ChangedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    -- Change Details
    OldValues NVARCHAR(MAX) NULL, -- JSON of old values
    NewValues NVARCHAR(MAX) NULL, -- JSON of new values
    ChangeDescription NVARCHAR(500) NULL,
    IpAddress NVARCHAR(50) NULL,

    CONSTRAINT FK_AuditLog_ChangedBy FOREIGN KEY (ChangedBy) REFERENCES Users(UserId),

    INDEX IX_AuditLog_EntityType (EntityType),
    INDEX IX_AuditLog_Entity (EntityType, EntityId),
    INDEX IX_AuditLog_ChangedBy (ChangedBy),
    INDEX IX_AuditLog_ChangedAt (ChangedAt)
);
```

**Logged Actions:**
- Challenge creation, modification, deletion
- Team roster changes (especially admin overrides)
- User role changes
- Participant enrollment/withdrawal

**Notes:**
- OldValues and NewValues store JSON for flexible change tracking
- Critical for accountability in admin actions
- Can be queried for team modification history

---

### 10. Notifications

Email and notification queue (for future expansion).

```sql
CREATE TABLE Notifications (
    NotificationId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    NotificationType NVARCHAR(50) NOT NULL, -- 'ChallengeInvite', 'ChallengeStart', 'DailyUpdate', 'Results'
    Subject NVARCHAR(255) NOT NULL,
    Body NVARCHAR(MAX) NOT NULL,

    -- Status
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Sent', 'Failed'
    SentAt DATETIME2 NULL,
    ErrorMessage NVARCHAR(500) NULL,
    RetryCount INT NOT NULL DEFAULT 0,

    -- Metadata
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_Notifications_User FOREIGN KEY (UserId) REFERENCES Users(UserId),

    INDEX IX_Notifications_User (UserId),
    INDEX IX_Notifications_Status (Status),
    INDEX IX_Notifications_CreatedAt (CreatedAt)
);
```

**Purpose:**
- Queue for email sending
- Retry failed sends
- Track notification history

**Notes:**
- Background job processes pending notifications
- Stub implementation: Just logs to console
- Production: Integrates with SendGrid/Azure Communication Services

---

## Relationships Summary

### One-to-Many
- Users → HealthMetrics
- Users → ChallengeParticipants
- Challenges → Teams
- Challenges → ChallengeParticipants
- Challenges → Leaderboards

### Many-to-Many
- Users ↔ Teams (via TeamMembers)
- Users ↔ Challenges (via ChallengeParticipants)

### Computed Dependencies
- Leaderboards ← DailySummaries ← HealthMetrics
- DailySummaries ← HealthMetrics + ChallengeParticipants

---

## Indexes Strategy

### Performance Indexes
All tables include:
- Primary key clustered index
- Foreign key indexes
- Commonly filtered columns (Status, IsActive, Dates)

### Covering Indexes
- HealthMetrics: UserDateRange includes all metric columns
- Leaderboards: ChallengeTypeRank for fast leaderboard queries

### Future Considerations
- Columnstore indexes for HealthMetrics (if scale exceeds 10M rows)
- Partitioning by date for HealthMetrics and DailySummaries

---

## Data Types Rationale

| Data Type | Usage | Reason |
|-----------|-------|--------|
| `INT` | IDs for core entities | Supports 2B+ records, sufficient for organizational use |
| `BIGINT` | HealthMetrics.MetricId, cumulative scores | High volume time-series data |
| `NVARCHAR` | Text fields | Unicode support for international names |
| `DATETIME2` | Timestamps | Better precision than DATETIME, UTC storage |
| `DATE` | MetricDate, SummaryDate | No time component needed, saves space |
| `DECIMAL(10,2)` | Distance | Precise decimal calculations |
| `BIT` | Boolean flags | SQL Server boolean equivalent |

---

## Sample Data Structure

### Example Challenge Flow

```
Challenge: "November Step Challenge"
├── ChallengeId: 1
├── Type: Team
├── StartDate: 2025-11-01
├── EndDate: 2025-11-30
│
├── Teams
│   ├── Team 1: "Step Warriors"
│   │   ├── Captain: John (UserId: 2)
│   │   └── Members: [2, 3, 4, 5]
│   │
│   └── Team 2: "Fitness Fanatics"
│       ├── Captain: Sarah (UserId: 6)
│       └── Members: [6, 7, 8]
│
├── Participants
│   ├── ParticipantId: 1 → User: 2, Team: 1
│   ├── ParticipantId: 2 → User: 3, Team: 1
│   └── ... (8 total)
│
├── HealthMetrics
│   ├── User 2, Date: 2025-11-01, Steps: 8500
│   ├── User 2, Date: 2025-11-02, Steps: 10200
│   └── ... (240 records for 8 users × 30 days)
│
└── Leaderboards
    ├── Individual
    │   ├── Rank 1: User 2, Score: 285000 steps
    │   ├── Rank 2: User 6, Score: 272000 steps
    │   └── ...
    │
    └── Team
        ├── Rank 1: Team 1, Score: 950000 steps (4 members)
        └── Rank 2: Team 2, Score: 780000 steps (3 members)
```

---

## Data Integrity Rules

### Business Logic Constraints

1. **Challenge Dates**
   - EndDate > StartDate
   - SignupEndDate ≤ StartDate (if used)
   - Cannot modify challenge dates once status is 'Active'

2. **Team Membership**
   - User can only be on one team per challenge
   - Team captain must be a team member
   - Team size respects challenge min/max (if set)

3. **Health Metrics**
   - Cannot enter future dates
   - Cannot enter dates before user joined challenge
   - One entry per user per day

4. **Leaderboards**
   - Only include participants with DataSharingConsent = 1
   - Only include active challenges
   - Recompute when HealthMetrics changes

5. **Audit Trail**
   - Team roster changes must be logged
   - Admin overrides must be logged
   - Challenge status changes must be logged

---

## Performance Considerations

### Query Optimization

**Hot Paths (optimize first):**
1. Leaderboard retrieval - Use cached Leaderboards table
2. User dashboard - Indexed on UserId + ChallengeId
3. Health data sync - Batch inserts, single transaction
4. Date range queries - Indexed on MetricDate

**Caching Strategy:**
- Leaderboards: Refresh every 5 minutes
- DailySummaries: Compute once per day per user
- Challenge list: Cache for 1 minute

### Scaling Considerations

**At 500 users:**
- HealthMetrics: ~180K rows/year (500 users × 365 days)
- Leaderboards: ~50 rows per challenge × 10 challenges = 500 rows
- **Database size:** ~500 MB/year

**At 5000 users:**
- HealthMetrics: ~1.8M rows/year
- **Database size:** ~5 GB/year
- Consider partitioning HealthMetrics by month

**Mitigation:**
- Archive completed challenges older than 2 years
- Partition HealthMetrics if exceeds 10M rows
- Use read replicas for reporting queries

---

## Migration Strategy

### Phase 1: Core Schema
1. Create Users, Challenges, Teams tables
2. Create relationship tables (TeamMembers, ChallengeParticipants)
3. Seed test data

### Phase 2: Health Data
4. Create HealthMetrics table
5. Create DailySummaries table
6. Create indexes

### Phase 3: Computed Data
7. Create Leaderboards table
8. Create AuditLog table
9. Create Notifications table

### Rollback Plan
- Each migration includes DOWN script
- Backup before each migration
- Test migrations in dev environment first

---

## Seed Data Requirements

### Test Users
- 1 Admin
- 3 Captains
- 16 Participants
- **Total: 20 users**

### Test Challenges
- 1 Past challenge (completed)
- 1 Active challenge (in progress)
- 1 Future challenge (signup phase)

### Test Teams
- 3 teams in active challenge (sizes: 5, 4, 6 members)
- 2 teams in past challenge (sizes: 4, 5 members)

### Test Health Data
- Last 30 days for active challenge participants
- Realistic distribution (weekdays: 6K-10K steps, weekends: 8K-15K steps)
- Some missed days (realistic gaps)

---

## Next Steps

1. ✅ Schema designed
2. ⏳ Create SQL migration scripts
3. ⏳ Create Entity Framework Core models
4. ⏳ Create seed data script
5. ⏳ Test locally with SQL Server LocalDB
6. ⏳ Validate all relationships
7. ⏳ Performance test with 10K health records

---

**Schema complete and ready for implementation!** 🗄️
