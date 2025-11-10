-- =============================================
-- Migration: 001_InitialSchema
-- Description: Create initial database schema for Challenge Boards
-- Author: System
-- Date: 2025-11-10
-- =============================================

-- Enable ANSI_NULLS and QUOTED_IDENTIFIER
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Starting Migration 001_InitialSchema...';
GO

-- =============================================
-- 1. Create Users Table
-- =============================================
PRINT 'Creating Users table...';

CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(255) NOT NULL,
    PasswordHash NVARCHAR(255) NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    DisplayName NVARCHAR(200) NULL,
    Role NVARCHAR(50) NOT NULL DEFAULT 'Participant',
    ProfileImageUrl NVARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    DataSharingConsent BIT NOT NULL DEFAULT 0,
    OngoingVisibility BIT NOT NULL DEFAULT 0,
    LastSyncDate DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT UX_Users_Email UNIQUE (Email),
    CONSTRAINT CK_Users_Role CHECK (Role IN ('Admin', 'Captain', 'Participant'))
);

CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_Role ON Users(Role);
CREATE INDEX IX_Users_IsActive ON Users(IsActive);

PRINT 'Users table created successfully.';
GO

-- =============================================
-- 2. Create Challenges Table
-- =============================================
PRINT 'Creating Challenges table...';

CREATE TABLE Challenges (
    ChallengeId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ChallengeType NVARCHAR(50) NOT NULL,
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2 NOT NULL,
    SignupStartDate DATETIME2 NULL,
    SignupEndDate DATETIME2 NULL,

    TrackSteps BIT NOT NULL DEFAULT 1,
    TrackActiveMinutes BIT NOT NULL DEFAULT 1,
    TrackDistance BIT NOT NULL DEFAULT 1,

    PrimaryMetric NVARCHAR(50) NOT NULL DEFAULT 'Steps',
    ScoringMethod NVARCHAR(50) NOT NULL DEFAULT 'Total',
    TeamScoringMethod NVARCHAR(50) NULL,
    TeamScoringTopN INT NULL,
    MinTeamSize INT NULL,
    MaxTeamSize INT NULL,

    Status NVARCHAR(50) NOT NULL DEFAULT 'Draft',

    CreatedBy INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_Challenges_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(UserId),
    CONSTRAINT CK_Challenges_Dates CHECK (EndDate > StartDate),
    CONSTRAINT CK_Challenges_SignupDates CHECK (SignupEndDate IS NULL OR SignupEndDate >= SignupStartDate),
    CONSTRAINT CK_Challenges_Type CHECK (ChallengeType IN ('Individual', 'Team', 'Mixed')),
    CONSTRAINT CK_Challenges_Status CHECK (Status IN ('Draft', 'Signup', 'Active', 'Completed', 'Archived')),
    CONSTRAINT CK_Challenges_PrimaryMetric CHECK (PrimaryMetric IN ('Steps', 'ActiveMinutes', 'Distance')),
    CONSTRAINT CK_Challenges_ScoringMethod CHECK (ScoringMethod IN ('Total', 'DailyAverage'))
);

CREATE INDEX IX_Challenges_Status ON Challenges(Status);
CREATE INDEX IX_Challenges_Dates ON Challenges(StartDate, EndDate);
CREATE INDEX IX_Challenges_ChallengeType ON Challenges(ChallengeType);

PRINT 'Challenges table created successfully.';
GO

-- =============================================
-- 3. Create Teams Table
-- =============================================
PRINT 'Creating Teams table...';

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
    CONSTRAINT FK_Teams_Captain FOREIGN KEY (CaptainUserId) REFERENCES Users(UserId)
);

CREATE INDEX IX_Teams_Challenge ON Teams(ChallengeId);
CREATE INDEX IX_Teams_Captain ON Teams(CaptainUserId);
CREATE INDEX IX_Teams_IsActive ON Teams(IsActive);
CREATE UNIQUE INDEX UX_Teams_ChallengeName ON Teams(ChallengeId, TeamName) WHERE IsActive = 1;

PRINT 'Teams table created successfully.';
GO

-- =============================================
-- 4. Create TeamMembers Table
-- =============================================
PRINT 'Creating TeamMembers table...';

CREATE TABLE TeamMembers (
    TeamMemberId INT IDENTITY(1,1) PRIMARY KEY,
    TeamId INT NOT NULL,
    UserId INT NOT NULL,
    JoinedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    AddedBy INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,

    CONSTRAINT FK_TeamMembers_Team FOREIGN KEY (TeamId) REFERENCES Teams(TeamId) ON DELETE CASCADE,
    CONSTRAINT FK_TeamMembers_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_TeamMembers_AddedBy FOREIGN KEY (AddedBy) REFERENCES Users(UserId)
);

