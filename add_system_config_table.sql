-- Add system_config table
CREATE TABLE IF NOT EXISTS system_config (
    id INT PRIMARY KEY AUTO_INCREMENT,
    default_prompt_name VARCHAR(255),
    default_prompt_text TEXT,
    content_history_count_low INT NOT NULL DEFAULT 10,
    content_history_count_medium INT NOT NULL DEFAULT 20,
    content_history_count_high INT NOT NULL DEFAULT 40,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default values if table is newly created
INSERT INTO system_config (default_prompt_name, default_prompt_text, content_history_count_low, content_history_count_medium, content_history_count_high)
SELECT 'Enhance English', 'Enhance English for the following text: ', 10, 20, 40
WHERE NOT EXISTS (SELECT 1 FROM system_config);

-- Verify the table was created
DESCRIBE system_config;

-- Check the values
SELECT * FROM system_config;