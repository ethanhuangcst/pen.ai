import Foundation

// Database configuration
enum DatabaseConfig {
    static let host = "101.132.156.250"
    static let port = 33320
    static let username = "wingmandev"
    static let password = "Wing123_Man"
    static let databaseName = "wingman_db"
}

// Default prompt constants
enum DefaultPrompt {
    static let id = "DEFAULT"
    static let name = "Default Prompt"
    static let text = "You are Pen, an AI writing assistant designed to help users improve their writing. Your goal is to analyze the provided text and enhance it while maintaining the original meaning and intent."
    static let systemFlag = "PEN"
}

// Run the check
func runCheck() {
    print("Starting default prompt check...")
    
    // Build the shell command
    let command = """
    node -e "
    const mysql = require('mysql2/promise');
    
    const config = {
      host: '\(DatabaseConfig.host)',
      port: \(DatabaseConfig.port),
      user: '\(DatabaseConfig.username)',
      password: '\(DatabaseConfig.password)',
      database: '\(DatabaseConfig.databaseName)'
    };
    
    const defaultPromptText = '\(DefaultPrompt.text)';
    const defaultPromptName = '\(DefaultPrompt.name)';
    const defaultPromptId = '\(DefaultPrompt.id)';
    
    async function createDefaultPrompt(connection, userId) {
      console.log(`Creating default prompt for user ${userId}...`);
      
      const query = `
        INSERT INTO prompts (id, user_id, prompt_name, prompt_text, system_flag)
        VALUES (?, ?, ?, ?, ?)
      `;
      
      await connection.execute(query, [
        defaultPromptId,
        userId,
        defaultPromptName,
        defaultPromptText,
        '\(DefaultPrompt.systemFlag)'
      ]);
      
      console.log(`Default prompt created for user ${userId}`);
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
    ""
    """
    
    // Execute the command
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    task.launch()
    task.waitUntilExit()
    
    // Read output
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        print(output)
    }
    
    print("Check completed.")
}

// Run the check
runCheck()
