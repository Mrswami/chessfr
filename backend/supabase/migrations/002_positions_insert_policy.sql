-- Allow authenticated users to insert new positions (e.g. when training on a FEN not yet in DB).
CREATE POLICY "Authenticated users can insert positions"
    ON positions FOR INSERT
    TO authenticated
    WITH CHECK (true);
