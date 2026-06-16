-- ============================================================
-- Zu Platform – PostgreSQL Schema
-- Run on Supabase via the SQL Editor
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── Tenants ─────────────────────────────────────────────────
CREATE TABLE tenants (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                VARCHAR(255) NOT NULL,
  slug                VARCHAR(100) NOT NULL UNIQUE,
  logo_url            TEXT,
  primary_colour      VARCHAR(7),
  plan                VARCHAR(20)  NOT NULL DEFAULT 'free',
  subscription_status VARCHAR(20)  NOT NULL DEFAULT 'trial',
  stripe_customer_id  VARCHAR(255),
  stripe_sub_id       VARCHAR(255),
  trial_ends_at       TIMESTAMPTZ,
  user_count          INT          NOT NULL DEFAULT 0,
  storage_used_bytes  BIGINT       NOT NULL DEFAULT 0,
  storage_limit_bytes BIGINT       NOT NULL DEFAULT 5368709120,
  is_active           BOOLEAN      NOT NULL DEFAULT true,
  billing_email       VARCHAR(255),
  billing_address_1   VARCHAR(255),
  billing_city        VARCHAR(100),
  billing_postcode    VARCHAR(20),
  billing_country     VARCHAR(2)   DEFAULT 'GB',
  vat_number          VARCHAR(50),
  created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── Users ───────────────────────────────────────────────────
CREATE TABLE users (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  clerk_id       VARCHAR(255) NOT NULL UNIQUE,
  email          VARCHAR(255) NOT NULL UNIQUE,
  first_name     VARCHAR(100) NOT NULL,
  last_name      VARCHAR(100) NOT NULL,
  avatar_url     TEXT,
  role           VARCHAR(30)  NOT NULL DEFAULT 'standard_user',
  tenant_id      UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  is_active      BOOLEAN      NOT NULL DEFAULT true,
  mfa_enabled    BOOLEAN      NOT NULL DEFAULT false,
  last_login_at  TIMESTAMPTZ,
  phone_number   VARCHAR(30),
  department     VARCHAR(100),
  job_title      VARCHAR(150),
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_clerk_id  ON users(clerk_id);

-- ─── Billing: Plans ──────────────────────────────────────────
CREATE TABLE subscription_plans (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug               VARCHAR(50)  NOT NULL UNIQUE,
  name               VARCHAR(100) NOT NULL,
  description        TEXT,
  price_monthly_gbp  NUMERIC(10,2),
  price_annual_gbp   NUMERIC(10,2),
  features           JSONB        NOT NULL DEFAULT '[]',
  limits             JSONB        NOT NULL DEFAULT '{}',
  is_public          BOOLEAN      NOT NULL DEFAULT true,
  is_active          BOOLEAN      NOT NULL DEFAULT true,
  sort_order         INT          NOT NULL DEFAULT 0,
  created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── Billing: Tenant Subscriptions ───────────────────────────
CREATE TABLE tenant_subscriptions (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id             UUID        NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
  plan_slug             VARCHAR(50) NOT NULL,
  status                VARCHAR(30) NOT NULL DEFAULT 'trial',
  stripe_subscription_id VARCHAR(255),
  current_period_start  TIMESTAMPTZ,
  current_period_end    TIMESTAMPTZ,
  cancel_at_period_end  BOOLEAN,
  cancelled_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Billing: App Entitlements ────────────────────────────────
CREATE TABLE application_entitlements (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_slug  VARCHAR(50)  NOT NULL,
  app_slug   VARCHAR(50)  NOT NULL,
  enabled    BOOLEAN      NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (plan_slug, app_slug)
);

-- ─── Billing: Feature Flags ───────────────────────────────────
CREATE TABLE feature_flags (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key         VARCHAR(100) NOT NULL,
  app_slug    VARCHAR(50)  NOT NULL,
  plan_slug   VARCHAR(50)  NOT NULL,
  enabled     BOOLEAN      NOT NULL DEFAULT true,
  description TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (key, plan_slug)
);

-- ─── Billing: Invoices ────────────────────────────────────────
CREATE TABLE invoices (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id            UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  number               VARCHAR(50)  NOT NULL UNIQUE,
  stripe_invoice_id    VARCHAR(255),
  status               VARCHAR(30)  NOT NULL DEFAULT 'draft',
  subtotal_gbp         NUMERIC(10,2) NOT NULL DEFAULT 0,
  tax_amount_gbp       NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_gbp            NUMERIC(10,2) NOT NULL DEFAULT 0,
  billing_period_start TIMESTAMPTZ,
  billing_period_end   TIMESTAMPTZ,
  due_date             TIMESTAMPTZ,
  paid_at              TIMESTAMPTZ,
  pdf_url              TEXT,
  line_items           JSONB         NOT NULL DEFAULT '[]',
  created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoices_tenant_id ON invoices(tenant_id);

-- ─── Billing: Usage Records ───────────────────────────────────
CREATE TABLE usage_records (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id    UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  metric_key   VARCHAR(100) NOT NULL,
  value        BIGINT       NOT NULL,
  recorded_at  TIMESTAMPTZ  NOT NULL,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_usage_tenant_metric ON usage_records(tenant_id, metric_key, recorded_at);

-- ─── ISMS: Risks ─────────────────────────────────────────────
CREATE TABLE isms_risks (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id      UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title          VARCHAR(255) NOT NULL,
  description    TEXT         NOT NULL,
  likelihood     INT          NOT NULL CHECK (likelihood BETWEEN 1 AND 5),
  impact         INT          NOT NULL CHECK (impact BETWEEN 1 AND 5),
  risk_score     INT          GENERATED ALWAYS AS (likelihood * impact) STORED,
  severity       VARCHAR(20)  GENERATED ALWAYS AS (
                   CASE
                     WHEN likelihood * impact >= 20 THEN 'critical'
                     WHEN likelihood * impact >= 15 THEN 'high'
                     WHEN likelihood * impact >= 8  THEN 'medium'
                     ELSE 'low'
                   END
                 ) STORED,
  status         VARCHAR(30)  NOT NULL DEFAULT 'open',
  owner_id       UUID         REFERENCES users(id),
  treatment_plan TEXT,
  due_date       TIMESTAMPTZ,
  tags           TEXT[]       NOT NULL DEFAULT '{}',
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_isms_risks_tenant ON isms_risks(tenant_id);

-- ─── ISMS: Controls ──────────────────────────────────────────
CREATE TABLE isms_controls (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id        UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  framework        VARCHAR(50)  NOT NULL,
  control_ref      VARCHAR(50)  NOT NULL,
  title            VARCHAR(255) NOT NULL,
  description      TEXT         NOT NULL,
  status           VARCHAR(30)  NOT NULL DEFAULT 'not_started',
  owner_id         UUID         REFERENCES users(id),
  last_reviewed_at TIMESTAMPTZ,
  next_review_at   TIMESTAMPTZ,
  notes            TEXT,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_isms_controls_tenant     ON isms_controls(tenant_id);
CREATE INDEX idx_isms_controls_framework  ON isms_controls(tenant_id, framework);

-- ─── ISMS: Policies ──────────────────────────────────────────
CREATE TABLE isms_policies (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id       UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title           VARCHAR(255) NOT NULL,
  content         TEXT         NOT NULL,
  version         VARCHAR(20)  NOT NULL DEFAULT '1.0',
  status          VARCHAR(30)  NOT NULL DEFAULT 'draft',
  approved_by_id  UUID         REFERENCES users(id),
  approved_at     TIMESTAMPTZ,
  review_date     TIMESTAMPTZ,
  created_by_id   UUID         NOT NULL REFERENCES users(id),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE policy_acknowledgements (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  policy_id        UUID NOT NULL REFERENCES isms_policies(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES users(id),
  acknowledged_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (policy_id, user_id)
);

-- ─── ISMS: Audits ────────────────────────────────────────────
CREATE TABLE isms_audits (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id        UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title            VARCHAR(255) NOT NULL,
  scope            TEXT,
  status           VARCHAR(30)  NOT NULL DEFAULT 'planned',
  scheduled_date   TIMESTAMPTZ,
  completed_date   TIMESTAMPTZ,
  auditor_id       UUID         REFERENCES users(id),
  created_by_id    UUID         NOT NULL REFERENCES users(id),
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_findings (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  audit_id          UUID         NOT NULL REFERENCES isms_audits(id) ON DELETE CASCADE,
  title             VARCHAR(255) NOT NULL,
  description       TEXT         NOT NULL,
  severity          VARCHAR(30)  NOT NULL DEFAULT 'minor',
  status            VARCHAR(30)  NOT NULL DEFAULT 'open',
  due_date          TIMESTAMPTZ,
  corrective_action TEXT,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── ISMS: Evidence ──────────────────────────────────────────
CREATE TABLE evidence (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id       UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title           VARCHAR(255) NOT NULL,
  description     TEXT,
  file_url        TEXT         NOT NULL,
  file_name       VARCHAR(255) NOT NULL,
  file_type       VARCHAR(100) NOT NULL,
  file_size_bytes BIGINT       NOT NULL,
  expires_at      TIMESTAMPTZ,
  uploaded_by_id  UUID         NOT NULL REFERENCES users(id),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── ZuCards: Templates ──────────────────────────────────────
CREATE TABLE card_templates (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          VARCHAR(255) NOT NULL,
  category      VARCHAR(50)  NOT NULL,
  thumbnail_url TEXT,
  design_data   JSONB        NOT NULL DEFAULT '{}',
  is_premium    BOOLEAN      NOT NULL DEFAULT false,
  is_active     BOOLEAN      NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── ZuCards: Group Cards ────────────────────────────────────
CREATE TABLE group_cards (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id           UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title               VARCHAR(255) NOT NULL,
  recipient_name      VARCHAR(255) NOT NULL,
  recipient_email     VARCHAR(255) NOT NULL,
  template_id         UUID         REFERENCES card_templates(id),
  category            VARCHAR(50)  NOT NULL,
  design_data         JSONB        NOT NULL DEFAULT '{}',
  scheduled_delivery  TIMESTAMPTZ,
  delivered_at        TIMESTAMPTZ,
  shareable_link      TEXT         NOT NULL UNIQUE,
  shareable_token     VARCHAR(100) UNIQUE,
  status              VARCHAR(30)  NOT NULL DEFAULT 'draft',
  created_by_id       UUID         NOT NULL REFERENCES users(id),
  created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_group_cards_tenant ON group_cards(tenant_id);

CREATE TABLE card_contributions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  card_id           UUID         NOT NULL REFERENCES group_cards(id) ON DELETE CASCADE,
  contributor_name  VARCHAR(255) NOT NULL,
  contributor_email VARCHAR(255),
  message           TEXT         NOT NULL,
  gif_url           TEXT,
  sticker_url       TEXT,
  position          JSONB        NOT NULL DEFAULT '{"x": 0, "y": 0}',
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── ZuDoc: Folders ──────────────────────────────────────────
CREATE TABLE document_folders (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id      UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name           VARCHAR(255) NOT NULL,
  parent_id      UUID         REFERENCES document_folders(id),
  created_by_id  UUID         NOT NULL REFERENCES users(id),
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── ZuDoc: Documents ────────────────────────────────────────
CREATE TABLE documents (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id        UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title            VARCHAR(255) NOT NULL,
  content          TEXT         NOT NULL DEFAULT '',
  folder_id        UUID         REFERENCES document_folders(id),
  status           VARCHAR(30)  NOT NULL DEFAULT 'draft',
  tags             TEXT[]       NOT NULL DEFAULT '{}',
  current_version  INT          NOT NULL DEFAULT 1,
  created_by_id    UUID         NOT NULL REFERENCES users(id),
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documents_tenant ON documents(tenant_id);

CREATE TABLE document_versions (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id    UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  version        INT  NOT NULL,
  content        TEXT NOT NULL,
  changed_by_id  UUID NOT NULL REFERENCES users(id),
  change_summary VARCHAR(500),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE shared_links (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id  UUID        NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  token        VARCHAR(100) NOT NULL UNIQUE,
  permissions  VARCHAR(20)  NOT NULL DEFAULT 'view',
  expires_at   TIMESTAMPTZ,
  is_active    BOOLEAN      NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── ZuDoc: Signatures ───────────────────────────────────────
CREATE TABLE signature_requests (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id      UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  document_id    UUID         NOT NULL REFERENCES documents(id),
  title          VARCHAR(255) NOT NULL,
  message        TEXT,
  status         VARCHAR(30)  NOT NULL DEFAULT 'pending',
  completed_at   TIMESTAMPTZ,
  expires_at     TIMESTAMPTZ,
  created_by_id  UUID         NOT NULL REFERENCES users(id),
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sig_requests_tenant ON signature_requests(tenant_id);

CREATE TABLE signatories (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  signature_request_id  UUID         NOT NULL REFERENCES signature_requests(id) ON DELETE CASCADE,
  email                 VARCHAR(255) NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  "order"               INT          NOT NULL DEFAULT 1,
  status                VARCHAR(30)  NOT NULL DEFAULT 'pending',
  signed_at             TIMESTAMPTZ,
  declined_at           TIMESTAMPTZ,
  signature_image_url   TEXT,
  ip_address            INET,
  signing_token         VARCHAR(100) UNIQUE,
  created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE signature_audit_log (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  signature_request_id  UUID         NOT NULL REFERENCES signature_requests(id) ON DELETE CASCADE,
  event                 VARCHAR(100) NOT NULL,
  actor_email           VARCHAR(255),
  ip_address            INET,
  metadata              JSONB,
  created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── Notifications ────────────────────────────────────────────
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tenant_id   UUID         NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  type        VARCHAR(30)  NOT NULL DEFAULT 'info',
  title       VARCHAR(255) NOT NULL,
  message     TEXT         NOT NULL,
  app_slug    VARCHAR(50),
  action_url  TEXT,
  is_read     BOOLEAN      NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);

-- ─── Audit Log (platform-wide) ───────────────────────────────
CREATE TABLE audit_log (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id   UUID,
  user_id     UUID,
  action      VARCHAR(100) NOT NULL,
  resource    VARCHAR(100) NOT NULL,
  resource_id UUID,
  ip_address  INET,
  user_agent  TEXT,
  metadata    JSONB,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_tenant ON audit_log(tenant_id, created_at);

-- ─── Row Level Security ───────────────────────────────────────
ALTER TABLE users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE isms_risks          ENABLE ROW LEVEL SECURITY;
ALTER TABLE isms_controls       ENABLE ROW LEVEL SECURITY;
ALTER TABLE isms_policies       ENABLE ROW LEVEL SECURITY;
ALTER TABLE isms_audits         ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_cards         ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents           ENABLE ROW LEVEL SECURITY;
ALTER TABLE signature_requests  ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices            ENABLE ROW LEVEL SECURITY;

-- Updated timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER trg_tenants_updated         BEFORE UPDATE ON tenants          FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_users_updated           BEFORE UPDATE ON users             FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_documents_updated       BEFORE UPDATE ON documents         FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_sig_requests_updated    BEFORE UPDATE ON signature_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_group_cards_updated     BEFORE UPDATE ON group_cards       FOR EACH ROW EXECUTE FUNCTION update_updated_at();
