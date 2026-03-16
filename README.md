# SplitLive - Real-Time Expense Splitting Application

A full-stack Splitwise clone with real-time updates, built with Ruby on Rails 7 and React.

**Live App:** [splitlive.vercel.app](https://splitlive.vercel.app) | **API:** [splitlive-api.onrender.com](https://splitlive-api.onrender.com/up)

---

## Architecture

```
                    ┌──────────────────────────────────────────┐
                    │           React Frontend (Vercel)         │
                    │                                          │
                    │  LoginPage ─ GroupsPage ─ GroupDetailPage │
                    │  Context API (Auth) ─ React Router        │
                    └──────────┬──────────────┬────────────────┘
                               │              │
                          HTTP REST      WebSocket
                          (fetch)     (ActionCable)
                               │              │
                    ┌──────────▼──────────────▼────────────────┐
                    │          Rails 7 API (Render)             │
                    │                                          │
                    │  JWT Auth ─ Controllers ─ ActionCable     │
                    │  Services ─ Background Jobs ─ Mailers     │
                    └──────┬──────────┬──────────┬─────────────┘
                           │          │          │
                    ┌──────▼───┐ ┌────▼────┐ ┌───▼────┐
                    │PostgreSQL│ │  Redis  │ │Sidekiq │
                    │  (data)  │ │ (queue) │ │(worker)│
                    └──────────┘ └─────────┘ └────────┘
```

## Features

- **User Authentication** - JWT-based signup/login with bcrypt password hashing
- **Groups** - Create groups, add members by email
- **Expenses** - Add expenses with 3 split types:
  - Equal split (auto-divides among all members)
  - Percentage split (custom % per person)
  - Exact split (custom amount per person)
- **Balance Calculation** - Greedy debt simplification algorithm that minimizes settlement transactions
- **Real-Time Updates** - ActionCable WebSockets push expense and balance updates instantly to all group members
- **Settlements** - Record payments between members to settle debts
- **Email Notifications** - Action Mailer sends expense alerts to group members via background jobs
- **Background Jobs** - Sidekiq processes balance broadcasts and email notifications asynchronously

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby on Rails 7.2 (API mode) |
| Frontend | React 18 + Context API + React Router |
| Database | PostgreSQL 16 |
| Real-time | ActionCable (WebSockets) |
| Background Jobs | Sidekiq + Redis |
| Auth | JWT (JSON Web Tokens) + bcrypt |
| Email | Action Mailer + Gmail SMTP |
| Testing | RSpec + FactoryBot (45 tests) |
| Deployment | Render (API) + Vercel (Frontend) |
| CI/CD | GitHub Actions (RuboCop linting) |

## Database Schema

```
┌──────────┐       ┌─────────────┐       ┌──────────┐
│  Users   │──────>│ Memberships │<──────│  Groups  │
│          │  1:N  │ (join table)│  N:1  │          │
│ id       │       │ user_id     │       │ id       │
│ name     │       │ group_id    │       │ name     │
│ email    │       └─────────────┘       │created_by│
│ password │                             └──────────┘
│ _digest  │                                  │
└──────────┘                                  │ 1:N
     │                                        │
     │ 1:N                              ┌─────▼────┐
     │         ┌──────────────┐         │ Expenses │
     └────────>│ExpenseSplits │<────────│          │
               │              │   1:N   │ group_id │
               │ expense_id   │         │ paid_by  │
               │ user_id      │         │ amount   │
               │ amount_owed  │         │ split_   │
               └──────────────┘         │  type    │
                                        └──────────┘
┌──────────────┐
│ Settlements  │
│              │
│ group_id     │
│ payer_id ────│──> Users
│ payee_id ────│──> Users
│ amount       │
└──────────────┘
```

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/signup` | Create account, returns JWT |
| POST | `/api/v1/auth/login` | Login, returns JWT |

### Groups
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/groups` | List your groups |
| POST | `/api/v1/groups` | Create a group |
| GET | `/api/v1/groups/:id` | Group details + members |
| GET | `/api/v1/groups/:id/balances` | Net balances + simplified debts |
| POST | `/api/v1/groups/:id/members` | Add member by email |

### Expenses
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/groups/:id/expenses` | List group expenses |
| POST | `/api/v1/groups/:id/expenses` | Add expense with splits |

### Settlements
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/groups/:id/settlements` | List settlements |
| POST | `/api/v1/groups/:id/settlements` | Record a payment |

### WebSocket
```
ws://localhost:3000/cable?token=<JWT>
Channel: GroupChannel { group_id: <id> }
```

## Balance Calculation Algorithm

The app uses a **greedy debt simplification algorithm** to minimize the number of settlement transactions:

```
1. Calculate net balance for each member:
   Net = (Total Paid) - (Total Owed) + (Settlements Received) - (Settlements Made)

2. Separate into creditors (+balance) and debtors (-balance)

3. Sort both by amount (largest first)

4. Match biggest debtor with biggest creditor:
   Transfer = min(debt, credit)
   Repeat until all settled

Example:
  Dewoo: +600 (is owed), Rahul: -300 (owes), Priya: -300 (owes)
  Result: Rahul pays Dewoo 300, Priya pays Dewoo 300
  Only 2 transactions instead of potentially more
```

## Getting Started

### Prerequisites

- Ruby 3.3+
- Rails 7.2+
- PostgreSQL 16+
- Node.js 18+
- Redis (for Sidekiq)

### Backend Setup

```bash
# Clone the repo
git clone https://github.com/DewooSawant/splitlive.git
cd splitlive

# Install dependencies
bundle install

# Create and migrate database
bin/rails db:create db:migrate

# Start the server
bin/rails server
```

### Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start React dev server
PORT=3001 npm start
```

### Running Background Jobs (optional)

```bash
# Start Redis (if not running)
brew services start redis

# Start Sidekiq worker
bundle exec sidekiq
```

### Running Tests

```bash
# Run all 45 tests
bundle exec rspec

# With verbose output
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/services/balance_calculator_spec.rb
```

## Test Coverage

```
45 tests, 0 failures

Models:
  - User: validations, email normalization, authentication, associations
  - Expense: validations, enum (equal/percentage/exact)
  - Settlement: custom validation (payer != payee)

Requests:
  - Authentication: signup, login, error handling
  - Groups: CRUD, authorization, member-only access
  - Expenses: create with splits, validation errors

Services:
  - BalanceCalculator: net balances, settlements, debt simplification, zero-sum property
```

## Project Structure

```
splitlive/
├── app/
│   ├── channels/
│   │   ├── application_cable/connection.rb   # WebSocket JWT auth
│   │   └── group_channel.rb                  # Real-time group updates
│   ├── controllers/api/v1/
│   │   ├── authentication_controller.rb      # Signup + Login
│   │   ├── groups_controller.rb              # Groups CRUD + Balances
│   │   ├── members_controller.rb             # Add members
│   │   ├── expenses_controller.rb            # Expenses with splits
│   │   └── settlements_controller.rb         # Record payments
│   ├── jobs/
│   │   ├── balance_broadcast_job.rb          # Async WebSocket broadcast
│   │   └── expense_notification_job.rb       # Async email notifications
│   ├── mailers/
│   │   └── expense_mailer.rb                 # Email templates
│   ├── models/
│   │   ├── user.rb, group.rb, membership.rb
│   │   ├── expense.rb, expense_split.rb, settlement.rb
│   └── services/
│       ├── jwt_service.rb                    # Token encode/decode
│       └── balance_calculator.rb             # Debt simplification
├── frontend/
│   └── src/
│       ├── api/api.js                        # Centralized API calls
│       ├── context/AuthContext.js             # Global auth state
│       └── pages/
│           ├── LoginPage.js                  # Signup/Login
│           ├── GroupsPage.js                 # Group list
│           └── GroupDetailPage.js            # Expenses/Balances/Members
├── spec/                                     # 45 RSpec tests
└── config/
    ├── routes.rb                             # API routes
    └── cable.yml                             # ActionCable config
```

## Key Technical Decisions

| Decision | Reasoning |
|----------|-----------|
| JWT over Devise | API-only app doesn't need sessions/cookies. 50 lines vs complex gem config. |
| Context API over Redux | App state is simple (token + user). Redux adds unnecessary boilerplate. |
| Greedy algorithm for debts | Minimizes transactions. O(n log n) time complexity. |
| Background jobs for broadcasts | API responds instantly. Heavy work (balance calc, email) happens async. |
| Decimal(10,2) for money | Never use float for financial data. Prevents rounding errors. |
| Composite unique indexes | Database-level protection against duplicates (membership, expense splits). |

## Author

**Dewoo Sawant** - [GitHub](https://github.com/DewooSawant)
