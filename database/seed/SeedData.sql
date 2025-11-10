-- =============================================
-- Seed Data Script for Challenge Boards
-- Description: Populate database with realistic test data
-- Author: System
-- Date: 2025-11-10
-- =============================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

PRINT 'Starting seed data population...';
GO

-- =============================================
-- 1. Seed Users
-- =============================================
PRINT 'Seeding Users...';

-- Clear existing data (for re-seeding)
DELETE FROM Notifications;
DELETE FROM AuditLog;
DELETE FROM Leaderboards;
DELETE FROM DailySummaries;
DELETE FROM HealthMetrics;
DELETE FROM ChallengeParticipants;
DELETE FROM TeamMembers;
DELETE FROM Teams;
DELETE FROM Challenges;
DELETE FROM Users;

-- Reset identity seeds
DBCC CHECKIDENT ('Users', RESEED, 0);
DBCC CHECKIDENT ('Challenges', RESEED, 0);
DBCC CHECKIDENT ('Teams', RESEED, 0);
GO

-- Insert 20 test users
-- Password hash for "Test123!" (stub - not real bcrypt)
DECLARE @passwordHash NVARCHAR(255) = '$2a$11$StubHashForDevelopmentOnly';

-- 1 Admin
INSERT INTO Users (Email, PasswordHash, FirstName, LastName, DisplayName, Role, IsActive, DataSharingConsent, OngoingVisibility)
VALUES
('admin@challengeboards.com', @passwordHash, 'Alice', 'Admin', 'Admin Alice', 'Admin', 1, 1, 1);

-- 3 Captains
INSERT INTO Users (Email, PasswordHash, FirstName, LastName, DisplayName, Role, IsActive, DataSharingConsent, OngoingVisibility)
VALUES
('john.smith@company.com', @passwordHash, 'John', 'Smith', 'Johnny Steps', 'Captain', 1, 1, 1),
('sarah.johnson@company.com', @passwordHash, 'Sarah', 'Johnson', 'Speedy Sarah', 'Captain', 1, 1, 1),
('mike.williams@company.com', @passwordHash, 'Mike', 'Williams', 'Mike the Hiker', 'Captain', 1, 1, 1);

-- 16 Participants
INSERT INTO Users (Email, PasswordHash, FirstName, LastName, DisplayName, Role, IsActive, DataSharingConsent, OngoingVisibility)
VALUES
('emma.brown@company.com', @passwordHash, 'Emma', 'Brown', 'Emma B', 'Participant', 1, 1, 0),
('james.davis@company.com', @passwordHash, 'James', 'Davis', 'JD', 'Participant', 1, 1, 1),
('olivia.miller@company.com', @passwordHash, 'Olivia', 'Miller', 'Olivia', 'Participant', 1, 1, 0),
('william.wilson@company.com', @passwordHash, 'William', 'Wilson', 'Will', 'Participant', 1, 1, 1),
('sophia.moore@company.com', @passwordHash, 'Sophia', 'Moore', 'Sophie', 'Participant', 1, 1, 0),
('benjamin.taylor@company.com', @passwordHash, 'Benjamin', 'Taylor', 'Ben T', 'Participant', 1, 1, 1),
('charlotte.anderson@company.com', @passwordHash, 'Charlotte', 'Anderson', 'Charlie', 'Participant', 1, 1, 0),
('lucas.thomas@company.com', @passwordHash, 'Lucas', 'Thomas', 'Luke', 'Participant', 1, 1, 1),
('amelia.jackson@company.com', @passwordHash, 'Amelia', 'Jackson', 'Amy', 'Participant', 1, 1, 0),
('henry.white@company.com', @passwordHash, 'Henry', 'White', 'Hank', 'Participant', 1, 1, 1),
('mia.harris@company.com', @passwordHash, 'Mia', 'Harris', 'Mia H', 'Participant', 1, 1, 0),
('alexander.martin@company.com', @passwordHash, 'Alexander', 'Martin', 'Alex', 'Participant', 1, 1, 1),
('isabella.thompson@company.com', @passwordHash, 'Isabella', 'Thompson', 'Bella', 'Participant', 1, 1, 0),
('daniel.garcia@company.com', @passwordHash, 'Daniel', 'Garcia', 'Danny', 'Participant', 1, 1, 1),
('ava.martinez@company.com', @passwordHash, 'Ava', 'Martinez', 'Ava M', 'Participant', 1, 1, 0),
('matthew.robinson@company.com', @passwordHash, 'Matthew', 'Robinson', 'Matt', 'Participant', 1, 1, 1);

PRINT 'Users seeded: 20 users (1 Admin, 3 Captains, 16 Participants)';
GO

