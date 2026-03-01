const mysql = require('mysql2/promise');

// Database configuration
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

// Default prompt text
const defaultPromptText = "You are Pen, an AI writing assistant designed to help users improve their writing. Your goal is to analyze the provided text and enhance it while maintaining the original meaning and intent.";
const defaultPromptName = "Default Prompt";
const defaultPromptId = "DEFAULT";

async function createDefaultPrompt(connection, userId) {
  console.log(`Creating default prompt for user ${userId}...`);
  
  // Generate a unique ID for this user's default prompt
  const uniqueId = `prompt-${Date.now()}-${userId}`;
  
  const query = `
    INSERT INTO prompts (id, user_id, prompt_name, prompt_text, system_flag)
    VALUES (?, ?, ?, ?, ?)
  `;
  
  await connection.execute(query, [
    uniqueId,
    userId,
    defaultPromptName,
    defaultPromptText,
    "PEN"
  ]);
  
  console.log(`Default prompt created for user ${userId} with ID: ${uniqueId}`);
}

async function checkUsersForDefaultPrompt() {
  let connection;
  
  try {
    connection = await mysql.createConnection(config);
    console.log('Connected to the database!');
    
    // Get all users
    const [users] = await connection.execute('SELECT id, email FROM users');
    console.log(`Found ${users.length} users`);
    
    let usersWithMissingDefaultPrompt = [];
    
    // Check each user
    for (const user of users) {
      const { id: userId, email } = user;
      
      // Check if user has a default prompt
      const [prompts] = await connection.execute(
        'SELECT id, prompt_name FROM prompts WHERE user_id = ? AND (id = ? OR prompt_name = ?)',
        [userId, defaultPromptId, defaultPromptName]
      );
      
      if (prompts.length === 0) {
        console.log(`User ${email} (ID: ${userId}) is missing default prompt`);
        usersWithMissingDefaultPrompt.push(userId);
      } else {
        console.log(`User ${email} (ID: ${userId}) has default prompt`);
      }
    }
    
    // Create default prompts for users who don't have them
    if (usersWithMissingDefaultPrompt.length > 0) {
      console.log(`\nCreating default prompts for ${usersWithMissingDefaultPrompt.length} users...`);
      for (const userId of usersWithMissingDefaultPrompt) {
        await createDefaultPrompt(connection, userId);
      }
      console.log('\nDefault prompts created successfully');
    } else {
      console.log('\nAll users already have default prompts');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\nConnection closed');
    }
  }
}

// Run the check
checkUsersForDefaultPrompt();
