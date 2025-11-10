# Challenge Boards - Development Plan
**Version:** 1.0
**Date:** November 10, 2025
**Goal:** Get a working application running locally before full cloud integration

---

## Philosophy: Build Core, Stub Peripherals

**Approach:**
1. Build real business logic (challenges, teams, leaderboards, scoring)
2. Stub external integrations (Azure services, mobile sync, email)
3. Use local infrastructure (SQL Server, local auth, in-memory cache)
4. Track all stubs for later implementation
5. Get end-to-end flow working ASAP

---

## Development Environment Setup

### Local Infrastructure
- **Database:** SQL Server LocalDB or Docker SQL Server
- **Backend:** ASP.NET Core Web API running on localhost:5000
- **Frontend:** React dev server on localhost:3000
- **Cache:** In-memory cache (stub for Redis)
- **Auth:** Simple JWT with hardcoded users (stub for Azure AD)
- **Email:** Console output / file logging (stub for SendGrid)

### Prerequisites
- .NET 8 SDK
- Node.js 18+
- SQL Server LocalDB or Docker
- Visual Studio Code or Visual Studio 2022
- Git

---

## Stub Registry

Track everything that's stubbed and needs real implementation later:

| Component | Stub Implementation | Production Implementation | Phase |
|-----------|-------------------|--------------------------|-------|
| **Authentication** | JWT with in-memory user store | Azure AD B2C or custom auth | Phase 4 |
| **Database** | SQL Server LocalDB | Azure SQL Database | Phase 4 |
| **Cache** | In-memory IMemoryCache | Azure Redis Cache | Phase 4 |
| **Email** | Console logging | SendGrid / Azure Communication Services | Phase 3 |
| **Blob Storage** | Local file system | Azure Blob Storage | Phase 3 |
| **Mobile Health Sync** | Mock data seeding API | HealthKit / Google Fit integration | Phase 5 |
| **Real-time Updates** | Polling (every 30s) | Azure SignalR Service | Phase 4 |
| **Background Jobs** | In-process background service | Azure Functions | Phase 4 |
| **Application Insights** | Console logging | Azure Application Insights | Phase 4 |
| **Key Vault** | appsettings.json | Azure Key Vault | Phase 4 |

---

## Phase 1: Foundation & Database (Week 1)

### Goals
- Database schema designed and implemented
- Migrations set up
- Seed data for development

### Deliverables

#### 1.1 Database Schema
**Tables to create:**
- `Users` - User accounts
- `Challenges` - Challenge definitions
- `Teams` - Team information
- `TeamMembers` - Many-to-many relationship
- `ChallengeParticipants` - Who's in each challenge
- `HealthMetrics` - Time-series health data
- `Leaderboards` - Computed rankings (materialized view)
- `AuditLog` - Change tracking

**Schema File:** `database/schema.sql`

#### 1.2 Entity Framework Core Setup
- Create domain models
- Configure DbContext
- Set up migrations
- Create seed data script

#### 1.3 Seed Data
Create realistic test data:
- 20 users (5 admins, 15 participants)
- 3 challenges (1 past, 1 active, 1 upcoming)
- 5 teams with varying sizes
- Health metrics for last 30 days

### Success Criteria
- [ ] Can create database locally
- [ ] Can run migrations
- [ ] Can seed test data
- [ ] Can query all tables successfully

---

## Phase 2: Backend API Core (Week 2)

### Goals
- ASP.NET Core Web API project structure
- Core CRUD endpoints working
- Stubbed authentication
- Repository pattern implemented

### Deliverables

#### 2.1 Project Structure
```
ChallengeBoards.API/
├── Controllers/
├── Models/
│   ├── Entities/      # EF Core entities
│   ├── DTOs/          # API request/response models
│   └── ViewModels/    # Computed data models
├── Services/
│   ├── Interfaces/
│   └── Implementations/
├── Repositories/
│   ├── Interfaces/
│   └── Implementations/
├── Data/
│   ├── ChallengeDbContext.cs
│   └── Migrations/
├── Middleware/
├── Configuration/
└── Program.cs
```

