/*
  # Schema for Melodify Tamil Music App

  1. New Tables
    - `users` (extends auth.users) - User profiles
    - `artists` - Tamil music artists
    - `songs` - Music tracks
    - `playlists` - User-created playlists
    - `playlist_songs` - Junction table for playlists and songs
    - `purchases` - Premium song purchases

  2. Security
    - Enable RLS on all tables
    - Add appropriate security policies
*/

-- Create tables
CREATE TABLE IF NOT EXISTS artists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  image_url text,
  bio text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS songs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  artist_id uuid REFERENCES artists(id) ON DELETE CASCADE,
  album text,
  genre text,
  duration integer NOT NULL,
  image_url text NOT NULL,
  song_url text NOT NULL,
  is_premium boolean DEFAULT false,
  price numeric,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS playlists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  description text,
  image_url text,
  is_public boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS playlist_songs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  playlist_id uuid REFERENCES playlists(id) ON DELETE CASCADE,
  song_id uuid REFERENCES songs(id) ON DELETE CASCADE,
  position integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id uuid REFERENCES songs(id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  status text CHECK (status IN ('pending', 'completed', 'failed')) DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlist_songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies

-- Artists: Anyone can view
CREATE POLICY "Anyone can view artists" 
  ON artists
  FOR SELECT 
  TO public
  USING (true);

-- Songs: Anyone can view
CREATE POLICY "Anyone can view songs" 
  ON songs
  FOR SELECT 
  TO public
  USING (true);

-- Playlists: Public playlists visible to all, private only to owner
CREATE POLICY "Anyone can view public playlists" 
  ON playlists
  FOR SELECT 
  TO public
  USING (is_public = true OR user_id = auth.uid());

-- Playlist Songs: Anyone can view if playlist is public
CREATE POLICY "Anyone can view songs in public playlists" 
  ON playlist_songs
  FOR SELECT 
  TO public
  USING (
    (SELECT is_public FROM playlists WHERE id = playlist_id) = true OR
    (SELECT user_id FROM playlists WHERE id = playlist_id) = auth.uid()
  );

-- Purchases: Users can only view their own purchases
CREATE POLICY "Users can view their own purchases" 
  ON purchases
  FOR SELECT 
  TO authenticated
  USING (user_id = auth.uid());

-- Playlists: Users can CRUD their own playlists
CREATE POLICY "Users can create playlists" 
  ON playlists
  FOR INSERT 
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their playlists" 
  ON playlists
  FOR UPDATE 
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete their playlists" 
  ON playlists
  FOR DELETE 
  TO authenticated
  USING (user_id = auth.uid());

-- Playlist Songs: Users can CRUD songs in their playlists
CREATE POLICY "Users can add songs to their playlists" 
  ON playlist_songs
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    (SELECT user_id FROM playlists WHERE id = playlist_id) = auth.uid()
  );

CREATE POLICY "Users can update songs in their playlists" 
  ON playlist_songs
  FOR UPDATE 
  TO authenticated
  USING (
    (SELECT user_id FROM playlists WHERE id = playlist_id) = auth.uid()
  );

CREATE POLICY "Users can remove songs from their playlists" 
  ON playlist_songs
  FOR DELETE 
  TO authenticated
  USING (
    (SELECT user_id FROM playlists WHERE id = playlist_id) = auth.uid()
  );

-- Purchases: Users can create their own purchases
CREATE POLICY "Users can create purchases" 
  ON purchases
  FOR INSERT 
  TO authenticated
  WITH CHECK (user_id = auth.uid());