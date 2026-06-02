-- E-Office PostgreSQL schema
-- Source: PRD.md + current frontend mock screens.
-- Timezone expectation: application writes/reads in Asia/Jakarta.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

DO $$ BEGIN
  CREATE TYPE user_status AS ENUM ('aktif', 'nonaktif');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE letter_request_status AS ENUM (
    'draft',
    'dikirim',
    'diproses_operator',
    'menunggu_approval',
    'disetujui',
    'ditolak',
    'selesai'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE incoming_letter_status AS ENUM (
    'diregistrasi',
    'diteruskan',
    'didisposisikan',
    'ditindaklanjuti',
    'selesai'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE outgoing_letter_status AS ENUM (
    'draft',
    'diperiksa',
    'menunggu_approval',
    'disetujui',
    'ditolak',
    'dikirim'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE disposition_status AS ENUM ('dikirim', 'diterima', 'ditindaklanjuti', 'selesai');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE follow_up_status AS ENUM ('proses', 'selesai');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE priority_level AS ENUM ('biasa', 'penting', 'segera');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE archive_source_type AS ENUM ('letter_request', 'incoming_letter', 'outgoing_letter', 'disposition');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE document_owner_type AS ENUM ('letter_request', 'incoming_letter', 'outgoing_letter', 'disposition_follow_up', 'archive', 'backup');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM (
    'letter_request_submitted',
    'incoming_letter_forwarded',
    'disposition_created',
    'disposition_followed_up',
    'letter_request_approved',
    'letter_request_rejected',
    'outgoing_letter_sent',
    'generic'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(50) NOT NULL UNIQUE,
  name varchar(100) NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(100) NOT NULL UNIQUE,
  name varchar(150) NOT NULL,
  module varchar(80) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(150) NOT NULL UNIQUE,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id uuid NOT NULL REFERENCES roles(id),
  unit_id uuid REFERENCES units(id) ON DELETE SET NULL,
  full_name varchar(150) NOT NULL,
  username varchar(80) NOT NULL UNIQUE,
  email citext UNIQUE,
  password_hash text NOT NULL,
  position varchar(120),
  phone varchar(40),
  address text,
  status user_status NOT NULL DEFAULT 'aktif',
  must_change_password boolean NOT NULL DEFAULT false,
  last_login_at timestamptz,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS letter_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(120) NOT NULL UNIQUE,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS letter_natures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(50) NOT NULL UNIQUE,
  name varchar(80) NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_type document_owner_type NOT NULL,
  owner_id uuid,
  original_name varchar(255) NOT NULL,
  stored_name varchar(255) NOT NULL UNIQUE,
  storage_path text NOT NULL,
  mime_type varchar(150) NOT NULL,
  file_extension varchar(20) NOT NULL,
  file_size_bytes bigint NOT NULL CHECK (file_size_bytes > 0 AND file_size_bytes <= 10485760),
  checksum_sha256 varchar(64),
  previewable boolean NOT NULL DEFAULT false,
  uploaded_by uuid REFERENCES users(id) ON DELETE SET NULL,
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT documents_allowed_extension CHECK (lower(file_extension) IN ('pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png')),
  CONSTRAINT documents_allowed_mime CHECK (
    mime_type IN (
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'image/jpeg',
      'image/png'
    )
  )
);

CREATE TABLE IF NOT EXISTS letter_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_number varchar(60) NOT NULL UNIQUE,
  request_date date NOT NULL DEFAULT CURRENT_DATE,
  letter_type_id uuid NOT NULL REFERENCES letter_types(id),
  subject varchar(255) NOT NULL,
  destination varchar(255) NOT NULL,
  body text NOT NULL,
  applicant_id uuid NOT NULL REFERENCES users(id),
  applicant_unit_id uuid REFERENCES units(id) ON DELETE SET NULL,
  status letter_request_status NOT NULL DEFAULT 'draft',
  operator_id uuid REFERENCES users(id) ON DELETE SET NULL,
  approver_id uuid REFERENCES users(id) ON DELETE SET NULL,
  rejection_note text,
  submitted_at timestamptz,
  processed_at timestamptz,
  approval_requested_at timestamptz,
  approved_at timestamptz,
  rejected_at timestamptz,
  completed_at timestamptz,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT letter_requests_rejection_note_required CHECK (status <> 'ditolak' OR rejection_note IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS incoming_letters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agenda_number varchar(60) NOT NULL UNIQUE,
  letter_number varchar(100) NOT NULL,
  letter_date date NOT NULL,
  received_date date NOT NULL,
  sender varchar(255) NOT NULL,
  subject varchar(255) NOT NULL,
  letter_type_id uuid NOT NULL REFERENCES letter_types(id),
  letter_nature_id uuid NOT NULL REFERENCES letter_natures(id),
  summary text,
  status incoming_letter_status NOT NULL DEFAULT 'diregistrasi',
  registered_by uuid NOT NULL REFERENCES users(id),
  forwarded_to uuid REFERENCES users(id) ON DELETE SET NULL,
  forwarded_by uuid REFERENCES users(id) ON DELETE SET NULL,
  forwarded_at timestamptz,
  read_by_leader_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS outgoing_letters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_number varchar(100) NOT NULL UNIQUE,
  letter_date date NOT NULL,
  letter_type_id uuid REFERENCES letter_types(id) ON DELETE SET NULL,
  destination varchar(255) NOT NULL,
  subject varchar(255) NOT NULL,
  summary text,
  status outgoing_letter_status NOT NULL DEFAULT 'draft',
  created_by uuid NOT NULL REFERENCES users(id),
  checked_by uuid REFERENCES users(id) ON DELETE SET NULL,
  approver_id uuid REFERENCES users(id) ON DELETE SET NULL,
  rejection_note text,
  sent_method varchar(80),
  sent_reference varchar(120),
  checked_at timestamptz,
  approval_requested_at timestamptz,
  approved_at timestamptz,
  rejected_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT outgoing_letters_rejection_note_required CHECK (status <> 'ditolak' OR rejection_note IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS dispositions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  disposition_number varchar(60) NOT NULL UNIQUE,
  incoming_letter_id uuid NOT NULL REFERENCES incoming_letters(id),
  giver_id uuid NOT NULL REFERENCES users(id),
  target_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  target_unit_id uuid REFERENCES units(id) ON DELETE SET NULL,
  instruction text NOT NULL,
  due_date date,
  priority priority_level NOT NULL DEFAULT 'biasa',
  status disposition_status NOT NULL DEFAULT 'dikirim',
  sent_at timestamptz NOT NULL DEFAULT now(),
  received_at timestamptz,
  followed_up_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT dispositions_target_required CHECK (target_user_id IS NOT NULL OR target_unit_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS disposition_follow_ups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  disposition_id uuid NOT NULL REFERENCES dispositions(id) ON DELETE CASCADE,
  notes text NOT NULL,
  status follow_up_status NOT NULL DEFAULT 'proses',
  followed_up_by uuid NOT NULL REFERENCES users(id),
  followed_up_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS archives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  archive_number varchar(60) NOT NULL UNIQUE,
  source_type archive_source_type NOT NULL,
  source_id uuid NOT NULL,
  document_id uuid REFERENCES documents(id) ON DELETE SET NULL,
  letter_type_id uuid REFERENCES letter_types(id) ON DELETE SET NULL,
  subject varchar(255) NOT NULL,
  status varchar(80) NOT NULL,
  archived_by uuid REFERENCES users(id) ON DELETE SET NULL,
  archived_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (source_type, source_id)
);

CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type notification_type NOT NULL DEFAULT 'generic',
  title varchar(180) NOT NULL,
  message text NOT NULL,
  source_type varchar(80),
  source_id uuid,
  is_read boolean NOT NULL DEFAULT false,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  activity varchar(120) NOT NULL,
  module varchar(80) NOT NULL,
  data_id uuid,
  data_label varchar(180),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS backups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  backup_code varchar(80) NOT NULL UNIQUE,
  document_id uuid REFERENCES documents(id) ON DELETE SET NULL,
  status varchar(40) NOT NULL DEFAULT 'success',
  file_size_bytes bigint,
  notes text,
  executed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  executed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'roles',
    'units',
    'users',
    'letter_types',
    'letter_natures',
    'letter_requests',
    'incoming_letters',
    'outgoing_letters',
    'dispositions',
    'disposition_follow_ups',
    'archives'
  ]
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_updated_at ON %I', table_name, table_name);
    EXECUTE format(
      'CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
      table_name,
      table_name
    );
  END LOOP;
END $$;

CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_unit_id ON users(unit_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_documents_owner ON documents(owner_type, owner_id);
CREATE INDEX IF NOT EXISTS idx_letter_requests_applicant_status ON letter_requests(applicant_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_letter_requests_request_date ON letter_requests(request_date);
CREATE INDEX IF NOT EXISTS idx_incoming_letters_status ON incoming_letters(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_incoming_letters_dates ON incoming_letters(letter_date, received_date);
CREATE INDEX IF NOT EXISTS idx_outgoing_letters_status ON outgoing_letters(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_outgoing_letters_date ON outgoing_letters(letter_date);
CREATE INDEX IF NOT EXISTS idx_dispositions_target_user_status ON dispositions(target_user_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_dispositions_incoming_letter ON dispositions(incoming_letter_id);
CREATE INDEX IF NOT EXISTS idx_archives_source ON archives(source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_archives_subject_trgm_fallback ON archives USING btree (lower(subject));
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read ON notifications(recipient_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_filter ON audit_logs(module, user_id, created_at DESC);
