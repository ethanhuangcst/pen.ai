const mysql = require('mysql2/promise');

// Database configuration from the config file
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function testHistoryUpdate() {
  let connection;
  
  try {
    // Create a connection to the database
    connection = await mysql.createConnection(config);
    console.log('Connected to the database!');
    
    // Query the users table to check the pen_content_history values
    console.log('\n=== Checking pen_content_history values ===');
    const [rows] = await connection.execute(
      'SELECT id, name, email, pen_content_history FROM users WHERE id = ?',
      [4] // Ethan Huang's user ID
    );
    
    if (rows.length > 0) {
      const user = rows[0];
      console.log(`User: ${user.name} (${user.email})`);
      console.log(`pen_content_history: ${user.pen_content_history}`);
      console.log(`\n✓ The pen_content_history value is: ${user.pen_content_history}`);
    } else {
      console.log('User not found');
    }
    
  } catch (error) {
    console.error('Error querying database:', error);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\nConnection closed');
    }
  }
}

// Run the script
testHistoryUpdate();