CREATE INDEX IX_TeamMembers_Team ON TeamMembers(TeamId);
CREATE INDEX IX_TeamMembers_User ON TeamMembers(UserId);
CREATE UNIQUE INDEX UX_TeamMembers_Active ON TeamMembers(TeamId, UserId) WHERE IsActive = 1;

PRINT 'TeamMembers table created successfully.';
GO

-- =============================================
-- 5. Create ChallengeParticipants Table
-- =============================================
PRINT 'Creating ChallengeParticipants table...';

CREATE TABLE ChallengeParticipants (
    ParticipantId INT IDENTITY(1,1) PRIMARY KEY,
    ChallengeId INT NOT NULL,
    UserId INT NOT NULL,
    TeamId INT NULL,

    DataSharingConsent BIT NOT NULL DEFAULT 0,
    ConsentDate DATETIME2 NULL,
    JoinedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsActive BIT NOT NULL DEFAULT 1,
    LeftAt DATETIME2 NULL,

    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_ChallengeParticipants_Challenge FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    CONSTRAINT FK_ChallengeParticipants_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_ChallengeParticipants_Team FOREIGN KEY (TeamId) REFERENCES Teams(TeamId) ON DELETE SET NULL
);

CREATE INDEX IX_ChallengeParticipants_Challenge ON ChallengeParticipants(ChallengeId);
CREATE INDEX IX_ChallengeParticipants_User ON ChallengeParticipants(UserId);
CREATE INDEX IX_ChallengeParticipants_Team ON ChallengeParticipants(TeamId);
CREATE INDEX IX_ChallengeParticipants_IsActive ON ChallengeParticipants(IsActive);
CREATE UNIQUE INDEX UX_ChallengeParticipants_Active ON ChallengeParticipants(ChallengeId, UserId) WHERE IsActive = 1;

PRINT 'ChallengeParticipants table created successfully.';
GO

-- =============================================
-- 6. Create HealthMetrics Table
-- =============================================
PRINT 'Creating HealthMetrics table...';

CREATE TABLE HealthMetrics (
    MetricId BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    MetricDate DATE NOT NULL,

    Steps INT NOT NULL DEFAULT 0,
    ActiveMinutes INT NOT NULL DEFAULT 0,
    DistanceKilometers DECIMAL(10, 2) NOT NULL DEFAULT 0,

    Source NVARCHAR(50) NULL,
    SyncedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_HealthMetrics_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT CK_HealthMetrics_Steps CHECK (Steps >= 0),
    CONSTRAINT CK_HealthMetrics_ActiveMinutes CHECK (ActiveMinutes >= 0 AND ActiveMinutes <= 1440),
    CONSTRAINT CK_HealthMetrics_Distance CHECK (DistanceKilometers >= 0)
);

CREATE UNIQUE INDEX UX_HealthMetrics_UserDate ON HealthMetrics(UserId, MetricDate);
CREATE INDEX IX_HealthMetrics_User ON HealthMetrics(UserId);
CREATE INDEX IX_HealthMetrics_Date ON HealthMetrics(MetricDate);
CREATE INDEX IX_HealthMetrics_UserDateRange ON HealthMetrics(UserId, MetricDate) INCLUDE (Steps, ActiveMinutes, DistanceKilometers);

PRINT 'HealthMetrics table created successfully.';
GO

-- =============================================
-- 7. Create DailySummaries Table
-- =============================================
PRINT 'Creating DailySummaries table...';

