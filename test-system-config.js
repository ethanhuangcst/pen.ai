const mysql = require('mysql2/promise');

// Database configuration
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function testSystemConfig() {
  let connection;
  
  try {
    // Create a connection to the database
    connection = await mysql.createConnection(config);
    console.log('Connected to the database!');
    
    // Query system config
    console.log('Querying system_config table...');
    const [rows] = await connection.execute(
      'SELECT default_prompt_name, default_prompt_text, content_history_count_low, content_history_count_medium, content_history_count_high FROM system_config LIMIT 1'
    );
    
    if (rows.length > 0) {
      const row = rows[0];
      console.log('\n=== System Configuration ===');
      console.log('Default Prompt Name:', row.default_prompt_name);
      console.log('Default Prompt Text:', row.default_prompt_text);
      console.log('Content History Count Low:', row.content_history_count_low);
      console.log('Content History Count Medium:', row.content_history_count_medium);
      console.log('Content History Count High:', row.content_history_count_high);
    } else {
      console.log('No system_config record found');
    }
    
  } catch (error) {
    console.error('Error testing system config:', error);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\nConnection closed');
    }
  }
}

// Run the test
testSystemConfig();
