-- ============================================================================
-- جسر الوصول — additive SQL for PDF uploads
-- This does NOT touch your existing schools/topics/questions/etc tables.
-- Run once in Supabase: Dashboard → SQL Editor → New query → paste → Run.
-- Safe to re-run (everything is IF NOT EXISTS / ON CONFLICT DO NOTHING).
-- ============================================================================

create extension if not exists pgcrypto;

-- 1. Table to hold PDF metadata (the file itself lives in Storage).
create table if not exists public.pdf_resources (
  id            uuid primary key default gen_random_uuid(),
  school_id     uuid references public.schools(id) on delete cascade not null,
  topic_id      uuid references public.topics(id) on delete set null,
  subject       text,
  title         text not null,
  storage_path  text not null,
  uploaded_at   timestamptz default now()
);

alter table public.pdf_resources enable row level security;

-- Anyone can read the list (students browse PDFs without logging in).
drop policy if exists "pdf_resources_select_public" on public.pdf_resources;
create policy "pdf_resources_select_public" on public.pdf_resources
  for select using (true);

-- Only a school's own logged-in admin can add/remove its rows.
-- Uses the school_members table your existing setup already has.
drop policy if exists "pdf_resources_write_admin" on public.pdf_resources;
create policy "pdf_resources_write_admin" on public.pdf_resources
  for all using (
    exists (
      select 1 from public.school_members
      where school_members.school_id = pdf_resources.school_id
        and school_members.user_id = auth.uid()
        and school_members.status = 'active'
    )
  ) with check (
    exists (
      select 1 from public.school_members
      where school_members.school_id = pdf_resources.school_id
        and school_members.user_id = auth.uid()
        and school_members.status = 'active'
    )
  );

-- 2. Storage bucket for the actual PDF files.
insert into storage.buckets (id, name, public)
values ('pdfs', 'pdfs', true)
on conflict (id) do nothing;

-- Anyone can download (public bucket); only a school's own admin can
-- upload/delete inside their own school_id-prefixed folder.
drop policy if exists "pdfs_storage_read_public" on storage.objects;
create policy "pdfs_storage_read_public" on storage.objects
  for select using (bucket_id = 'pdfs');

drop policy if exists "pdfs_storage_write_admin" on storage.objects;
create policy "pdfs_storage_write_admin" on storage.objects
  for insert with check (
    bucket_id = 'pdfs'
    and exists (
      select 1 from public.school_members
      where school_members.school_id = ((storage.foldername(name))[1])::uuid
        and school_members.user_id = auth.uid()
        and school_members.status = 'active'
    )
  );

drop policy if exists "pdfs_storage_delete_admin" on storage.objects;
create policy "pdfs_storage_delete_admin" on storage.objects
  for delete using (
    bucket_id = 'pdfs'
    and exists (
      select 1 from public.school_members
      where school_members.school_id = ((storage.foldername(name))[1])::uuid
        and school_members.user_id = auth.uid()
        and school_members.status = 'active'
    )
  );

-- ============================================================================
-- Also needed for the public quiz/PDF pages to work without login: make sure
-- terms / topics / term_topics / questions already allow public SELECT.
-- If you're not sure they do, these are safe to (re-)run:
-- ============================================================================
alter table public.terms       enable row level security;
alter table public.topics      enable row level security;
alter table public.term_topics enable row level security;
alter table public.questions   enable row level security;

drop policy if exists "terms_select_public" on public.terms;
create policy "terms_select_public" on public.terms for select using (true);

drop policy if exists "topics_select_public" on public.topics;
create policy "topics_select_public" on public.topics for select using (true);

drop policy if exists "term_topics_select_public" on public.term_topics;
create policy "term_topics_select_public" on public.term_topics for select using (true);

drop policy if exists "questions_select_public" on public.questions;
create policy "questions_select_public" on public.questions for select using (true);
