-- Existing installations may have renamed these keys manually. Application
-- auth and RBAC queries use the original schema names. Renames preserve FKs.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='roles' AND column_name='id_role')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='roles' AND column_name='id') THEN
    ALTER TABLE roles RENAME COLUMN id_role TO id;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='permissions' AND column_name='id_permission')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='permissions' AND column_name='id') THEN
    ALTER TABLE permissions RENAME COLUMN id_permission TO id;
  END IF;
END $$;
