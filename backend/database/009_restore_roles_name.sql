-- Restore the canonical column used by auth, user management, and role metadata.
-- Some existing databases renamed roles.name to name_role after migrations ran.
-- Renaming preserves role IDs, labels, constraints, and user relationships.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'roles' AND column_name = 'name'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'roles' AND column_name = 'name_role'
  ) THEN
    ALTER TABLE public.roles RENAME COLUMN name_role TO name;
  END IF;
END $$;
