const mysql = require('mysql2/promise');

// Database configuration from the config file
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function queryDatabase() {
  let connection;
  
  try {
    // Create a connection to the database
    connection = await mysql.createConnection(config);
    console.log('Connected to the database!');
    
    // Query the structure of the ai_connections table
    console.log('\n=== ai_connections table structure ===');
    const [rows] = await connection.execute('DESCRIBE ai_connections');
    console.table(rows);
    
    // Query sample data from the ai_connections table
    console.log('\n=== Sample data from ai_connections ===');
    const [dataRows] = await connection.execute('SELECT * FROM ai_connections LIMIT 5');
    console.table(dataRows);
    
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
queryDatabase();
