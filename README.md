# FamilyHub — Private Family Management

Premium, minimalist family management site. All HTML (inline CSS + JS). Supabase for auth.

## Design

- Inspired by modern clean product sites (Instrument Serif + Geist)
- Soft Google-like ambient backlight / fog
- No emojis — SVG icons only
- Subtle entrance animations
- Consistent layout across all pages

## Pages

| File | Description |
|------|-------------|
| `index.html` | Landing page |
| `login.html` | Sign-in only (no public signup) |
| `dash.html` | Full dashboard — Overview, **Calendar**, **Tasks**, **Notes**, **Members** |
| `acc.html` | Account — change name, pronouns, role, designation |

## Features in Dashboard

- **Calendar** — month view, select day, add / remove events
- **Tasks** — add, complete, delete (persisted in localStorage)
- **Notes** — shared notes with timestamps
- **Members** — family member cards (name, role, pronouns)
- Data is stored in `localStorage` for demo. Replace with Supabase tables when ready.

## Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Authentication → Users → Add user (email + password) for each family member
3. In **login.html**, **dash.html** and **acc.html** replace:

```js
const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

4. Open `index.html` in a browser

## Optional: real tables

```sql
create table family_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  full_name text,
  pronouns text,
  role text,
  designation text default 'Member',
  created_at timestamptz default now()
);

alter table family_members enable row level security;
create policy "Authenticated can read"
  on family_members for select to authenticated using (true);
```

Then replace the localStorage helpers in the scripts with Supabase queries.
