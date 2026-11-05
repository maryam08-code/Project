-- Human-readable identifiers; UUID keys and foreign keys remain intact.
DO $$
DECLARE
  entity text;
  ordering text;
BEGIN
  FOREACH entity IN ARRAY ARRAY['roles', 'permissions', 'units', 'users', 'letter_types',
    'documents', 'letter_requests', 'incoming_letters', 'outgoing_letters', 'dispositions',
    'disposition_follow_ups', 'archives', 'notifications', 'backups', 'final_letter_publications']
  LOOP
    EXECUTE format('ALTER TABLE %I ADD COLUMN number bigint', entity);
    ordering := CASE WHEN entity = 'final_letter_publications' THEN 'published_at, id' WHEN entity = 'documents' THEN 'uploaded_at, id' ELSE 'created_at, id' END;
    EXECUTE format('WITH numbered AS (SELECT id, row_number() OVER (ORDER BY %s) AS n FROM %I)
      UPDATE %I AS target SET number = numbered.n FROM numbered WHERE target.id = numbered.id', ordering, entity, entity);
    EXECUTE format('ALTER TABLE %I ALTER COLUMN number SET NOT NULL', entity);
    EXECUTE format('ALTER TABLE %I ALTER COLUMN number ADD GENERATED ALWAYS AS IDENTITY', entity);
    EXECUTE format('SELECT setval(pg_get_serial_sequence(%L, %L), COALESCE(MAX(number), 0) + 1, false) FROM %I', entity, 'number', entity);
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I UNIQUE (number)', entity, entity || '_number_key');
  END LOOP;
END $$;
