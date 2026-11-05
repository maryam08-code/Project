-- Restore canonical outgoing fields in databases edited outside migrations.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='outgoing_letters' AND column_name='letter_number_outgoing_letter')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='outgoing_letters' AND column_name='letter_number') THEN
    ALTER TABLE outgoing_letters RENAME COLUMN letter_number_outgoing_letter TO letter_number;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='outgoing_letters' AND column_name='subject_outgoing_letter')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='outgoing_letters' AND column_name='subject') THEN
    ALTER TABLE outgoing_letters RENAME COLUMN subject_outgoing_letter TO subject;
  END IF;
END $$;
ALTER TABLE documents ALTER COLUMN checksum_sha256 TYPE varchar(64),
  ALTER COLUMN original_name TYPE varchar(255), ALTER COLUMN stored_name TYPE varchar(255),
  ALTER COLUMN mime_type TYPE varchar(150);
ALTER TABLE outgoing_letters ALTER COLUMN letter_number TYPE varchar(100),
  ALTER COLUMN subject TYPE varchar(255), ALTER COLUMN destination TYPE varchar(255);
