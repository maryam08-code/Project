CREATE TABLE IF NOT EXISTS final_letter_publications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type varchar(40) NOT NULL CHECK (source_type IN ('ajuan', 'outgoing')),
  source_reference varchar(200) NOT NULL,
  letter_number varchar(200) NOT NULL,
  number_normal text NOT NULL UNIQUE,
  code_hash varchar(64) NOT NULL UNIQUE,
  metadata jsonb NOT NULL,
  document_name varchar(255) NOT NULL,
  document_pdf bytea NOT NULL,
  document_hash varchar(64) NOT NULL,
  published_by uuid NOT NULL REFERENCES users(id),
  published_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (source_type, source_reference)
);
