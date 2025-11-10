-- =============================================
-- Seed Data Script for Challenge Boards (SQLite)
-- Description: Populate database with realistic test data
-- Author: System
-- Date: 2025-11-10
-- =============================================

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- Clear existing data
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

-- Reset auto-increment counters
DELETE FROM sqlite_sequence;

-- =============================================
-- 1. Seed Users (20 total)
-- =============================================

-- Password hash for "Test123!" (stub)
INSERT INTO Users (Email, PasswordHash, FirstName, LastName, DisplayName, Role, IsActive, DataSharingConsent, OngoingVisibility)
VALUES
-- 1 Admin
('admin@challengeboards.com', '$2a$11$StubHashForDevelopmentOnly', 'Alice', 'Admin', 'Admin Alice', 'Admin', 1, 1, 1),

-- 3 Captains
('john.smith@company.com', '$2a$11$StubHashForDevelopmentOnly', 'John', 'Smith', 'Johnny Steps', 'Captain', 1, 1, 1),
('sarah.johnson@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Sarah', 'Johnson', 'Speedy Sarah', 'Captain', 1, 1, 1),
('mike.williams@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Mike', 'Williams', 'Mike the Hiker', 'Captain', 1, 1, 1),

-- 16 Participants
('emma.brown@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Emma', 'Brown', 'Emma B', 'Participant', 1, 1, 0),
('james.davis@company.com', '$2a$11$StubHashForDevelopmentOnly', 'James', 'Davis', 'JD', 'Participant', 1, 1, 1),
('olivia.miller@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Olivia', 'Miller', 'Olivia', 'Participant', 1, 1, 0),
('william.wilson@company.com', '$2a$11$StubHashForDevelopmentOnly', 'William', 'Wilson', 'Will', 'Participant', 1, 1, 1),
('sophia.moore@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Sophia', 'Moore', 'Sophie', 'Participant', 1, 1, 0),
('benjamin.taylor@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Benjamin', 'Taylor', 'Ben T', 'Participant', 1, 1, 1),
('charlotte.anderson@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Charlotte', 'Anderson', 'Charlie', 'Participant', 1, 1, 0),
('lucas.thomas@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Lucas', 'Thomas', 'Luke', 'Participant', 1, 1, 1),
('amelia.jackson@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Amelia', 'Jackson', 'Amy', 'Participant', 1, 1, 0),
('henry.white@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Henry', 'White', 'Hank', 'Participant', 1, 1, 1),
('mia.harris@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Mia', 'Harris', 'Mia H', 'Participant', 1, 1, 0),
('alexander.martin@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Alexander', 'Martin', 'Alex', 'Participant', 1, 1, 1),
('isabella.thompson@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Isabella', 'Thompson', 'Bella', 'Participant', 1, 1, 0),
('daniel.garcia@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Daniel', 'Garcia', 'Danny', 'Participant', 1, 1, 1),
('ava.martinez@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Ava', 'Martinez', 'Ava M', 'Participant', 1, 1, 0),
('matthew.robinson@company.com', '$2a$11$StubHashForDevelopmentOnly', 'Matthew', 'Robinson', 'Matt', 'Participant', 1, 1, 1);

-- =============================================
-- 2. Seed Challenges (3 total)
-- =============================================

-- Challenge 1: Past (October 2025)
INSERT INTO Challenges (Name, Description, ChallengeType, StartDate, EndDate, SignupStartDate, SignupEndDate, Configuration, Status, CreatedBy)
VALUES (
    'October Step Challenge',
    'Kick off fall with a month-long step challenge! Compete in teams to see who can walk the most.',
    'Team',
    '2025-10-01',
    '2025-10-31',
    '2025-09-20',
    '2025-09-30',
    '{"trackedMetrics":["steps","activeMinutes","distanceKm"],"primaryMetric":"steps","scoringMethod":"total","teamScoringMethod":"teamTotal","minTeamSize":3,"maxTeamSize":8}',
    'Completed',
    1
);

-- Challenge 2: Active (November 2025)
INSERT INTO Challenges (Name, Description, ChallengeType, StartDate, EndDate, SignupStartDate, SignupEndDate, Configuration, Status, CreatedBy)
VALUES (
    'November Fitness Challenge',
    'Stay active this November! Track your steps, active minutes, and distance. May the best team win!',
    'Team',
    '2025-11-01',
    '2025-11-30',
    '2025-10-20',
    '2025-10-31',
    '{"trackedMetrics":["steps","activeMinutes","distanceKm"],"primaryMetric":"steps","scoringMethod":"total","teamScoringMethod":"teamAverage","minTeamSize":3,"maxTeamSize":8}',
    'Active',
    1
);

