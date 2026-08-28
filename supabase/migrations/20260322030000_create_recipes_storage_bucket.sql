-- Create storage bucket for recipe images if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('recipes', 'recipes', true)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for storage bucket

-- Allow public read access to recipe images
CREATE POLICY "Public Read Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'recipes');

-- Allow authenticated users to upload/insert recipe images
CREATE POLICY "Authenticated Upload Access"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'recipes');

-- Allow authenticated users to update recipe images
CREATE POLICY "Authenticated Update Access"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'recipes')
WITH CHECK (bucket_id = 'recipes');

-- Allow authenticated users to delete recipe images
CREATE POLICY "Authenticated Delete Access"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'recipes');
