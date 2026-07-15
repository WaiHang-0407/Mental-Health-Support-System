alter table public.user_activity_paths
add column if not exists current_page_number integer not null default 1,
add column if not exists completed_page_count integer not null default 0,
add column if not exists last_opened_at timestamptz,
add column if not exists completed_at timestamptz,
add column if not exists is_saved boolean not null default false,
add column if not exists saved_at timestamptz;
