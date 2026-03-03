const mysql = require('mysql2/promise');

async function checkDatabaseSchema() {
    console.log('=== Checking database schema ===');
    
    try {
        // Create connection
        const connection = await mysql.createConnection({
            host: '101.132.156.250',
            port: 33320,
            user: 'wingmandev',
            password: 'Wing123_Man',
            database: 'wingman_db'
        });
        
        console.log('Connected to database');
        
        // Get all tables
        const [tablesResult] = await connection.execute('SHOW TABLES');
        const tables = tablesResult.map(row => Object.values(row)[0]);
        
        console.log('Found tables:', tables);
        
        // Prepare schema content
        let schemaContent = '# Database Structure\n\n';
        schemaContent += '## Overview\n';
        schemaContent += 'This document describes the database structure for the Pen AI application. The database contains tables for users, AI connections, prompts, chats, chat messages, and AI providers.\n\n';
        schemaContent += '## Tables\n\n';
        
        // Get structure for each table
        for (const table of tables) {
            console.log(`\n=== Checking table: ${table} ===`);
            
            const [columnsResult] = await connection.execute(`DESCRIBE ${table}`);
            
            schemaContent += `### ${table}\n\n`;
            schemaContent += '| Column | Type | Null | Key | Default | Extra |\n';
            schemaContent += '|--------|------|------|-----|---------|-------|\n';
            
            for (const column of columnsResult) {
                schemaContent += `| ${column.Field} | ${column.Type} | ${column.Null} | ${column.Key} | ${column.Default || ''} | ${column.Extra || ''} |\n`;
            }
            
            schemaContent += '\n';
        }
        
        // Add relationships section
        schemaContent += '## Relationships\n\n';
        schemaContent += '```\n';
        schemaContent += '┌────────────┐     ┌────────────┐     ┌────────────┐\n';
        schemaContent += '│   users    │────▶│ ai_connections │────▶│ ai_providers │\n';
        schemaContent += '└────────────┘     └────────────┘     └────────────┘\n';
        schemaContent += '      │                   │\n';
        schemaContent += '      │                   │\n';
        schemaContent += '      ▼                   ▼\n';
        schemaContent += '┌────────────┐     ┌────────────┐     ┌───────────────┐\n';
        schemaContent += '│   chats    │────▶│chat_messages│     │content_history│\n';
        schemaContent += '└────────────┘     └────────────┘     └───────────────┘\n';
        schemaContent += '      │                                   ▲\n';
        schemaContent += '      │                                   │\n';
        schemaContent += '      ▼                                   │\n';
        schemaContent += '┌────────────┐                           │\n';
        schemaContent += '│  prompts   │───────────────────────────┘\n';
        schemaContent += '└────────────┘\n';
        schemaContent += '```\n\n';
        
        // Add key points section
        schemaContent += '## Key Points\n\n';
        schemaContent += '1. **User Management**: The `users` table stores all user information, including authentication details and profile data.\n\n';
        schemaContent += '2. **AI Connections**: The `ai_connections` table stores API keys and provider information for each user\'s AI services.\n\n';
        schemaContent += '3. **Chat System**: The `chats` and `chat_messages` tables handle the chat functionality, allowing users to have multiple conversations with AI providers.\n\n';
        schemaContent += '4. **Prompt Management**: The `prompts` table stores user-created prompts that can be reused in conversations. The `is_default` column indicates whether a prompt is the default prompt for a user.\n\n';
        schemaContent += '5. **AI Provider Configuration**: The `ai_providers` table stores configuration information for different AI service providers.\n\n';
        schemaContent += '6. **Content History**: The `content_history` table stores records of enhanced content, including the original content, enhanced content, prompt used, and AI provider.\n\n';
        schemaContent += '7. **System Configuration**: The `system_config` table stores global system settings, including default prompt information and content history count options (LOW, MEDIUM, HIGH) that can be centrally managed.\n\n';
        schemaContent += '8. **Data Consistency**: Foreign key relationships ensure data integrity between related tables.\n\n';
        schemaContent += '9. **Timestamps**: Most tables include `created_at` and `updated_at` timestamps for tracking when records were created or modified.\n\n';
        schemaContent += '10. **System Flag**: The `system_flag` column in several tables indicates whether records were created by the Wingman app or the Pen app.\n\n';
        
        // Add security considerations section
        schemaContent += '## Security Considerations\n\n';
        schemaContent += '- Passwords are stored as plain text in the `password` column. In a production environment, these should be hashed using a secure hashing algorithm.\n';
        schemaContent += '- API keys in the `ai_connections` table are stored as plain text. These should be encrypted or stored in a secure vault in a production environment.\n';
        schemaContent += '- Email addresses are unique to prevent duplicate user accounts.\n';
        
        // Write to file
        const fs = require('fs');
        fs.writeFileSync('./Docs/tech-design/db_structure.md', schemaContent);
        
        console.log('\n=== Database schema updated in db_structure.md ===');
        
        // Close connection
        await connection.end();
        
    } catch (error) {
        console.error('Error checking database schema:', error);
    }
}

// Run the script
checkDatabaseSchema();
