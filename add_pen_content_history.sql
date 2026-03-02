-- Add pen_content_history column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS pen_content_history INT NOT NULL DEFAULT 10;

-- Update existing users to have the default value if they don't already have it
UPDATE users SET pen_content_history = 10 WHERE pen_content_history IS NULL;

-- Verify the column was added
DESCRIBE users;

-- Check the values
SELECT id, name, email, pen_content_history FROM users;
