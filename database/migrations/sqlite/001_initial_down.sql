-- =============================================
-- Migration Rollback: 001_Initial (SQLite)
-- Description: Drop all tables
-- Author: System
-- Date: 2025-11-10
-- WARNING: This will delete all data!
-- =============================================

PRAGMA foreign_keys = OFF;

-- Drop tables in reverse order of dependencies
DROP TABLE IF EXISTS Notifications;
DROP TABLE IF EXISTS AuditLog;
DROP TABLE IF EXISTS Leaderboards;
DROP TABLE IF EXISTS DailySummaries;
DROP TABLE IF EXISTS HealthMetrics;
DROP TABLE IF EXISTS ChallengeParticipants;
DROP TABLE IF EXISTS TeamMembers;
DROP TABLE IF EXISTS Teams;
DROP TABLE IF EXISTS Challenges;
DROP TABLE IF EXISTS Users;

PRAGMA foreign_keys = ON;

SELECT 'Rollback of Migration 001_Initial completed' AS Message;
SELECT 'All tables have been dropped' AS Warning;
