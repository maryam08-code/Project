-- Keep the canonical ERD/application key name after manual id_<entity> edits.
-- Only rename single-column UUID primary keys; foreign keys follow automatically.
DO $$
DECLARE entity text; old_key text;
BEGIN
  FOREACH entity IN ARRAY ARRAY['roles','permissions','units','users','letter_types','letter_natures',
    'documents','letter_requests','incoming_letters','outgoing_letters','dispositions',
    'disposition_follow_ups','archives','notifications','backups','final_letter_publications']
  LOOP
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=entity AND column_name='id') THEN
      SELECT a.attname INTO old_key
      FROM pg_index i JOIN pg_class t ON t.oid=i.indrelid
        JOIN pg_namespace n ON n.oid=t.relnamespace
        JOIN pg_attribute a ON a.attrelid=t.oid AND a.attnum=ANY(i.indkey)
      WHERE n.nspname='public' AND t.relname=entity AND i.indisprimary AND i.indnatts=1
        AND a.atttypid='uuid'::regtype AND a.attname LIKE 'id\_%' ESCAPE '\';
      IF old_key IS NOT NULL THEN EXECUTE format('ALTER TABLE public.%I RENAME COLUMN %I TO id',entity,old_key); END IF;
    END IF;
  END LOOP;
END $$;
