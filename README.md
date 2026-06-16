# Zu Platform

**One Platform. Multiple Business Solutions.**

Enterprise-grade modular SaaS ecosystem featuring ISMS Trustee (compliance management), ZuCards (group eCards), and ZuDoc (document management & e-signatures).

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/YOUR_ORG/zu-platform.git
cd zu-platform

# 2. Environment
cp .env.example .env.local
# Fill in Clerk, Supabase, and Resend credentials

# 3. Start local services (PostgreSQL + Redis)
docker compose -f docker/docker-compose.yml up -d

# 4. Install dependencies
npm install
cd frontend && npm install && cd ..
cd backend  && npm install && cd ..

# 5. Start development servers
npm run dev
```

- **Frontend**: http://localhost:3000
- **Backend**:  http://localhost:4000
- **API Docs**: http://localhost:4000/api/docs

---

## Architecture

| Layer        | Technology              |
|-------------|-------------------------|
| Frontend    | Next.js 14, React, TypeScript, Tailwind CSS, ShadCN |
| Backend     | NestJS, TypeORM, Passport |
| Database    | PostgreSQL (Supabase)   |
| Auth        | Clerk                   |
| Email       | Resend                  |
| Payments    | Stripe                  |
| Frontend hosting | Vercel            |
| Backend hosting  | Railway           |
| Monitoring  | Better Stack            |

---

## Applications

| App          | Plan  | Description |
|-------------|-------|-------------|
| ISMS Trustee | Gold  | ISO 27001, Cyber Essentials & GDPR compliance |
| ZuCards      | Free  | Group greeting cards for teams |
| ZuDoc        | Free  | Document management & e-signatures |

---

## Project Structure

```
zu-platform/
├── frontend/              # Next.js application
│   └── src/
│       ├── app/           # App Router pages
│       ├── components/    # React components
│       ├── lib/           # Utilities
│       └── types/         # TypeScript types
├── backend/               # NestJS API
│   └── src/
│       ├── modules/       # Feature modules
│       ├── common/        # Guards, decorators, interceptors
│       └── config/        # Configuration
├── docs/
│   ├── architecture/      # Schema, ERD, ADRs
│   ├── api/               # OpenAPI spec
│   └── deployment/        # Deployment guides
├── docker/                # Docker Compose
└── .github/workflows/     # CI/CD
```

---

## Available Scripts

```bash
npm run dev          # Start both frontend and backend
npm run build        # Build both for production
npm run test         # Run all tests
npm run lint         # Lint both codebases
npm run db:migrate   # Run database migrations
npm run db:seed      # Seed database with initial data
```

---

## Deployment

See [docs/deployment/DEPLOYMENT.md](docs/deployment/DEPLOYMENT.md) for the complete guide covering Vercel, Railway, Supabase, Clerk, Resend, and Stripe setup.

---

## Testing

```bash
# Backend unit tests
cd backend && npm test

# Backend coverage
cd backend && npm run test:cov

# Frontend tests
cd frontend && npm test

# E2E tests
cd backend && npm run test:e2e
```

---

## License

Private – All rights reserved. Zu Platform Ltd.