#### 2.2 API Endpoints (Priority Order)

**Week 2 - Core Endpoints:**
1. **Auth (Stubbed)**
   - `POST /api/auth/login` - Returns JWT for test users
   - `GET /api/auth/me` - Returns current user info

2. **Users**
   - `GET /api/users` - List users (admin only)
   - `GET /api/users/{id}` - Get user details
   - `PUT /api/users/{id}` - Update user profile

3. **Challenges**
   - `GET /api/challenges` - List all challenges
   - `GET /api/challenges/{id}` - Get challenge details
   - `POST /api/challenges` - Create challenge (admin)
   - `PUT /api/challenges/{id}` - Update challenge (admin)
   - `DELETE /api/challenges/{id}` - Delete challenge (admin)

4. **Teams**
   - `GET /api/challenges/{challengeId}/teams` - List teams for challenge
   - `POST /api/challenges/{challengeId}/teams` - Create team
   - `PUT /api/teams/{id}` - Update team
   - `POST /api/teams/{id}/members` - Add team member
   - `DELETE /api/teams/{id}/members/{userId}` - Remove member

5. **Participants**
   - `POST /api/challenges/{id}/join` - Join challenge
   - `DELETE /api/challenges/{id}/leave` - Leave challenge
   - `GET /api/challenges/{id}/participants` - List participants

#### 2.3 Stub Implementations

**Authentication Middleware:**
```csharp
// Hardcoded test users
public class StubAuthService
{
    private readonly List<User> _testUsers = new()
    {
        new User { Id = 1, Email = "admin@test.com", Role = "Admin" },
        new User { Id = 2, Email = "captain@test.com", Role = "Captain" },
        new User { Id = 3, Email = "user@test.com", Role = "Participant" }
    };

    public string GenerateJwtToken(User user)
    {
        // Simple JWT generation
        // TODO: Replace with Azure AD in Phase 4
    }
}
```

**Email Service Stub:**
```csharp
public class StubEmailService : IEmailService
{
    private readonly ILogger<StubEmailService> _logger;

    public Task SendEmailAsync(string to, string subject, string body)
    {
        _logger.LogInformation($"[EMAIL STUB] To: {to}, Subject: {subject}");
        // TODO: Replace with SendGrid in Phase 3
        return Task.CompletedTask;
    }
}
```

