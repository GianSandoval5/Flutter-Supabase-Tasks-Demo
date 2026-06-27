-- Flutter + Supabase Tasks Demo
-- Charla 2: programar una Edge Function con pg_cron + pg_net.
--
-- IMPORTANTE:
-- 1. Ejecuta primero `supabase/03_task_automation.sql`.
-- 2. Despliega la Edge Function `task-automation`.
-- 3. Guarda los secretos en Supabase Vault antes de ejecutar este archivo:
--
--    select vault.create_secret('https://TU-PROYECTO.supabase.co', 'project_url');
--    select vault.create_secret('MISMO_VALOR_DE_AUTOMATION_SECRET', 'task_automation_secret');
--
-- pg_cron usa UTC. La expresion `0 13 * * *` equivale a 08:00 en Peru
-- cuando Peru esta en UTC-5.

create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists supabase_vault cascade;

do $$
begin
  if not exists (
    select 1 from vault.decrypted_secrets where name = 'project_url'
  ) then
    raise exception 'Falta el secreto project_url en Vault.';
  end if;

  if not exists (
    select 1 from vault.decrypted_secrets where name = 'task_automation_secret'
  ) then
    raise exception 'Falta el secreto task_automation_secret en Vault.';
  end if;
end $$;

do $$
begin
  if exists (
    select 1 from cron.job where jobname = 'daily-task-automation-edge'
  ) then
    perform cron.unschedule('daily-task-automation-edge');
  end if;
end $$;

select cron.schedule(
  'daily-task-automation-edge',
  '0 13 * * *',
  $$
  select net.http_post(
    url := (
      select decrypted_secret
      from vault.decrypted_secrets
      where name = 'project_url'
    ) || '/functions/v1/task-automation',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-automation-secret', (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = 'task_automation_secret'
      )
    ),
    body := jsonb_build_object(
      'run_type', 'cron',
      'source', 'pg_cron',
      'notes', 'Ejecucion diaria programada para la charla 2'
    )
  ) as request_id;
  $$
);

-- Para pausar o reemplazar el job:
-- select cron.unschedule('daily-task-automation-edge');

-- Para revisar ejecuciones:
-- select * from public.task_automation_runs order by created_at desc;
