# Koto Pai

A personal debt tracking application. Track what you owe and what's owed to you with friends and family.

## Getting Started

### Prerequisites

* Ruby 3.x
* PostgreSQL
* Node.js (for Tailwind CSS)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Setup the database:
   ```bash
   bin/rails db:create db:migrate
   ```
4. Start the development server:
   ```bash
   bin/dev
   ```

## Development

### Database Seeding (Development Only)

⚠️ **WARNING**: The following test credentials are for local development ONLY. Do not use these in production.

To populate your development database with test users and data:

```bash
bin/rails db:seed
```

**Test User Credentials (password: `password123` for all):**

| Email | Role Description |
|-------|-----------------|
| alice@example.com | Creator/Lender on multiple chains |
| bob@example.com | Lender/Creator on some, Borrower on others |
| charlie@example.com | Borrower on some, Viewer on others |
| diana@example.com | Lender/Creator on some, Viewer on others |
| eve@example.com | Creator on some, Viewer on others |

**Testing the Add Participant Feature:**

- **Users who can add participants:** Login as `alice@example.com` or `bob@example.com` - they have creator/lender roles
- **Users who cannot add participants:** Login as `charlie@example.com` or `diana@example.com` on chains where they are borrower/viewer

### Running Tests

```bash
bin/rails test
```

## Deployment

Instructions for deploying to production...

## Security Notice

- Never commit production credentials to the repository
- Never use the development test passwords (`password123`) in production
- Ensure proper authentication and authorization checks are in place before deploying
