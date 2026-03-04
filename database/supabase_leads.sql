-- Base de captacao de clientes (leads) para Supabase/Postgres
-- Execute este arquivo no SQL Editor do projeto no supabase.com

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text,
  whatsapp text,
  company_name text,
  role_title text,
  interest text not null,
  message text,
  source text not null default 'site',
  campaign text,
  landing_page text,
  status text not null default 'novo'
    check (status in ('novo', 'qualificando', 'contatado', 'proposta', 'convertido', 'perdido')),
  score integer not null default 0 check (score between 0 and 100),
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_term text,
  utm_content text,
  consent_lgpd boolean not null default false,
  consent_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint leads_contact_required check (
    nullif(trim(coalesce(email, '')), '') is not null
    or nullif(trim(coalesce(whatsapp, '')), '') is not null
  )
);

drop trigger if exists trg_leads_set_updated_at on public.leads;
create trigger trg_leads_set_updated_at
before update on public.leads
for each row execute function public.set_updated_at();

create unique index if not exists leads_email_unique_idx
  on public.leads (lower(email))
  where email is not null and trim(email) <> '';

create unique index if not exists leads_whatsapp_unique_idx
  on public.leads (regexp_replace(whatsapp, '\D', '', 'g'))
  where whatsapp is not null and trim(whatsapp) <> '';

create index if not exists leads_status_created_idx
  on public.leads (status, created_at desc);

create index if not exists leads_source_created_idx
  on public.leads (source, created_at desc);

create table if not exists public.lead_interactions (
  id bigserial primary key,
  lead_id uuid not null references public.leads(id) on delete cascade,
  channel text not null
    check (channel in ('whatsapp', 'email', 'ligacao', 'reuniao', 'instagram', 'outro')),
  interaction_type text not null
    check (interaction_type in ('tentativa', 'resposta', 'reuniao', 'proposta', 'fechamento', 'observacao')),
  notes text,
  happened_at timestamptz not null default now(),
  created_by text,
  created_at timestamptz not null default now()
);

create index if not exists lead_interactions_lead_date_idx
  on public.lead_interactions (lead_id, happened_at desc);

create or replace view public.vw_leads_funil as
select
  status,
  count(*) as total_leads,
  round(avg(score)::numeric, 1) as score_medio
from public.leads
group by status
order by
  case status
    when 'novo' then 1
    when 'qualificando' then 2
    when 'contatado' then 3
    when 'proposta' then 4
    when 'convertido' then 5
    when 'perdido' then 6
    else 99
  end;

alter table public.leads enable row level security;
alter table public.lead_interactions enable row level security;

grant usage on schema public to anon, authenticated;
grant insert on public.leads to anon;
grant select, update on public.leads to authenticated;
grant select, insert, update, delete on public.lead_interactions to authenticated;

drop policy if exists "anon_can_insert_leads" on public.leads;
create policy "anon_can_insert_leads"
on public.leads
for insert
to anon
with check (
  consent_lgpd = true
  and status = 'novo'
  and score = 0
  and length(trim(full_name)) >= 3
  and (
    nullif(trim(coalesce(email, '')), '') is not null
    or nullif(trim(coalesce(whatsapp, '')), '') is not null
  )
);

drop policy if exists "authenticated_can_manage_leads" on public.leads;
create policy "authenticated_can_manage_leads"
on public.leads
for all
to authenticated
using (true)
with check (true);

drop policy if exists "authenticated_can_manage_interactions" on public.lead_interactions;
create policy "authenticated_can_manage_interactions"
on public.lead_interactions
for all
to authenticated
using (true)
with check (true);

comment on table public.leads is 'Cadastro principal de leads para captacao comercial.';
comment on table public.lead_interactions is 'Historico de contatos e etapas com cada lead.';