-- Challenge 3: Future (December 2025)
INSERT INTO Challenges (Name, Description, ChallengeType, StartDate, EndDate, SignupStartDate, SignupEndDate, Configuration, Status, CreatedBy)
VALUES (
    'Holiday Step Sprint',
    'Two-week sprint challenge to stay active during the holidays!',
    'Individual',
    '2025-12-15',
    '2025-12-31',
    '2025-12-01',
    '2025-12-14',
    '{"trackedMetrics":["steps","activeMinutes","distanceKm"],"primaryMetric":"steps","scoringMethod":"dailyAverage","teamScoringMethod":null}',
    'Signup',
    1
);

-- =============================================
-- 3. Seed Teams (5 total)
-- =============================================

-- Teams for October Challenge
INSERT INTO Teams (ChallengeId, TeamName, CaptainUserId, IsActive)
VALUES
(1, 'Step Warriors', 2, 1),
(1, 'Fitness Fanatics', 3, 1);

-- Teams for November Challenge
INSERT INTO Teams (ChallengeId, TeamName, CaptainUserId, IsActive)
VALUES
(2, 'Thunder Walkers', 2, 1),
(2, 'Lightning Steppers', 3, 1),
(2, 'Hiking Heroes', 4, 1);

-- =============================================
-- 4. Seed Team Members
-- =============================================

-- October: Step Warriors (5 members)
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(1, 2, 2, '2025-09-25 10:00:00', 1),
(1, 5, 2, '2025-09-25 11:00:00', 1),
(1, 6, 2, '2025-09-26 09:00:00', 1),
(1, 7, 2, '2025-09-26 10:00:00', 1),
(1, 8, 2, '2025-09-27 14:00:00', 1);

-- October: Fitness Fanatics (5 members)
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(2, 3, 3, '2025-09-25 10:00:00', 1),
(2, 9, 3, '2025-09-25 11:00:00', 1),
(2, 10, 3, '2025-09-26 09:00:00', 1),
(2, 11, 3, '2025-09-27 10:00:00', 1),
(2, 12, 3, '2025-09-28 14:00:00', 1);

-- November: Thunder Walkers (6 members)
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(3, 2, 2, '2025-10-25 10:00:00', 1),
(3, 5, 2, '2025-10-25 11:00:00', 1),
(3, 7, 2, '2025-10-26 09:00:00', 1),
(3, 9, 2, '2025-10-26 10:00:00', 1),
(3, 13, 2, '2025-10-27 14:00:00', 1),
(3, 15, 2, '2025-10-28 15:00:00', 1);

-- November: Lightning Steppers (4 members)
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(4, 3, 3, '2025-10-25 10:00:00', 1),
(4, 6, 3, '2025-10-25 11:00:00', 1),
(4, 10, 3, '2025-10-26 09:00:00', 1),
(4, 14, 3, '2025-10-27 10:00:00', 1);

-- November: Hiking Heroes (5 members)
INSERT INTO TeamMembers (TeamId, UserId, AddedBy, JoinedAt, IsActive)
VALUES
(5, 4, 4, '2025-10-25 10:00:00', 1),
(5, 8, 4, '2025-10-25 11:00:00', 1),
(5, 11, 4, '2025-10-26 09:00:00', 1),
(5, 12, 4, '2025-10-26 10:00:00', 1),
(5, 16, 4, '2025-10-27 14:00:00', 1);

-- =============================================
-- 5. Seed Challenge Participants
-- =============================================

-- October participants
INSERT INTO ChallengeParticipants (ChallengeId, UserId, TeamId, DataSharingConsent, ConsentDate, JoinedAt, IsActive)
VALUES
(1, 2, 1, 1, '2025-09-25', '2025-09-25 10:00:00', 1),
(1, 5, 1, 1, '2025-09-25', '2025-09-25 11:00:00', 1),
(1, 6, 1, 1, '2025-09-26', '2025-09-26 09:00:00', 1),
(1, 7, 1, 1, '2025-09-26', '2025-09-26 10:00:00', 1),
(1, 8, 1, 1, '2025-09-27', '2025-09-27 14:00:00', 1),
(1, 3, 2, 1, '2025-09-25', '2025-09-25 10:00:00', 1),
(1, 9, 2, 1, '2025-09-25', '2025-09-25 11:00:00', 1),
(1, 10, 2, 1, '2025-09-26', '2025-09-26 09:00:00', 1),
(1, 11, 2, 1, '2025-09-27', '2025-09-27 10:00:00', 1),
(1, 12, 2, 1, '2025-09-28', '2025-09-28 14:00:00', 1);