-- =============================================
-- 2. Seed Challenges
-- =============================================
PRINT 'Seeding Challenges...';

-- Challenge 1: Past challenge (October 2025)
INSERT INTO Challenges (
    Name, Description, ChallengeType,
    StartDate, EndDate, SignupStartDate, SignupEndDate,
    TrackSteps, TrackActiveMinutes, TrackDistance,
    PrimaryMetric, ScoringMethod, TeamScoringMethod,
    Status, CreatedBy
)
VALUES (
    'October Step Challenge',
    'Kick off fall with a month-long step challenge! Compete in teams to see who can walk the most.',
    'Team',
    '2025-10-01', '2025-10-31', '2025-09-20', '2025-09-30',
    1, 1, 1,
    'Steps', 'Total', 'TeamTotal',
    'Completed',
    1 -- Admin
);

-- Challenge 2: Active challenge (November 2025)
INSERT INTO Challenges (
    Name, Description, ChallengeType,
    StartDate, EndDate, SignupStartDate, SignupEndDate,
    TrackSteps, TrackActiveMinutes, TrackDistance,
    PrimaryMetric, ScoringMethod, TeamScoringMethod,
    MinTeamSize, MaxTeamSize,
    Status, CreatedBy
)
VALUES (
    'November Fitness Challenge',
    'Stay active this November! Track your steps, active minutes, and distance. May the best team win!',
    'Team',
    '2025-11-01', '2025-11-30', '2025-10-20', '2025-10-31',
    1, 1, 1,
    'Steps', 'Total', 'TeamAverage',
    3, 8,
    'Active',
    1 -- Admin
);

-- Challenge 3: Future challenge (December 2025)
INSERT INTO Challenges (
    Name, Description, ChallengeType,
    StartDate, EndDate, SignupStartDate, SignupEndDate,
    TrackSteps, TrackActiveMinutes, TrackDistance,
    PrimaryMetric, ScoringMethod, TeamScoringMethod,
    Status, CreatedBy
)
VALUES (
    'Holiday Step Sprint',
    'Two-week sprint challenge to stay active during the holidays!',
    'Individual',
    '2025-12-15', '2025-12-31', '2025-12-01', '2025-12-14',
    1, 1, 1,
    'Steps', 'DailyAverage', NULL,
    'Signup',
    1 -- Admin
);

PRINT 'Challenges seeded: 3 challenges (1 Completed, 1 Active, 1 Signup)';
GO

-- =============================================
-- 3. Seed Teams
-- =============================================
PRINT 'Seeding Teams...';

-- Teams for October Challenge (ChallengeId = 1)
INSERT INTO Teams (ChallengeId, TeamName, CaptainUserId, IsActive)
VALUES
(1, 'Step Warriors', 2, 1), -- John Smith
(1, 'Fitness Fanatics', 3, 1); -- Sarah Johnson

-- Teams for November Challenge (ChallengeId = 2)
INSERT INTO Teams (ChallengeId, TeamName, CaptainUserId, IsActive)
VALUES
(2, 'Thunder Walkers', 2, 1), -- John Smith
(2, 'Lightning Steppers', 3, 1), -- Sarah Johnson
(2, 'Hiking Heroes', 4, 1); -- Mike Williams

PRINT 'Teams seeded: 5 teams (2 in October, 3 in November)';
GO

-- =============================================
-- 4. Seed Team Members
-- =============================================
PRINT 'Seeding Team Members...';

-- October Challenge - Step Warriors (Team 1)
-- Captain (John) + 4 members
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(1, 2, 2, '2025-09-25', 1),  -- John (Captain)
(1, 5, 2, '2025-09-25', 1),  -- Emma
(1, 6, 2, '2025-09-26', 1),  -- James
(1, 7, 2, '2025-09-26', 1),  -- Olivia
(1, 8, 2, '2025-09-27', 1);  -- William

-- October Challenge - Fitness Fanatics (Team 2)
-- Captain (Sarah) + 4 members
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(2, 3, 3, '2025-09-25', 1),  -- Sarah (Captain)
(2, 9, 3, '2025-09-25', 1),  -- Sophia
(2, 10, 3, '2025-09-26', 1), -- Benjamin
(2, 11, 3, '2025-09-27', 1), -- Charlotte
(2, 12, 3, '2025-09-28', 1); -- Lucas

