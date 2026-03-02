-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    user_id INT NOT NULL,
    content_history_count INT NOT NULL DEFAULT 10,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Add index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);

-- Insert default preferences for existing users
INSERT INTO user_preferences (id, user_id, content_history_count) 
SELECT CONCAT('preference-', UUID()), id, 10 
FROM users 
WHERE NOT EXISTS (
    SELECT 1 FROM user_preferences WHERE user_preferences.user_id = users.id
);
