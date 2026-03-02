const mysql = require('mysql2/promise');

// Database configuration
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function createDefaultPrompts() {
    let connection;
    
    try {
        // Connect to the database
        connection = await mysql.createConnection(config);
        
        console.log('Connected to database');
        
        // Get default prompt from system_config table
        let [configRows] = await connection.execute(
            'SELECT default_prompt_name, default_prompt_text FROM system_config LIMIT 1'
        );
        
        let defaultPromptName = 'Enhance English';
        let defaultPromptText = 'Enhance English for the following text: ';
        
        if (configRows.length > 0) {
            defaultPromptName = configRows[0].default_prompt_name || defaultPromptName;
            defaultPromptText = configRows[0].default_prompt_text || defaultPromptText;
        }
        
        console.log(`Using default prompt: ${defaultPromptName}`);
        
        // Get all users
        let [users] = await connection.execute('SELECT id FROM users');
        console.log(`Found ${users.length} users`);
        
        let createdCount = 0;
        let skippedCount = 0;
        
        // For each user, check if they have a default prompt
        for (const user of users) {
            const userId = user.id;
            
            // Check if user already has a default prompt
            let [promptRows] = await connection.execute(
                'SELECT id FROM prompts WHERE user_id = ? AND is_default = ?',
                [userId, 1]
            );
            
            if (promptRows.length === 0) {
                // Create default prompt for this user
                const promptId = `prompt-${Date.now()}-${userId}`;
                await connection.execute(
                    'INSERT INTO prompts (id, user_id, prompt_name, prompt_text, system_flag, is_default) VALUES (?, ?, ?, ?, ?, ?)',
                    [promptId, userId, defaultPromptName, defaultPromptText, 'PEN', 1]
                );
                createdCount++;
                console.log(`Created default prompt for user ${userId} with ID: ${promptId}`);
            } else {
                skippedCount++;
                console.log(`User ${userId} already has a default prompt, skipping`);
            }
        }
        
        console.log(`\nSummary: Created ${createdCount} default prompts, skipped ${skippedCount} users`);
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        if (connection) {
            await connection.end();
            console.log('Database connection closed');
        }
    }
}

// Run the script
createDefaultPrompts();
