# Supabase Setup Instructions

## Creating the Users Table

The app requires a `users` table to store user profiles and nicknames. Follow these steps:

### Method 1: Using Supabase Dashboard SQL Editor

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy and paste the contents of `migrations/001_create_users_table.sql`
5. Click **Run** to execute the query
6. Then run `migrations/002_insert_existing_users.sql` to create profiles for existing users

### Method 2: Using Supabase CLI

If you have Supabase CLI installed:

```bash
supabase db push
```

## What the migration does:

1. Creates a `users` table with:
   - `id` (UUID) - linked to auth.users
   - `username` (TEXT) - for storing nicknames
   - `avatar_url` (TEXT) - for future profile pictures
   - `created_at` and `updated_at` timestamps

2. Sets up Row Level Security (RLS) policies:
   - Users can only view their own profile
   - Users can only update their own profile
   - Users can only insert their own profile

3. Creates a trigger to automatically create a user profile when a new auth user is created

4. Creates an index on username for better query performance

## Verifying the setup:

After running the migrations, you can verify:

1. In SQL Editor, run:
   ```sql
   SELECT * FROM public.users;
   ```

2. Check that your anonymous users now have entries in the users table

3. The app should now be able to save and display Korean nicknames!