const mysql = require('mysql2/promise');

// Database configuration
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function queryUsersTable() {
  let connection;
  
  try {
    // Create a connection to the database
    connection = await mysql.createConnection(config);
    console.log('Connected to the database!');
    
    // Query the structure of the users table
    console.log('\n=== users table structure ===');
    const [rows] = await connection.execute('DESCRIBE wingman_db.users');
    // Print in a formatted table
    console.log('Field\t\tType\t\tNull\tKey\tDefault\tExtra');
    console.log('---\t\t---\t\t---\t---\t---\t---');
    rows.forEach(row => {
      console.log(`${row.Field}\t\t${row.Type}\t\t${row.Null}\t${row.Key}\t${row.Default}\t${row.Extra}`);
    });
    
    // Query total users count
    console.log('\n=== Users count ===');
    const [countRows] = await connection.execute('SELECT COUNT(*) as count FROM wingman_db.users');
    console.log(`Total users: ${countRows[0].count}`);
    
  } catch (error) {
    console.error('Error querying database:', error);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\nConnection closed');
    }
  }
}

// Run the query
queryUsersTable();