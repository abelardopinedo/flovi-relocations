create table relocation_requests (
  id uuid primary key default gen_random_uuid(),
  origin text not null,
  destination text not null,
  move_date date not null,
  notes text,
  status text not null default 'open', -- open | booked | completed
  dispatcher_id uuid references auth.users(id),
  driver_id uuid references auth.users(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Row Level Security
alter table relocation_requests enable row level security;

-- allow any authenticated user to read all requests
create policy "read all" on relocation_requests
  for select using (auth.role() = 'authenticated');

-- allow any authenticated user to insert (dispatcher creates requests)
create policy "insert own" on relocation_requests
  for insert with check (auth.uid() = dispatcher_id);

-- allow any authenticated user to update (dispatcher edits, driver books)
create policy "update all" on relocation_requests
  for update using (auth.role() = 'authenticated');