### Success Criteria
- [ ] All CRUD endpoints return 200 OK
- [ ] Can authenticate with stub JWT
- [ ] Can create challenge via API
- [ ] Can create team and add members
- [ ] Swagger UI working (https://localhost:5000/swagger)

---

## Phase 3: Health Data & Leaderboards (Week 3)

### Goals
- Health metrics ingestion API
- Leaderboard computation logic
- Mock mobile sync endpoint
- Scoring algorithms implemented

### Deliverables

#### 3.1 Health Data Endpoints

1. **Mock Sync Endpoint (Stub for Mobile App)**
   ```
   POST /api/health/sync
   Body: {
     "userId": 1,
     "metrics": [
       { "date": "2025-11-01", "steps": 8500, "activeMinutes": 45, "distance": 4.2 },
       { "date": "2025-11-02", "steps": 10200, "activeMinutes": 60, "distance": 5.1 }
     ]
   }
   ```
   - Accepts bulk health data
   - Validates date ranges
   - Prevents duplicate entries
   - Returns sync status

2. **Manual Entry Endpoint**
   ```
   POST /api/health/entry
   Body: { "date": "2025-11-10", "steps": 7500 }
   ```
   - For manual data entry during development
   - Single day entry

3. **Query Endpoints**
   ```
   GET /api/health/{userId}?startDate=2025-11-01&endDate=2025-11-10
   GET /api/health/{userId}/summary?period=week
   ```

#### 3.2 Leaderboard Logic

**Service: `LeaderboardService.cs`**
- Compute individual rankings
- Compute team rankings
- Support multiple scoring methods:
  - Total accumulation
  - Daily average
  - Team average vs. team total
- Cache results (in-memory for now)

**Endpoints:**
```
GET /api/challenges/{id}/leaderboard?type=individual
GET /api/challenges/{id}/leaderboard?type=team
GET /api/challenges/{id}/leaderboard/{userId}/position
```

#### 3.3 Background Job: Daily Leaderboard Refresh

Create `LeaderboardComputeService` (hosted service):
- Runs every 5 minutes (configurable)
- Recomputes all active challenge leaderboards
- Stores in `Leaderboards` table
- TODO: Move to Azure Functions in Phase 4

#### 3.4 Mock Data Generator

Create utility to generate realistic health data:
```csharp
public class MockHealthDataGenerator
{
    public List<HealthMetric> GenerateForUser(int userId, DateRange range)
    {
        // Realistic step counts (4000-15000 steps/day)
        // Realistic active minutes (20-90 min/day)
        // Some days with zero (simulates missed days)
        // Weekend patterns (higher steps)
    }
}
```

### Success Criteria
- [ ] Can POST health data via API
- [ ] Leaderboard computes correctly
- [ ] Individual and team rankings work
- [ ] Background job updates leaderboards automatically
- [ ] Mock data generator creates realistic test data

---

## Phase 4: Frontend Core (Week 4)

### Goals
- React app structure
- Authentication flow
- Dashboard layout
- Challenge list and detail views

### Deliverables

#### 4.1 Project Setup
```
challenge-boards-web/
├── public/
├── src/
│   ├── components/
│   │   ├── layout/
│   │   ├── challenges/
│   │   ├── teams/
│   │   └── common/
│   ├── pages/
│   │   ├── LoginPage.tsx
│   │   ├── DashboardPage.tsx
│   │   ├── ChallengePage.tsx
│   │   └── LeaderboardPage.tsx
│   ├── services/
│   │   └── api.ts
│   ├── hooks/
│   ├── contexts/
│   │   └── AuthContext.tsx
│   ├── types/
│   └── utils/
├── package.json
└── tsconfig.json
```

**Tech Stack:**
- React 18 + TypeScript
- React Router v6
- Axios for API calls
- React Query for data fetching
- Material-UI or Tailwind CSS
- Chart.js or Recharts

#### 4.2 Pages to Build (Priority Order)

**Week 4 - Essential Pages:**

1. **Login Page** (Stub Auth)
   - Email/password form
   - Calls `/api/auth/login`
   - Stores JWT in localStorage
   - Redirects to dashboard

2. **Dashboard Page**
   - Shows active challenges
   - User's current ranking
   - Quick stats (today's steps, weekly total)
   - Links to challenges

3. **Challenge List Page**
   - Shows all challenges (past, active, upcoming)
   - Filter by status
   - "Join Challenge" button

4. **Challenge Detail Page**
   - Challenge info (dates, rules, description)
   - Leaderboard tabs (Individual / Team)
   - Current user's position
   - Team roster (if in team)

5. **Leaderboard Component**
   - Table view with rankings
   - Shows: Rank, Name, Steps, Active Minutes, Distance
   - Highlight current user
   - Sortable columns

#### 4.3 Stub Components

**Data Entry Form** (temporary):
```tsx
// For testing before mobile app
<HealthDataEntryForm
  userId={currentUser.id}
  onSubmit={(data) => api.submitHealthData(data)}
/>
```

**Mock Sync Button:**
```tsx
// Simulates mobile app sync
<Button onClick={() => mockSyncService.generateTodayData()}>
  Simulate Mobile Sync
</Button>
```

### Success Criteria
- [ ] Can log in with test account
- [ ] Dashboard shows active challenges
- [ ] Can view challenge details
- [ ] Leaderboard displays correctly
- [ ] Can manually enter health data (temp UI)
- [ ] Responsive design works on mobile

---

## Phase 5: Team Management (Week 5)

### Goals
- Team creation flow
- Team captain capabilities
- Admin team management
- Team detail view

### Deliverables

#### 5.1 Backend Enhancements
- Team captain authorization logic
- Admin override endpoints
- Team member invitation (email stub)

#### 5.2 Frontend Pages

1. **Create Team Flow**
   - Team name entry
   - Member search/selection
   - Invite via email (stubbed)
   - Submit roster

2. **Team Detail Page**
   - Team name and members
   - Team stats
   - Team leaderboard position
   - Member contribution breakdown

3. **Admin Team Management**
   - View all teams
   - Reassign members
   - Split/merge teams
   - Audit trail

### Success Criteria
- [ ] Captain can create team
- [ ] Can add/remove members
- [ ] Team shows in leaderboard
- [ ] Admin can modify any team

---

## Phase 6: Admin Features (Week 6)

### Goals
- Challenge creation UI
- Admin dashboard
- Basic reporting
- CSV export (local file system)

### Deliverables

#### 6.1 Challenge Creation Form
- Multi-step wizard
- Challenge configuration
- Rules and scoring setup
- Preview before publishing

#### 6.2 Admin Dashboard
- Active challenges overview
- Participation rates
- Data sync status (stub - shows "synced")
- Engagement metrics

#### 6.3 Reporting & Export
- Challenge summary report
- CSV export to local file system
- TODO: Replace with Azure Blob Storage in Phase 7

### Success Criteria
- [ ] Admin can create challenge via UI
- [ ] Dashboard shows key metrics
- [ ] Can export data to CSV

---

## Phase 7: Polish & Testing (Week 7)

### Goals
- Error handling
- Loading states
- Form validation
- Unit tests for critical logic
- Integration tests

### Deliverables

#### 7.1 Error Handling
- API error messages
- Toast notifications
- Friendly error pages
- Retry logic

#### 7.2 Testing
- Backend unit tests (XUnit)
  - Leaderboard computation
  - Scoring algorithms
  - Team management logic
- Frontend tests (Jest + React Testing Library)
  - Component rendering
  - User interactions
- Integration tests
  - End-to-end API flows

#### 7.3 Performance
- Database query optimization
- API response time profiling
- Frontend bundle size optimization

### Success Criteria
- [ ] All critical paths have tests
- [ ] Error states handled gracefully
- [ ] App feels responsive and polished

---

## Phase 8: Cloud Preparation (Week 8)

### Goals
- Prepare for Azure deployment
- Abstract stubbed services
- Configuration management
- CI/CD pipeline

### Deliverables

#### 8.1 Service Abstractions
Ensure all stubbed services use interfaces:
```csharp
public interface IEmailService { }
public interface ICacheService { }
public interface IStorageService { }
public interface IHealthSyncService { }
```

Implementations:
- `StubEmailService` → `SendGridEmailService`
- `InMemoryCacheService` → `RedisCacheService`
- `LocalFileStorageService` → `BlobStorageService`

#### 8.2 Configuration
- Environment-based appsettings
- Connection string management
- Feature flags for stub vs. real services

#### 8.3 Deployment Checklist
- [ ] Backend deployed to Azure App Service
- [ ] Frontend deployed to Azure Static Web Apps
- [ ] Database migrated to Azure SQL
- [ ] Environment variables configured
- [ ] Health check endpoints working

---

## Phase 9: Mobile App Stub (Week 9)

### Goals
- Create mock mobile app UI
- Demonstrate sync flow
- Test authentication from mobile

### Deliverables

#### 9.1 Mock Mobile App (.NET MAUI)
Simple app with:
- Login screen
- "Sync Health Data" button
- Calls mock sync API with generated data
- Shows last sync timestamp

**Note:** Does NOT integrate with HealthKit/Google Fit yet. Just proves the API flow works.

#### 9.2 Mobile API Testing
- Test authentication from mobile
- Test bulk data ingestion
- Test error handling

### Success Criteria
- [ ] Mobile app compiles and runs
- [ ] Can authenticate
- [ ] "Sync" button sends data to API
- [ ] Leaderboard updates after sync

---

## Phase 10: Real Integrations (Weeks 10-12)

**Now replace stubs with real implementations:**

### Week 10: Azure Services
- Deploy to Azure
- Configure Azure SQL Database
- Set up Redis Cache
- Configure SendGrid email
- Set up Blob Storage
- Configure Azure AD authentication

### Week 11: Mobile Health Integration
- Implement HealthKit (iOS)
- Implement Google Fit (Android)
- Background sync logic
- Handle permissions

### Week 12: Polish & Launch Prep
- Real email notifications
- SignalR for real-time updates
- Azure Functions for background jobs
- Application Insights monitoring
- Security hardening
- Load testing

---

## Development Standards

### Code Standards
- Follow C# coding conventions
- Use async/await consistently
- Implement repository pattern
- Use DTOs for API boundaries
- Validate all inputs

### Git Workflow
- Feature branches: `feature/{name}`
- Commit frequently with clear messages
- PR reviews before merging
- Keep main branch deployable

### Documentation
- XML comments for public APIs
- README per project
- API documentation (Swagger)
- Architecture decision records (ADRs)

---

## Testing Strategy

### Unit Tests
- All business logic services
- Leaderboard computation
- Scoring algorithms
- Data validation

### Integration Tests
- API endpoint flows
- Database operations
- Authentication flows

### Manual Testing Checklist
- [ ] User can sign up and join challenge
- [ ] Team captain can create team
- [ ] Health data syncs correctly
- [ ] Leaderboards compute accurately
- [ ] Admin can create and manage challenges
- [ ] Email notifications work (stub logs for now)
- [ ] App works on mobile browsers

---

## Progress Tracking

### Weekly Goals
- **Week 1:** Database schema and seed data ✓
- **Week 2:** Core API endpoints ✓
- **Week 3:** Health data and leaderboards ✓
- **Week 4:** Frontend core ✓
- **Week 5:** Team management ✓
- **Week 6:** Admin features ✓
- **Week 7:** Polish and testing ✓
- **Week 8:** Cloud preparation ✓
- **Week 9:** Mobile stub ✓
- **Week 10-12:** Real integrations ✓

### Definition of Done
A feature is "done" when:
- [ ] Code is written and reviewed
- [ ] Unit tests pass
- [ ] API documented
- [ ] Manually tested
- [ ] Merged to main
- [ ] Deployed to dev environment

---

## Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| Leaderboard computation too slow | Implement caching from day 1, optimize queries |
| Health data model doesn't scale | Design for partitioning from start |
| Authentication stub differs from real Azure AD | Use standard claims-based identity from beginning |
| Mobile sync expectations too complex | Set clear expectations that Phase 9 is mock only |
| Database migrations break in production | Test migrations in staging environment first |

---

## Success Metrics

### By End of Week 8
- [ ] App runs completely locally
- [ ] Can create and run a complete challenge end-to-end
- [ ] 5+ test users can participate simultaneously
- [ ] Leaderboards update correctly
- [ ] All stubs clearly documented
- [ ] Ready for Azure deployment

### By End of Week 12
- [ ] Deployed to Azure
- [ ] Real authentication working
- [ ] Mobile app syncing health data
- [ ] Email notifications working
- [ ] Ready for internal beta test

---

## Quick Start Commands

Once project is set up:

```bash
# Backend
cd ChallengeBoards.API
dotnet restore
dotnet ef database update
dotnet run

# Frontend
cd challenge-boards-web
npm install
npm start

# Open browser
# http://localhost:3000

# Login with test account
# Email: admin@test.com
# Password: Test123!
```

---

## Next Immediate Steps

1. ✅ Create this development plan
2. ⏳ Set up repository structure
3. ⏳ Design database schema (detailed ERD)
4. ⏳ Create initial .NET solution and projects
5. ⏳ Set up React project
6. ⏳ Create first migration
7. ⏳ Implement stub authentication
8. ⏳ Build first API endpoint
9. ⏳ Build first React page

---

**Ready to start coding!** 🚀