-- November Challenge - Thunder Walkers (Team 3)
-- Captain (John) + 5 members
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(3, 2, 2, '2025-10-25', 1),  -- John (Captain)
(3, 5, 2, '2025-10-25', 1),  -- Emma
(3, 7, 2, '2025-10-26', 1),  -- Olivia
(3, 9, 2, '2025-10-26', 1),  -- Sophia
(3, 13, 2, '2025-10-27', 1), -- Amelia
(3, 15, 2, '2025-10-28', 1); -- Mia

-- November Challenge - Lightning Steppers (Team 4)
-- Captain (Sarah) + 3 members
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(4, 3, 3, '2025-10-25', 1),  -- Sarah (Captain)
(4, 6, 3, '2025-10-25', 1),  -- James
(4, 10, 3, '2025-10-26', 1), -- Benjamin
(4, 14, 3, '2025-10-27', 1); -- Henry

-- November Challenge - Hiking Heroes (Team 5)
-- Captain (Mike) + 4 members
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(5, 4, 4, '2025-10-25', 1),  -- Mike (Captain)
(5, 8, 4, '2025-10-25', 1),  -- William
(5, 11, 4, '2025-10-26', 1), -- Charlotte
(5, 12, 4, '2025-10-26', 1), -- Lucas
(5, 16, 4, '2025-10-27', 1); -- Alexander

PRINT 'Team Members seeded: 24 memberships';
GO

-- =============================================
-- 5. Seed Challenge Participants
-- =============================================
PRINT 'Seeding Challenge Participants...';

-- October Challenge participants
INSERT INTO ChallengeParticipants (ChallengeId, UserId, TeamId, DataSharingConsent, ConsentDate, JoinedAt, IsActive)
VALUES
-- Step Warriors
(1, 2, 1, 1, '2025-09-25', '2025-09-25', 1),
(1, 5, 1, 1, '2025-09-25', '2025-09-25', 1),
(1, 6, 1, 1, '2025-09-26', '2025-09-26', 1),
(1, 7, 1, 1, '2025-09-26', '2025-09-26', 1),
(1, 8, 1, 1, '2025-09-27', '2025-09-27', 1),
-- Fitness Fanatics
(1, 3, 2, 1, '2025-09-25', '2025-09-25', 1),
(1, 9, 2, 1, '2025-09-25', '2025-09-25', 1),
(1, 10, 2, 1, '2025-09-26', '2025-09-26', 1),
(1, 11, 2, 1, '2025-09-27', '2025-09-27', 1),
(1, 12, 2, 1, '2025-09-28', '2025-09-28', 1);

-- November Challenge participants
INSERT INTO ChallengeParticipants (ChallengeId, UserId, TeamId, DataSharingConsent, ConsentDate, JoinedAt, IsActive)
VALUES
-- Thunder Walkers
(2, 2, 3, 1, '2025-10-25', '2025-10-25', 1),
(2, 5, 3, 1, '2025-10-25', '2025-10-25', 1),
(2, 7, 3, 1, '2025-10-26', '2025-10-26', 1),
(2, 9, 3, 1, '2025-10-26', '2025-10-26', 1),
(2, 13, 3, 1, '2025-10-27', '2025-10-27', 1),
(2, 15, 3, 1, '2025-10-28', '2025-10-28', 1),
-- Lightning Steppers
(2, 3, 4, 1, '2025-10-25', '2025-10-25', 1),
(2, 6, 4, 1, '2025-10-25', '2025-10-25', 1),
(2, 10, 4, 1, '2025-10-26', '2025-10-26', 1),
(2, 14, 4, 1, '2025-10-27', '2025-10-27', 1),
-- Hiking Heroes
(2, 4, 5, 1, '2025-10-25', '2025-10-25', 1),
(2, 8, 5, 1, '2025-10-25', '2025-10-25', 1),
(2, 11, 5, 1, '2025-10-26', '2025-10-26', 1),
(2, 12, 5, 1, '2025-10-26', '2025-10-26', 1),
(2, 16, 5, 1, '2025-10-27', '2025-10-27', 1);

PRINT 'Challenge Participants seeded: 25 enrollments';
GO

-- =============================================
-- 6. Seed Health Metrics
-- =============================================
PRINT 'Seeding Health Metrics (this may take a moment)...';

-- Seed realistic health data for November challenge (last 10 days)
-- Pattern: Weekdays 6K-10K steps, Weekends 8K-15K steps, some missed days

DECLARE @UserId INT;
DECLARE @BaseDate DATE = '2025-11-01';
DECLARE @DayOffset INT;
DECLARE @Steps INT;
DECLARE @ActiveMinutes INT;
DECLARE @Distance DECIMAL(10,2);

-- Loop through each November participant
DECLARE user_cursor CURSOR FOR
SELECT DISTINCT UserId FROM ChallengeParticipants WHERE ChallengeId = 2;

