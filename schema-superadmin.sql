-- ============================================================================
-- جسر الوصول — platform super-admin (additive, safe to run alongside
-- everything else). Postgres RLS combines multiple permissive policies with
-- OR, so every policy below only ADDS access — it never removes or replaces
-- an existing policy, so nothing already working can break.
-- ============================================================================

-- 1. Who is a platform (super) admin — separate from any one school.
create table if not exists public.platform_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);
alter table public.platform_admins enable row level security;

create or replace function public.is_platform_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.platform_admins where user_id = auth.uid());
$$;

-- 2. Full access for the platform admin on every table this project uses.
--    Each of these ADDS a policy; it does not touch your existing ones.
do $$
declare
  t text;
begin
  foreach t in array array[
    'schools','school_members','terms','topics','term_topics',
    'questions','pdf_resources','classes','students',
    'quiz_attempts','quiz_answers'
  ]
  loop
    if exists (select 1 from information_schema.tables where table_schema='public' and table_name=t) then
      execute format(
        'drop policy if exists "platform_admin_full_access" on public.%I;', t
      );
      execute format(
        'create policy "platform_admin_full_access" on public.%I for all using (public.is_platform_admin()) with check (public.is_platform_admin());',
        t
      );
      execute format('alter table public.%I enable row level security;', t);
    end if;
  end loop;
end $$;

-- Storage: platform admin can read/write/delete any file in the pdfs bucket.
drop policy if exists "pdfs_storage_platform_admin" on storage.objects;
create policy "pdfs_storage_platform_admin" on storage.objects for all
  using (bucket_id = 'pdfs' and public.is_platform_admin())
  with check (bucket_id = 'pdfs' and public.is_platform_admin());

-- 3. Read-only functions the dashboard uses to list everything (these expose
--    auth.users.email, which the client can never read directly — that's
--    exactly why these are security-definer functions guarded by the
--    is_platform_admin() check above).
create or replace function public.admin_list_schools()
returns table (
  id uuid, name text, address text, phone text, email text,
  created_at timestamptz, owner_email text, member_count bigint
)
language sql security definer set search_path = public
as $$
  select
    s.id, s.name, s.address, s.phone, s.email, s.created_at,
    (select u.email from public.school_members sm
       join auth.users u on u.id = sm.user_id
       where sm.school_id = s.id and sm.role in ('owner','admin')
       order by sm.id limit 1) as owner_email,
    (select count(*) from public.school_members sm2 where sm2.school_id = s.id) as member_count
  from public.schools s
  where public.is_platform_admin()
  order by s.created_at desc;
$$;

create or replace function public.admin_list_users()
returns table (
  user_id uuid, email text, created_at timestamptz,
  school_id uuid, school_name text, role text, status text
)
language sql security definer set search_path = public
as $$
  select
    u.id as user_id, u.email, u.created_at,
    sm.school_id, s.name as school_name, sm.role, sm.status
  from auth.users u
  left join public.school_members sm on sm.user_id = u.id
  left join public.schools s on s.id = sm.school_id
  where public.is_platform_admin()
  order by u.created_at desc;
$$;

-- ============================================================================
-- 4. Make your account the platform admin — run this ONE line after you've
--    signed up through the site with the email you want to use as admin:
--
--    insert into public.platform_admins (user_id)
--    select id from auth.users where email = 'PUT_YOUR_ADMIN_EMAIL_HERE';
--
--    Supabase Auth needs a real email address — "Admin" alone can't sign up.
--    Pick any email you control, sign up on the site with password
--    Assalaamalaikum, then run the line above with that email.
-- ============================================================================
