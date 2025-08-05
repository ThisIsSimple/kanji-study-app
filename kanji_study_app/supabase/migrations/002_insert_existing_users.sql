-- Insert profiles for existing auth users who don't have a profile yet
INSERT INTO public.users (id)
SELECT id 
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users)
ON CONFLICT (id) DO NOTHING;