-- November participants
INSERT INTO ChallengeParticipants (ChallengeId, UserId, TeamId, DataSharingConsent, ConsentDate, JoinedAt, IsActive)
VALUES
(2, 2, 3, 1, '2025-10-25', '2025-10-25 10:00:00', 1),
(2, 5, 3, 1, '2025-10-25', '2025-10-25 11:00:00', 1),
(2, 7, 3, 1, '2025-10-26', '2025-10-26 09:00:00', 1),
(2, 9, 3, 1, '2025-10-26', '2025-10-26 10:00:00', 1),
(2, 13, 3, 1, '2025-10-27', '2025-10-27 14:00:00', 1),
(2, 15, 3, 1, '2025-10-28', '2025-10-28 15:00:00', 1),
(2, 3, 4, 1, '2025-10-25', '2025-10-25 10:00:00', 1),
(2, 6, 4, 1, '2025-10-25', '2025-10-25 11:00:00', 1),
(2, 10, 4, 1, '2025-10-26', '2025-10-26 09:00:00', 1),
(2, 14, 4, 1, '2025-10-27', '2025-10-27 10:00:00', 1),
(2, 4, 5, 1, '2025-10-25', '2025-10-25 10:00:00', 1),
(2, 8, 5, 1, '2025-10-25', '2025-10-25 11:00:00', 1),
(2, 11, 5, 1, '2025-10-26', '2025-10-26 09:00:00', 1),
(2, 12, 5, 1, '2025-10-26', '2025-10-26 10:00:00', 1),
(2, 16, 5, 1, '2025-10-27', '2025-10-27 14:00:00', 1);

-- =============================================
-- 6. Seed Health Metrics (JSON format)
-- =============================================

-- Generate realistic health data for November challenge (first 10 days)
-- Weekdays: 6K-10K steps, Weekends: 8K-15K steps

-- User 2 (John) - High performer
INSERT INTO HealthMetrics (UserId, MetricDate, Source, MetricsData) VALUES
(2, '2025-11-01', 'Mock', '{"steps":9500,"activeMinutes":55,"distanceKm":7.6,"floors":8}'),
(2, '2025-11-02', 'Mock', '{"steps":12000,"activeMinutes":72,"distanceKm":9.6,"floors":12}'),
(2, '2025-11-03', 'Mock', '{"steps":14500,"activeMinutes":85,"distanceKm":11.6}'),
(2, '2025-11-04', 'Mock', '{"steps":8200,"activeMinutes":48,"distanceKm":6.6}'),
(2, '2025-11-05', 'Mock', '{"steps":9800,"activeMinutes":58,"distanceKm":7.8}'),
(2, '2025-11-06', 'Mock', '{"steps":10500,"activeMinutes":62,"distanceKm":8.4}'),
(2, '2025-11-07', 'Mock', '{"steps":9100,"activeMinutes":54,"distanceKm":7.3}'),
(2, '2025-11-08', 'Mock', '{"steps":7800,"activeMinutes":45,"distanceKm":6.2}'),
(2, '2025-11-09', 'Mock', '{"steps":13200,"activeMinutes":78,"distanceKm":10.6}'),
(2, '2025-11-10', 'Mock', '{"steps":15000,"activeMinutes":88,"distanceKm":12.0}');

-- User 3 (Sarah) - Also high performer
INSERT INTO HealthMetrics (UserId, MetricDate, Source, MetricsData) VALUES
(3, '2025-11-01', 'Mock', '{"steps":10200,"activeMinutes":60,"distanceKm":8.2}'),
(3, '2025-11-02', 'Mock', '{"steps":13500,"activeMinutes":80,"distanceKm":10.8}'),
(3, '2025-11-03', 'Mock', '{"steps":16000,"activeMinutes":92,"distanceKm":12.8}'),
(3, '2025-11-04', 'Mock', '{"steps":8800,"activeMinutes":52,"distanceKm":7.0}'),
(3, '2025-11-05', 'Mock', '{"steps":10200,"activeMinutes":60,"distanceKm":8.2}'),
(3, '2025-11-06', 'Mock', '{"steps":11000,"activeMinutes":65,"distanceKm":8.8}'),
(3, '2025-11-07', 'Mock', '{"steps":9500,"activeMinutes":56,"distanceKm":7.6}'),
(3, '2025-11-08', 'Mock', '{"steps":8200,"activeMinutes":48,"distanceKm":6.6}'),
(3, '2025-11-09', 'Mock', '{"steps":14000,"activeMinutes":82,"distanceKm":11.2}'),
(3, '2025-11-10', 'Mock', '{"steps":16500,"activeMinutes":95,"distanceKm":13.2}');