OPEN user_cursor;
FETCH NEXT FROM user_cursor INTO @UserId;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Generate 10 days of data (Nov 1-10)
    SET @DayOffset = 0;

    WHILE @DayOffset < 10
    BEGIN
        DECLARE @CurrentDate DATE = DATEADD(DAY, @DayOffset, @BaseDate);
        DECLARE @DayOfWeek INT = DATEPART(WEEKDAY, @CurrentDate);

        -- Realistic patterns
        -- Weekend (Sat=7, Sun=1): Higher steps
        IF @DayOfWeek IN (1, 7)
        BEGIN
            SET @Steps = 8000 + (ABS(CHECKSUM(NEWID())) % 7000); -- 8K-15K
            SET @ActiveMinutes = 50 + (ABS(CHECKSUM(NEWID())) % 40); -- 50-90 min
        END
        ELSE
        BEGIN
            -- Weekday: Moderate steps
            SET @Steps = 6000 + (ABS(CHECKSUM(NEWID())) % 4000); -- 6K-10K
            SET @ActiveMinutes = 30 + (ABS(CHECKSUM(NEWID())) % 40); -- 30-70 min
        END

        -- Calculate distance (rough: 0.8 km per 1000 steps)
        SET @Distance = (@Steps * 0.8) / 1000.0;

        -- Randomly skip some days (10% chance)
        IF (ABS(CHECKSUM(NEWID())) % 100) > 10
        BEGIN
            INSERT INTO HealthMetrics (UserId, MetricDate, Steps, ActiveMinutes, DistanceKilometers, Source)
            VALUES (@UserId, @CurrentDate, @Steps, @ActiveMinutes, @Distance, 'Mock');
        END

        SET @DayOffset = @DayOffset + 1;
    END

    -- Update LastSyncDate for user
    UPDATE Users
    SET LastSyncDate = DATEADD(DAY, 9, @BaseDate)
    WHERE UserId = @UserId;

    FETCH NEXT FROM user_cursor INTO @UserId;
END

CLOSE user_cursor;
DEALLOCATE user_cursor;

PRINT 'Health Metrics seeded: ~140 records (15 users × 10 days, with some gaps)';
GO

-- =============================================
-- 7. Compute Daily Summaries for November Challenge
-- =============================================
PRINT 'Computing Daily Summaries...';

INSERT INTO DailySummaries (ChallengeId, UserId, SummaryDate, Steps, ActiveMinutes, DistanceKilometers, CumulativeSteps, CumulativeActiveMinutes, CumulativeDistanceKilometers)
SELECT
    2 AS ChallengeId,
    hm.UserId,
    hm.MetricDate AS SummaryDate,
    hm.Steps,
    hm.ActiveMinutes,
    hm.DistanceKilometers,
    SUM(hm.Steps) OVER (PARTITION BY hm.UserId ORDER BY hm.MetricDate) AS CumulativeSteps,
    SUM(hm.ActiveMinutes) OVER (PARTITION BY hm.UserId ORDER BY hm.MetricDate) AS CumulativeActiveMinutes,
    SUM(hm.DistanceKilometers) OVER (PARTITION BY hm.UserId ORDER BY hm.MetricDate) AS CumulativeDistanceKilometers
FROM HealthMetrics hm
WHERE hm.MetricDate >= '2025-11-01' AND hm.MetricDate <= '2025-11-10'
    AND hm.UserId IN (SELECT UserId FROM ChallengeParticipants WHERE ChallengeId = 2)
ORDER BY hm.UserId, hm.MetricDate;

PRINT 'Daily Summaries computed.';
GO

-- =============================================
-- 8. Compute Leaderboards for November Challenge
-- =============================================
PRINT 'Computing Leaderboards...';

-- Individual Leaderboard
WITH IndividualScores AS (
    SELECT
        cp.UserId,
        SUM(hm.Steps) AS TotalSteps,
        SUM(hm.ActiveMinutes) AS TotalActiveMinutes,
        SUM(hm.DistanceKilometers) AS TotalDistance
    FROM ChallengeParticipants cp
    INNER JOIN HealthMetrics hm ON cp.UserId = hm.UserId
    WHERE cp.ChallengeId = 2
        AND cp.IsActive = 1
        AND hm.MetricDate >= '2025-11-01'
        AND hm.MetricDate <= '2025-11-10'
    GROUP BY cp.UserId
),
RankedIndividuals AS (
    SELECT
        UserId,
        TotalSteps,
        TotalActiveMinutes,
        TotalDistance,
        ROW_NUMBER() OVER (ORDER BY TotalSteps DESC) AS Rank
    FROM IndividualScores
)
INSERT INTO Leaderboards (ChallengeId, LeaderboardType, EntityId, Rank, PrimaryScore, TotalSteps, TotalActiveMinutes, TotalDistanceKilometers)
SELECT
    2 AS ChallengeId,
    'Individual' AS LeaderboardType,
    UserId AS EntityId,
    Rank,
    TotalSteps AS PrimaryScore,
    TotalSteps,
    TotalActiveMinutes,
    TotalDistance
