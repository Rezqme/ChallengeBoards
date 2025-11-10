-- =============================================
-- Migration Rollback: 001_InitialSchema
-- Description: Drop all tables created in initial schema
-- Author: System
-- Date: 2025-11-10
-- WARNING: This will delete all data!
-- =============================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Starting rollback of Migration 001_InitialSchema...';
PRINT 'WARNING: This will delete all data in the database!';
GO

-- =============================================
-- Drop tables in reverse order of dependencies
-- =============================================

-- Drop dependent tables first
IF OBJECT_ID('dbo.Notifications', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping Notifications table...';
    DROP TABLE dbo.Notifications;
    PRINT 'Notifications table dropped.';
END
GO

IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping AuditLog table...';
    DROP TABLE dbo.AuditLog;
    PRINT 'AuditLog table dropped.';
END
GO

IF OBJECT_ID('dbo.Leaderboards', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping Leaderboards table...';
    DROP TABLE dbo.Leaderboards;
    PRINT 'Leaderboards table dropped.';
END
GO

IF OBJECT_ID('dbo.DailySummaries', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping DailySummaries table...';
    DROP TABLE dbo.DailySummaries;
    PRINT 'DailySummaries table dropped.';
END
GO

IF OBJECT_ID('dbo.HealthMetrics', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping HealthMetrics table...';
    DROP TABLE dbo.HealthMetrics;
    PRINT 'HealthMetrics table dropped.';
END
GO

IF OBJECT_ID('dbo.ChallengeParticipants', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping ChallengeParticipants table...';
    DROP TABLE dbo.ChallengeParticipants;
    PRINT 'ChallengeParticipants table dropped.';
END
GO

IF OBJECT_ID('dbo.TeamMembers', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping TeamMembers table...';
    DROP TABLE dbo.TeamMembers;
    PRINT 'TeamMembers table dropped.';
END
GO

IF OBJECT_ID('dbo.Teams', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping Teams table...';
    DROP TABLE dbo.Teams;
    PRINT 'Teams table dropped.';
END
GO

IF OBJECT_ID('dbo.Challenges', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping Challenges table...';
    DROP TABLE dbo.Challenges;
    PRINT 'Challenges table dropped.';
END
GO

IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
BEGIN
    PRINT 'Dropping Users table...';
    DROP TABLE dbo.Users;
    PRINT 'Users table dropped.';
END
GO

-- =============================================
-- Rollback Complete
-- =============================================
PRINT 'Rollback of Migration 001_InitialSchema completed successfully!';
PRINT 'All tables have been dropped.';
GO