CREATE TABLE DailySummaries (
    SummaryId INT IDENTITY(1,1) PRIMARY KEY,
    ChallengeId INT NOT NULL,
    UserId INT NOT NULL,
    SummaryDate DATE NOT NULL,

    Steps INT NOT NULL DEFAULT 0,
    ActiveMinutes INT NOT NULL DEFAULT 0,
    DistanceKilometers DECIMAL(10, 2) NOT NULL DEFAULT 0,

    CumulativeSteps BIGINT NOT NULL DEFAULT 0,
    CumulativeActiveMinutes BIGINT NOT NULL DEFAULT 0,
    CumulativeDistanceKilometers DECIMAL(12, 2) NOT NULL DEFAULT 0,

    ComputedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_DailySummaries_Challenge FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    CONSTRAINT FK_DailySummaries_User FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE UNIQUE INDEX UX_DailySummaries_ChallengeDateUser ON DailySummaries(ChallengeId, SummaryDate, UserId);
CREATE INDEX IX_DailySummaries_Challenge ON DailySummaries(ChallengeId);
CREATE INDEX IX_DailySummaries_User ON DailySummaries(UserId);
CREATE INDEX IX_DailySummaries_Date ON DailySummaries(SummaryDate);

PRINT 'DailySummaries table created successfully.';
GO

-- =============================================
-- 8. Create Leaderboards Table
-- =============================================
PRINT 'Creating Leaderboards table...';

CREATE TABLE Leaderboards (
    LeaderboardId INT IDENTITY(1,1) PRIMARY KEY,
    ChallengeId INT NOT NULL,
    LeaderboardType NVARCHAR(50) NOT NULL,
    EntityId INT NOT NULL,

    Rank INT NOT NULL,
    PreviousRank INT NULL,

    PrimaryScore DECIMAL(18, 2) NOT NULL,
    TotalSteps BIGINT NOT NULL DEFAULT 0,
    TotalActiveMinutes BIGINT NOT NULL DEFAULT 0,
    TotalDistanceKilometers DECIMAL(12, 2) NOT NULL DEFAULT 0,

    TeamMemberCount INT NULL,
    TeamAverageSteps DECIMAL(18, 2) NULL,

    ComputedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_Leaderboards_Challenge FOREIGN KEY (ChallengeId) REFERENCES Challenges(ChallengeId) ON DELETE CASCADE,
    CONSTRAINT CK_Leaderboards_Type CHECK (LeaderboardType IN ('Individual', 'Team'))
);

CREATE INDEX IX_Leaderboards_Challenge ON Leaderboards(ChallengeId);
CREATE INDEX IX_Leaderboards_Type ON Leaderboards(LeaderboardType);
CREATE INDEX IX_Leaderboards_ChallengeTypeRank ON Leaderboards(ChallengeId, LeaderboardType, Rank);
CREATE UNIQUE INDEX UX_Leaderboards_ChallengeTypeEntity ON Leaderboards(ChallengeId, LeaderboardType, EntityId);

PRINT 'Leaderboards table created successfully.';
GO

-- =============================================
-- 9. Create AuditLog Table
-- =============================================
PRINT 'Creating AuditLog table...';

CREATE TABLE AuditLog (
    AuditId BIGINT IDENTITY(1,1) PRIMARY KEY,
    EntityType NVARCHAR(50) NOT NULL,
    EntityId INT NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    ChangedBy INT NOT NULL,
    ChangedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    ChangeDescription NVARCHAR(500) NULL,
    IpAddress NVARCHAR(50) NULL,

    CONSTRAINT FK_AuditLog_ChangedBy FOREIGN KEY (ChangedBy) REFERENCES Users(UserId)
);

CREATE INDEX IX_AuditLog_EntityType ON AuditLog(EntityType);
CREATE INDEX IX_AuditLog_Entity ON AuditLog(EntityType, EntityId);
CREATE INDEX IX_AuditLog_ChangedBy ON AuditLog(ChangedBy);
CREATE INDEX IX_AuditLog_ChangedAt ON AuditLog(ChangedAt);

PRINT 'AuditLog table created successfully.';
GO

-- =============================================
-- 10. Create Notifications Table
-- =============================================
PRINT 'Creating Notifications table...';

CREATE TABLE Notifications (
    NotificationId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    NotificationType NVARCHAR(50) NOT NULL,
    Subject NVARCHAR(255) NOT NULL,
    Body NVARCHAR(MAX) NOT NULL,

    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending',
    SentAt DATETIME2 NULL,
    ErrorMessage NVARCHAR(500) NULL,
    RetryCount INT NOT NULL DEFAULT 0,

    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_Notifications_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT CK_Notifications_Status CHECK (Status IN ('Pending', 'Sent', 'Failed'))
);

CREATE INDEX IX_Notifications_User ON Notifications(UserId);
CREATE INDEX IX_Notifications_Status ON Notifications(Status);
CREATE INDEX IX_Notifications_CreatedAt ON Notifications(CreatedAt);

PRINT 'Notifications table created successfully.';
GO

-- =============================================
-- Migration Complete
-- =============================================
PRINT 'Migration 001_InitialSchema completed successfully!';
PRINT '10 tables created: Users, Challenges, Teams, TeamMembers, ChallengeParticipants, HealthMetrics, DailySummaries, Leaderboards, AuditLog, Notifications';
GO