FROM RankedIndividuals;

-- Team Leaderboard (using TeamAverage as per challenge config)
WITH TeamScores AS (
    SELECT
        cp.TeamId,
        COUNT(DISTINCT cp.UserId) AS MemberCount,
        SUM(hm.Steps) AS TeamTotalSteps,
        SUM(hm.ActiveMinutes) AS TeamTotalActiveMinutes,
        SUM(hm.DistanceKilometers) AS TeamTotalDistance,
        AVG(CAST(hm.Steps AS DECIMAL(18,2))) AS TeamAverageSteps
    FROM ChallengeParticipants cp
    INNER JOIN HealthMetrics hm ON cp.UserId = hm.UserId
    WHERE cp.ChallengeId = 2
        AND cp.IsActive = 1
        AND cp.TeamId IS NOT NULL
        AND hm.MetricDate >= '2025-11-01'
        AND hm.MetricDate <= '2025-11-10'
    GROUP BY cp.TeamId
),
RankedTeams AS (
    SELECT
        TeamId,
        MemberCount,
        TeamTotalSteps,
        TeamTotalActiveMinutes,
        TeamTotalDistance,
        TeamAverageSteps,
        ROW_NUMBER() OVER (ORDER BY TeamAverageSteps DESC) AS Rank
    FROM TeamScores
)
INSERT INTO Leaderboards (ChallengeId, LeaderboardType, EntityId, Rank, PrimaryScore, TotalSteps, TotalActiveMinutes, TotalDistanceKilometers, TeamMemberCount, TeamAverageSteps)
SELECT
    2 AS ChallengeId,
    'Team' AS LeaderboardType,
    TeamId AS EntityId,
    Rank,
    TeamAverageSteps AS PrimaryScore,
    TeamTotalSteps,
    TeamTotalActiveMinutes,
    TeamTotalDistance,
    MemberCount,
    TeamAverageSteps
FROM RankedTeams;

PRINT 'Leaderboards computed for November challenge.';
GO

-- =============================================
-- 9. Add Sample Audit Log Entry
-- =============================================
PRINT 'Seeding sample Audit Log...';

INSERT INTO AuditLog (EntityType, EntityId, Action, ChangedBy, ChangedAt, ChangeDescription)
VALUES
('Challenge', 2, 'Create', 1, '2025-10-15 09:30:00', 'November Fitness Challenge created'),
('Team', 3, 'Create', 2, '2025-10-25 14:20:00', 'Thunder Walkers team created'),
('TeamMember', 3, 'Create', 2, '2025-10-27 16:45:00', 'Added Amelia to Thunder Walkers');

PRINT 'Audit Log seeded: 3 entries';
GO

-- =============================================
-- 10. Verification Queries
-- =============================================
PRINT '';
PRINT '========================================';
PRINT 'Seed Data Summary:';
PRINT '========================================';

SELECT 'Users' AS TableName, COUNT(*) AS RecordCount FROM Users
UNION ALL
SELECT 'Challenges', COUNT(*) FROM Challenges
UNION ALL
SELECT 'Teams', COUNT(*) FROM Teams
UNION ALL
SELECT 'TeamMembers', COUNT(*) FROM TeamMembers
UNION ALL
SELECT 'ChallengeParticipants', COUNT(*) FROM ChallengeParticipants
UNION ALL
SELECT 'HealthMetrics', COUNT(*) FROM HealthMetrics
UNION ALL
SELECT 'DailySummaries', COUNT(*) FROM DailySummaries
UNION ALL
SELECT 'Leaderboards', COUNT(*) FROM Leaderboards
UNION ALL
SELECT 'AuditLog', COUNT(*) FROM AuditLog;

PRINT '';
PRINT '========================================';
PRINT 'Test Accounts:';
PRINT '========================================';
PRINT 'Admin:   admin@challengeboards.com / Test123!';
PRINT 'Captain: john.smith@company.com / Test123!';
PRINT 'Captain: sarah.johnson@company.com / Test123!';
PRINT 'User:    emma.brown@company.com / Test123!';
PRINT '';
PRINT 'Seed data population completed successfully!';
PRINT '========================================';
GO
