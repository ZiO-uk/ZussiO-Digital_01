# Zu Platform – Deployment Guide

## Overview

This guide covers deploying Zu Platform using free-tier services:

| Service         | Purpose                  | Free Tier             |
|-----------------|--------------------------|----------------------|
| GitHub          | Source control / CI/CD   | Unlimited public repos |
| Clerk           | Authentication           | 10,000 MAU free       |
| Supabase        | PostgreSQL + Storage     | 500 MB DB, 1 GB files |
| Resend          | Transactional email      | 3,000 emails/month    |
| Vercel          | Frontend hosting         | Unlimited hobby       |
| Railway         | Backend hosting          | $5/month credit       |
| Better Stack    | Monitoring               | 5 monitors free       |

---

## 1. GitHub Setup

```bash
# Clone or initialise
git init zu-platform
cd zu-platform

# Set up remote
git remote add origin https://github.com/YOUR_ORG/zu-platform.git

# Create main branch and push
git add .
git commit -m "feat: initial platform scaffold"
git push -u origin main
```

### Secrets to add in GitHub Settings → Secrets:

```
VERCEL_TOKEN
VERCEL_ORG_ID
VERCEL_PROJECT_ID
RAILWAY_TOKEN
```

---

## 2. Supabase (PostgreSQL + Storage)

### Create project
1. Go to https://supabase.com
2. New project → choose a region (UK preferred: London)
3. Note your **Project URL** and **anon key** from Settings → API

### Run schema
1. Open **SQL Editor** in Supabase dashboard
2. Paste contents of `docs/architecture/schema.sql`
3. Click **Run**
4. Paste contents of `docs/architecture/seed.sql`
5. Click **Run**

### Storage buckets
Create two buckets in **Storage**:
- `evidence` (private) – ISMS evidence files
- `documents` (private) – ZuDoc attachments
- `card-assets` (public) – ZuCards images

### Row Level Security
RLS is enabled by schema. Add policies via Supabase dashboard or SQL:

```sql
-- Example: users can only access their own tenant's documents
CREATE POLICY "tenant_isolation_documents"
ON documents FOR ALL
USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
```

### Connection string
From Settings → Database → Connection string (URI mode):
```
postgresql://postgres:YOUR_PASSWORD@db.PROJECT_REF.supabase.co:5432/postgres
```

---

## 3. Clerk (Authentication)

### Create application
1. Go to https://clerk.com
2. Create application → name it "Zu Platform"
3. Enable **Email + Password** and **Google OAuth**

### Get credentials
From Clerk Dashboard → API Keys:
```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
CLERK_SECRET_KEY=sk_...
```

### Configure webhook
1. Clerk Dashboard → Webhooks → Add endpoint
2. URL: `https://YOUR_BACKEND_URL/api/v1/auth/webhook/clerk`
3. Events to subscribe: `user.created`, `user.updated`, `user.deleted`
4. Copy the **Signing Secret** → `CLERK_WEBHOOK_SECRET`

### Customise appearance
Clerk Dashboard → Customization → match Zu Platform brand colours (#6366f1).

---

## 4. Resend (Email)

1. Go to https://resend.com
2. Create account → Add Domain (or use provided sandbox domain for dev)
3. Create API key → `RESEND_API_KEY=re_...`
4. Verify domain DNS records

---

## 5. Frontend – Vercel

### Install Vercel CLI
```bash
npm install -g vercel
cd frontend
vercel login
vercel link  # link to project
```

### Set environment variables
In Vercel dashboard → Project → Settings → Environment Variables:

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
NEXT_PUBLIC_API_URL   (your Railway backend URL)
CLERK_SECRET_KEY
SUPABASE_SERVICE_ROLE_KEY
RESEND_API_KEY
STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET
```

### Deploy
```bash
vercel --prod
```

Or push to `main` to trigger the GitHub Actions workflow.

---

## 6. Backend – Railway

### Install Railway CLI
```bash
npm install -g @railway/cli
railway login
```

### Create project
```bash
cd backend
railway init
# Select "Empty project"
railway up
```

### Set environment variables in Railway dashboard:
```
DATABASE_URL          (Supabase connection string)
CLERK_SECRET_KEY
CLERK_WEBHOOK_SECRET
RESEND_API_KEY
STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET
JWT_SECRET            (generate: openssl rand -base64 32)
FRONTEND_URL          (your Vercel URL)
NODE_ENV=production
PORT=4000
```

### Get backend URL
Railway will assign a URL like `https://zu-backend-production.up.railway.app`.
Set this as `NEXT_PUBLIC_API_URL` in Vercel.

---

## 7. Better Stack (Monitoring)

1. Go to https://betterstack.com
2. Create monitors for:
   - Frontend: `https://YOUR_VERCEL_URL`
   - Backend health: `https://YOUR_RAILWAY_URL/api/health`
3. Set alert notifications (email / Slack)
4. Copy **Source token** → `BETTERSTACK_SOURCE_TOKEN`

---

## 8. Stripe (Payments – future billing)

1. Go to https://dashboard.stripe.com
2. Get test keys from Developers → API keys
3. Create webhook endpoint for:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`

---

## Local Development

### Prerequisites
- Node.js 20+
- Docker (for local PostgreSQL + Redis)

### Setup
```bash
# Clone
git clone https://github.com/YOUR_ORG/zu-platform.git
cd zu-platform

# Copy environment template
cp .env.example .env.local
# Fill in your Clerk, Supabase, and Resend credentials

# Start local dependencies
docker compose -f docker/docker-compose.yml up postgres redis -d

# Install dependencies
npm install  # root
cd frontend && npm install
cd ../backend && npm install

# Start both services
cd ..
npm run dev
```

Frontend: http://localhost:3000
Backend:  http://localhost:4000
API Docs: http://localhost:4000/api/docs

---

## Production Checklist

- [ ] All `.env` secrets set in Vercel and Railway
- [ ] Clerk webhook configured and verified
- [ ] Supabase schema and seed data applied
- [ ] RLS policies reviewed and active
- [ ] Resend domain verified
- [ ] Better Stack monitors live
- [ ] Stripe webhooks configured
- [ ] JWT_SECRET is a strong random value
- [ ] CORS configured to production frontend URL
- [ ] GitHub Actions secrets added
- [ ] Custom domain configured on Vercel

---

## Useful Commands

```bash
# View backend logs (Railway)
railway logs

# Run database migrations locally
cd backend && npm run db:migrate

# Seed database locally
cd backend && npm run db:seed

# Run all tests
npm run test

# Type check frontend
cd frontend && npm run type-check

# Build for production locally
npm run build
```
