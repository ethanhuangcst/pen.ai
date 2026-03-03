const mysql = require('mysql2/promise');

async function testHistoryUpdate() {
  try {
    // Create database connection
    const connection = await mysql.createConnection({
      host: '101.132.156.250',
      port: 33320,
      user: 'wingmandev',
      password: 'Wing123_Man',
      database: 'wingman_db'
    });
    
    console.log('Connected to database');
    
    // Get current value for user with id 4
    const [currentRows] = await connection.execute(
      'SELECT pen_content_history FROM users WHERE id = ?',
      [4]
    );
    
    const currentValue = currentRows[0].pen_content_history;
    console.log(`Current pen_content_history for user 4: ${currentValue}`);
    
    // Test updating with integer value (simulating my fix)
    const newValue = currentValue === 10 ? 20 : 10;
    console.log(`Updating to: ${newValue}`);
    
    // Using parameterized query with integer value
    const [updateResult] = await connection.execute(
      'UPDATE users SET pen_content_history = ? WHERE id = ?',
      [newValue, 4]
    );
    
    console.log(`Update result: ${updateResult.affectedRows} row(s) affected`);
    
    // Verify the update
    const [updatedRows] = await connection.execute(
      'SELECT pen_content_history FROM users WHERE id = ?',
      [4]
    );
    
    const updatedValue = updatedRows[0].pen_content_history;
    console.log(`Updated pen_content_history for user 4: ${updatedValue}`);
    
    if (updatedValue === newValue) {
      console.log('✅ SUCCESS: History count updated correctly!');
    } else {
      console.log('❌ FAILED: History count not updated correctly!');
    }
    
    // Close connection
    await connection.end();
    console.log('Connection closed');
    
  } catch (error) {
    console.error('Error:', error);
  }
}

testHistoryUpdate();
