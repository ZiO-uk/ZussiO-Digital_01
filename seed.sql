-- ============================================================
-- Zu Platform – Seed Data
-- ============================================================

-- ─── Subscription Plans ──────────────────────────────────────
INSERT INTO subscription_plans (slug, name, description, price_monthly_gbp, features, limits, is_public, sort_order)
VALUES
  (
    'free',
    'Free',
    'Get started with ZuCards and ZuDoc at no cost.',
    0,
    '["ZuCards group eCards","ZuDoc document management","Unlimited cards and documents","Up to 10 users","5 GB storage","Community support","E-signature requests"]',
    '{"maxUsers":10,"maxStorageBytes":5368709120,"maxDocuments":null,"maxCards":null,"apiCallsPerDay":1000,"signatureRequestsPerMonth":5}',
    true,
    1
  ),
  (
    'silver',
    'Silver',
    'Coming soon – expanded limits and additional applications.',
    NULL,
    '["Everything in Free","Expanded user limits","Increased storage","Email support"]',
    '{"maxUsers":50,"maxStorageBytes":53687091200,"maxDocuments":null,"maxCards":null,"apiCallsPerDay":10000,"signatureRequestsPerMonth":50}',
    true,
    2
  ),
  (
    'gold',
    'Gold',
    'Full ISMS Trustee suite with compliance management and priority support.',
    NULL,
    '["Everything in Silver","ISMS Trustee","ISO 27001 framework","Cyber Essentials","GDPR tools","Risk register","Audit management","Compliance reporting","Unlimited users","Priority support"]',
    '{"maxUsers":null,"maxStorageBytes":null,"maxDocuments":null,"maxCards":null,"apiCallsPerDay":null,"signatureRequestsPerMonth":null}',
    true,
    3
  ),
  (
    'enterprise',
    'Enterprise',
    'Custom contracts, white-labelling, and dedicated support.',
    NULL,
    '["Everything in Gold","Custom contracts","Custom SLAs","White labelling","Dedicated support","Unlimited usage"]',
    '{"maxUsers":null,"maxStorageBytes":null,"maxDocuments":null,"maxCards":null,"apiCallsPerDay":null,"signatureRequestsPerMonth":null}',
    false,
    4
  );

-- ─── Application Entitlements ─────────────────────────────────
INSERT INTO application_entitlements (plan_slug, app_slug, enabled) VALUES
  ('free',       'zucards', true),
  ('free',       'zudoc',   true),
  ('free',       'isms',    false),
  ('silver',     'zucards', true),
  ('silver',     'zudoc',   true),
  ('silver',     'isms',    false),
  ('gold',       'zucards', true),
  ('gold',       'zudoc',   true),
  ('gold',       'isms',    true),
  ('enterprise', 'zucards', true),
  ('enterprise', 'zudoc',   true),
  ('enterprise', 'isms',    true);

-- ─── Feature Flags ───────────────────────────────────────────
INSERT INTO feature_flags (key, app_slug, plan_slug, enabled, description) VALUES
  -- ISMS features
  ('isms.risk_register',          'isms', 'gold',       true,  'Risk register and risk matrix'),
  ('isms.compliance_reporting',   'isms', 'gold',       true,  'Compliance reports and dashboards'),
  ('isms.audit_management',       'isms', 'gold',       true,  'Audit plans and findings'),
  ('isms.policy_workflows',       'isms', 'gold',       true,  'Policy approval workflows'),
  ('isms.risk_register',          'isms', 'enterprise', true,  'Risk register and risk matrix'),
  ('isms.compliance_reporting',   'isms', 'enterprise', true,  'Compliance reports and dashboards'),

  -- ZuDoc features
  ('zudoc.esignatures',           'zudoc', 'free',       true,  'Basic e-signature requests (5/month)'),
  ('zudoc.esignatures_unlimited', 'zudoc', 'gold',       true,  'Unlimited e-signature requests'),
  ('zudoc.version_history',       'zudoc', 'free',       true,  'Document version history'),
  ('zudoc.shared_links',          'zudoc', 'free',       true,  'Shareable document links'),

  -- ZuCards features
  ('zucards.custom_branding',     'zucards', 'gold',     true,  'Custom card branding'),
  ('zucards.scheduled_delivery',  'zucards', 'free',     true,  'Schedule card delivery'),
  ('zucards.gif_support',         'zucards', 'free',     true,  'GIF and sticker support');

-- ─── Card Templates (seed) ───────────────────────────────────
INSERT INTO card_templates (name, category, is_premium, is_active)
VALUES
  ('Classic Birthday',       'birthday',          false, true),
  ('Fun Birthday',           'birthday',          false, true),
  ('Work Anniversary',       'work_anniversary',  false, true),
  ('Happy Retirement',       'farewell',          false, true),
  ('Farewell & Good Luck',   'farewell',          false, true),
  ('Congratulations',        'congratulations',   false, true),
  ('Happy Holidays',         'holiday',           false, true),
  ('Thank You',              'custom',            false, true),
  ('Premium Birthday',       'birthday',          true,  true),
  ('Premium Anniversary',    'work_anniversary',  true,  true);