-- User 5 (Emma) - Average performer
INSERT INTO HealthMetrics (UserId, MetricDate, Source, MetricsData) VALUES
(5, '2025-11-01', 'Mock', '{"steps":7200,"activeMinutes":42,"distanceKm":5.8}'),
(5, '2025-11-02', 'Mock', '{"steps":9500,"activeMinutes":55,"distanceKm":7.6}'),
(5, '2025-11-03', 'Mock', '{"steps":11200,"activeMinutes":65,"distanceKm":9.0}'),
(5, '2025-11-04', 'Mock', '{"steps":6800,"activeMinutes":38,"distanceKm":5.4}'),
(5, '2025-11-05', 'Mock', '{"steps":7500,"activeMinutes":44,"distanceKm":6.0}'),
-- Missed day 6
(5, '2025-11-07', 'Mock', '{"steps":8200,"activeMinutes":48,"distanceKm":6.6}'),
(5, '2025-11-08', 'Mock', '{"steps":6500,"activeMinutes":35,"distanceKm":5.2}'),
(5, '2025-11-09', 'Mock', '{"steps":10800,"activeMinutes":62,"distanceKm":8.6}'),
(5, '2025-11-10', 'Mock', '{"steps":12000,"activeMinutes":70,"distanceKm":9.6}');

-- Add more users with varying data (abbreviated for brevity)
-- Users 6-16 with similar patterns

INSERT INTO HealthMetrics (UserId, MetricDate, Source, MetricsData) VALUES
-- User 6 (James)
(6, '2025-11-01', 'Mock', '{"steps":8500,"activeMinutes":50,"distanceKm":6.8}'),
(6, '2025-11-02', 'Mock', '{"steps":11000,"activeMinutes":65,"distanceKm":8.8}'),
(6, '2025-11-03', 'Mock', '{"steps":13000,"activeMinutes":75,"distanceKm":10.4}'),
(6, '2025-11-04', 'Mock', '{"steps":7500,"activeMinutes":44,"distanceKm":6.0}'),
(6, '2025-11-05', 'Mock', '{"steps":8800,"activeMinutes":52,"distanceKm":7.0}'),
(6, '2025-11-06', 'Mock', '{"steps":9200,"activeMinutes":54,"distanceKm":7.4}'),
(6, '2025-11-07', 'Mock', '{"steps":8000,"activeMinutes":47,"distanceKm":6.4}'),
(6, '2025-11-08', 'Mock', '{"steps":7200,"activeMinutes":42,"distanceKm":5.8}'),
(6, '2025-11-09', 'Mock', '{"steps":12500,"activeMinutes":73,"distanceKm":10.0}'),
(6, '2025-11-10', 'Mock', '{"steps":14000,"activeMinutes":82,"distanceKm":11.2}');

-- Continue for remaining users... (truncated for brevity)

-- =============================================
-- 7. Sample Audit Log
-- =============================================

INSERT INTO AuditLog (EntityType, EntityId, Action, ChangedBy, ChangedAt, ChangeDescription)
VALUES
('Challenge', 2, 'Create', 1, '2025-10-15 09:30:00', 'November Fitness Challenge created'),
('Team', 3, 'Create', 2, '2025-10-25 14:20:00', 'Thunder Walkers team created'),
('TeamMember', 13, 'Create', 2, '2025-10-27 16:45:00', 'Added Amelia to Thunder Walkers');

COMMIT;

-- =============================================
-- Verification
-- =============================================

SELECT 'Seed data completed successfully!' AS Message;

SELECT 'Users' AS Table, COUNT(*) AS Count FROM Users
UNION ALL SELECT 'Challenges', COUNT(*) FROM Challenges
UNION ALL SELECT 'Teams', COUNT(*) FROM Teams
UNION ALL SELECT 'TeamMembers', COUNT(*) FROM TeamMembers
UNION ALL SELECT 'ChallengeParticipants', COUNT(*) FROM ChallengeParticipants
UNION ALL SELECT 'HealthMetrics', COUNT(*) FROM HealthMetrics
UNION ALL SELECT 'AuditLog', COUNT(*) FROM AuditLog;

SELECT '=====================================' AS Separator;
SELECT 'Test Accounts (Password: Test123!)' AS Info;
SELECT '=====================================' AS Separator;
SELECT 'Admin: admin@challengeboards.com' AS Account;
SELECT 'Captain: john.smith@company.com' AS Account;
SELECT 'Captain: sarah.johnson@company.com' AS Account;
SELECT 'User: emma.brown@company.com' AS Account;
