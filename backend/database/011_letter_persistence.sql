-- Preserve UI-specific fields while keeping workflow, ownership and numbering relational.
ALTER TABLE letter_requests ADD COLUMN frontend_data jsonb NOT NULL DEFAULT '{}';
ALTER TABLE outgoing_letters ADD COLUMN frontend_data jsonb NOT NULL DEFAULT '{}';
ALTER TABLE letter_requests ADD COLUMN version integer NOT NULL DEFAULT 1;
ALTER TABLE outgoing_letters ADD COLUMN version integer NOT NULL DEFAULT 1;
ALTER TABLE documents ADD COLUMN content bytea;
CREATE UNIQUE INDEX documents_owner_content_key ON documents(owner_type, owner_id, checksum_sha256)
  WHERE content IS NOT NULL AND deleted_at IS NULL;

-- Incoming letters already have their official numbers at registration.
CREATE OR REPLACE FUNCTION archive_numbered_incoming() RETURNS trigger AS $$
BEGIN
  IF NEW.deleted_at IS NULL AND length(trim(NEW.letter_number)) > 0 THEN
    INSERT INTO archives (archive_number, source_type, source_id, letter_type_id, subject, status, archived_by)
    VALUES ('ARS/SM/' || NEW.number, 'incoming_letter', NEW.id, NEW.letter_type_id,
      NEW.subject, NEW.status::text, NEW.registered_by)
    ON CONFLICT (source_type, source_id) DO UPDATE
      SET subject = EXCLUDED.subject, status = EXCLUDED.status, updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER incoming_archive_persistence AFTER INSERT OR UPDATE ON incoming_letters
  FOR EACH ROW EXECUTE FUNCTION archive_numbered_incoming();
INSERT INTO archives (archive_number, source_type, source_id, letter_type_id, subject, status, archived_by)
SELECT 'ARS/SM/' || number, 'incoming_letter', id, letter_type_id, subject, status::text, registered_by
FROM incoming_letters WHERE deleted_at IS NULL AND length(trim(letter_number)) > 0
ON CONFLICT (source_type, source_id) DO NOTHING;
