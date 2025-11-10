-- =============================================
-- Migration: 001_Initial (SQLite)
-- Description: Create initial database schema with JSON flexibility
-- Author: System
-- Date: 2025-11-10
-- Database: SQLite 3.x
-- =============================================

PRAGMA foreign_keys = ON;

-- =============================================
-- 1. Users Table
-- =============================================

CREATE TABLE Users (
    UserId INTEGER PRIMARY KEY AUTOINCREMENT,
    Email TEXT NOT NULL UNIQUE,
    PasswordHash TEXT,
    FirstName TEXT NOT NULL,
    LastName TEXT NOT NULL,
    DisplayName TEXT,
    Role TEXT NOT NULL DEFAULT 'Participant' CHECK(Role IN ('Admin', 'Captain', 'Participant')),
    ProfileImageUrl TEXT,
    IsActive INTEGER NOT NULL DEFAULT 1 CHECK(IsActive IN (0, 1)),
    DataSharingConsent INTEGER NOT NULL DEFAULT 0 CHECK(DataSharingConsent IN (0, 1)),
    OngoingVisibility INTEGER NOT NULL DEFAULT 0 CHECK(OngoingVisibility IN (0, 1)),
    LastSyncDate TEXT,  -- ISO 8601 format
    CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
    UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_users_email ON Users(Email);
CREATE INDEX idx_users_role ON Users(Role);
CREATE INDEX idx_users_isactive ON Users(IsActive);

-- =============================================
-- 2. Challenges Table
-- =============================================

CREATE TABLE Challenges (
    ChallengeId INTEGER PRIMARY KEY AUTOINCREMENT,
    Name TEXT NOT NULL,
    Description TEXT,
    ChallengeType TEXT NOT NULL CHECK(ChallengeType IN ('Individual', 'Team', 'Mixed')),
    StartDate TEXT NOT NULL,  -- ISO 8601 date
    EndDate TEXT NOT NULL,    -- ISO 8601 date
    SignupStartDate TEXT,
    SignupEndDate TEXT,

    -- Configuration as JSON for flexibility
    Configuration TEXT NOT NULL,  -- JSON
    -- Example: {
    --   "trackedMetrics": ["steps", "activeMinutes", "distance"],
    --   "primaryMetric": "steps",
    --   "scoringMethod": "total",
    --   "teamScoringMethod": "teamAverage",
    --   "minTeamSize": 3,
    --   "maxTeamSize": 8
    -- }

    Status TEXT NOT NULL DEFAULT 'Draft' CHECK(Status IN ('Draft', 'Signup', 'Active', 'Completed', 'Archived')),

    CreatedBy INTEGER NOT NULL,
    CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
    UpdatedAt TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (CreatedBy) REFERENCES Users(UserId),
    CHECK (EndDate > StartDate)
);

CREATE INDEX idx_challenges_status ON Challenges(Status);
CREATE INDEX idx_challenges_dates ON Challenges(StartDate, EndDate);
CREATE INDEX idx_challenges_type ON Challenges(ChallengeType);
CREATE INDEX idx_challenges_createdby ON Challenges(CreatedBy);

-- =============================================
-- 3. Teams Table
-- =============================================

CREATE TABLE Teams (
    TeamId INTEGER PRIMARY KEY AUTOINCREMENT,
    ChallengeId INTEGER NOT NULL,
    TeamName TEXT NOT NULL,
    CaptainUserId INTEGER NOT NULL,
    TeamImageUrl TEXT,
    IsActive INTEGER NOT NULL DEFAULT 1 CHECK(IsActive IN (0, 1)),
    CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
    UpdatedAt TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    FOREIGN KEY (CaptainUserId) REFERENCES Users(UserId),
    UNIQUE (ChallengeId, TeamName, IsActive)
);

CREATE INDEX idx_teams_challenge ON Teams(ChallengeId);
CREATE INDEX idx_teams_captain ON Teams(CaptainUserId);
CREATE INDEX idx_teams_isactive ON Teams(IsActive);

-- =============================================
-- 4. TeamMembers Table
-- =============================================

CREATE TABLE TeamMembers (
    TeamMemberId INTEGER PRIMARY KEY AUTOINCREMENT,
    TeamId INTEGER NOT NULL,
    UserId INTEGER NOT NULL,
    JoinedAt TEXT NOT NULL DEFAULT (datetime('now')),
    AddedBy INTEGER NOT NULL,
    IsActive INTEGER NOT NULL DEFAULT 1 CHECK(IsActive IN (0, 1)),

    FOREIGN KEY (TeamId) REFERENCES Teams(TeamId) ON DELETE CASCADE,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (AddedBy) REFERENCES Users(UserId)
);

CREATE INDEX idx_teammembers_team ON TeamMembers(TeamId);
CREATE INDEX idx_teammembers_user ON TeamMembers(UserId);
CREATE INDEX idx_teammembers_isactive ON TeamMembers(IsActive);
CREATE UNIQUE INDEX idx_teammembers_unique ON TeamMembers(TeamId, UserId) WHERE IsActive = 1;

-- =============================================
-- 5. ChallengeParticipants Table
-- =============================================

CREATE TABLE ChallengeParticipants (
    ParticipantId INTEGER PRIMARY KEY AUTOINCREMENT,
    ChallengeId INTEGER NOT NULL,
    UserId INTEGER NOT NULL,
    TeamId INTEGER,

    DataSharingConsent INTEGER NOT NULL DEFAULT 0 CHECK(DataSharingConsent IN (0, 1)),
    ConsentDate TEXT,
    JoinedAt TEXT NOT NULL DEFAULT (datetime('now')),
    IsActive INTEGER NOT NULL DEFAULT 1 CHECK(IsActive IN (0, 1)),
    LeftAt TEXT,

    CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
    UpdatedAt TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (TeamId) REFERENCES Teams(TeamId) ON DELETE SET NULL
);

CREATE INDEX idx_participants_challenge ON ChallengeParticipants(ChallengeId);
CREATE INDEX idx_participants_user ON ChallengeParticipants(UserId);
CREATE INDEX idx_participants_team ON ChallengeParticipants(TeamId);
CREATE INDEX idx_participants_isactive ON ChallengeParticipants(IsActive);
CREATE UNIQUE INDEX idx_participants_unique ON ChallengeParticipants(ChallengeId, UserId) WHERE IsActive = 1;

-- =============================================
-- 6. HealthMetrics Table (with JSON flexibility)
-- =============================================

CREATE TABLE HealthMetrics (
    MetricId INTEGER PRIMARY KEY AUTOINCREMENT,
    UserId INTEGER NOT NULL,
    MetricDate TEXT NOT NULL,  -- ISO 8601 date (YYYY-MM-DD)
    Source TEXT,  -- 'HealthKit', 'GoogleFit', 'Garmin', 'Manual', 'Mock'

    -- Flexible metrics as JSON
    MetricsData TEXT NOT NULL,  -- JSON
    -- Example: {
    --   "steps": 8500,
    --   "activeMinutes": 45,
    --   "distanceKm": 6.8,
    --   "heartRate": {"avg": 72, "max": 145},
    --   "sleep": {"hours": 7.5, "quality": "good"}
    -- }

    SyncedAt TEXT NOT NULL DEFAULT (datetime('now')),
    CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    UNIQUE (UserId, MetricDate)
);

CREATE INDEX idx_metrics_user ON HealthMetrics(UserId);
CREATE INDEX idx_metrics_date ON HealthMetrics(MetricDate);
CREATE INDEX idx_metrics_userdate ON HealthMetrics(UserId, MetricDate);

-- Create indexes on common JSON fields for efficient queries
CREATE INDEX idx_metrics_steps ON HealthMetrics(
    UserId,
    json_extract(MetricsData, '$.steps')
) WHERE json_extract(MetricsData, '$.steps') IS NOT NULL;

-- =============================================
-- 7. DailySummaries Table (with JSON flexibility)
-- =============================================

CREATE TABLE DailySummaries (
    SummaryId INTEGER PRIMARY KEY AUTOINCREMENT,
    ChallengeId INTEGER NOT NULL,
    UserId INTEGER NOT NULL,
    SummaryDate TEXT NOT NULL,  -- ISO 8601 date

    -- Flexible aggregated metrics
    AggregatedMetrics TEXT NOT NULL,  -- JSON
    -- Example: {"steps": 8500, "activeMinutes": 45, "avgHeartRate": 72}

    -- Running totals for the challenge
    CumulativeTotals TEXT NOT NULL,  -- JSON
    -- Example: {"steps": 245000, "activeMinutes": 1250, "distanceKm": 196}

    ComputedAt TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    UNIQUE (ChallengeId, UserId, SummaryDate)
);

CREATE INDEX idx_summaries_challenge ON DailySummaries(ChallengeId);
CREATE INDEX idx_summaries_user ON DailySummaries(UserId);
CREATE INDEX idx_summaries_date ON DailySummaries(SummaryDate);
CREATE INDEX idx_summaries_challenge_date ON DailySummaries(ChallengeId, SummaryDate);

-- =============================================
-- 8. Leaderboards Table (with JSON flexibility)
-- =============================================

CREATE TABLE Leaderboards (
    LeaderboardId INTEGER PRIMARY KEY AUTOINCREMENT,
    ChallengeId INTEGER NOT NULL,
    LeaderboardType TEXT NOT NULL CHECK(LeaderboardType IN ('Individual', 'Team')),
    EntityId INTEGER NOT NULL,  -- UserId or TeamId

    Rank INTEGER NOT NULL,
    PreviousRank INTEGER,

    -- Flexible scores as JSON
    Scores TEXT NOT NULL,  -- JSON
    -- Example: {
    --   "primary": 245000,
    --   "steps": 245000,
    --   "activeMinutes": 1250,
    --   "distanceKm": 196,
    --   "avgSteps": 8166.67
    -- }

    -- Team-specific (nullable for individual)
    TeamMemberCount INTEGER,

    ComputedAt TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    UNIQUE (ChallengeId, LeaderboardType, EntityId)
);

CREATE INDEX idx_leaderboards_challenge ON Leaderboards(ChallengeId);
CREATE INDEX idx_leaderboards_type ON Leaderboards(LeaderboardType);
CREATE INDEX idx_leaderboards_rank ON Leaderboards(ChallengeId, LeaderboardType, Rank);
CREATE INDEX idx_leaderboards_entity ON Leaderboards(LeaderboardType, EntityId);

-- =============================================
-- 9. AuditLog Table
-- =============================================

CREATE TABLE AuditLog (
    AuditId INTEGER PRIMARY KEY AUTOINCREMENT,
    EntityType TEXT NOT NULL,  -- 'Challenge', 'Team', 'TeamMember', 'Participant'
    EntityId INTEGER NOT NULL,
    Action TEXT NOT NULL,  -- 'Create', 'Update', 'Delete', 'Reassign'
    ChangedBy INTEGER NOT NULL,
    ChangedAt TEXT NOT NULL DEFAULT (datetime('now')),

    -- Change details as JSON
    OldValues TEXT,  -- JSON
    NewValues TEXT,  -- JSON
    ChangeDescription TEXT,
    IpAddress TEXT,

    FOREIGN KEY (ChangedBy) REFERENCES Users(UserId)
);

CREATE INDEX idx_auditlog_entity ON AuditLog(EntityType, EntityId);
CREATE INDEX idx_auditlog_changedby ON AuditLog(ChangedBy);
CREATE INDEX idx_auditlog_changedat ON AuditLog(ChangedAt);

-- =============================================
-- 10. Notifications Table
-- =============================================

CREATE TABLE Notifications (
    NotificationId INTEGER PRIMARY KEY AUTOINCREMENT,
    UserId INTEGER NOT NULL,
    NotificationType TEXT NOT NULL,
    Subject TEXT NOT NULL,
    Body TEXT NOT NULL,

    Status TEXT NOT NULL DEFAULT 'Pending' CHECK(Status IN ('Pending', 'Sent', 'Failed')),
    SentAt TEXT,
    ErrorMessage TEXT,
    RetryCount INTEGER NOT NULL DEFAULT 0,

    CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE INDEX idx_notifications_user ON Notifications(UserId);
CREATE INDEX idx_notifications_status ON Notifications(Status);
CREATE INDEX idx_notifications_created ON Notifications(CreatedAt);

-- =============================================
-- Migration Complete
-- =============================================

SELECT 'Migration 001_Initial completed successfully!' AS Message;
SELECT 'Database: SQLite with JSON flexibility' AS Info;
SELECT '10 tables created' AS Summary;
