# FamilyHub — Private Family Management

Simple, minimalist, premium family management site (HTML only — no separate CSS/JS files). Uses Supabase for authentication and data.

## Files

- `index.html` — Landing page
- `login.html` — Sign-in only (no public signup)
- `dash.html` — Protected dashboard

## Setup

1. Create a project at [supabase.com](https://supabase.com).
2. In Authentication → Providers, keep Email enabled.
3. **Do not enable public sign-up** if you want fully private access (or leave it on and simply never share a signup link). Add family members yourself:
   - Authentication → Users → Add user (email + password), **or**
   - Use the Supabase dashboard / SQL to insert users.
4. Open `login.html` and `dash.html` and replace:

```js
const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

with your Project URL and anon/public key (Settings → API).

5. (Optional) Create tables, e.g.:

```sql
create table family_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  full_name text,
  role text default 'member',
  created_at timestamptz default now()
);

-- Enable RLS and add policies so only authenticated users can read
alter table family_members enable row level security;
create policy "Family can read members"
  on family_members for select
  to authenticated
  using (true);
```

6. Open `index.html` in a browser (or serve the folder with any static host).

## Design notes

- No gradients on UI elements (only very soft ambient light for the “side light / fog” effect).
- Google-inspired minimalist palette, soft layered shadows, clean typography.
- All styles and scripts are inline as requested.

## Security reminder

- Never put the **service_role** key in the frontend.
- Use Row Level Security (RLS) on every table.
- Keep the anon key restricted by RLS policies.
