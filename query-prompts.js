const mysql = require('mysql2/promise');

// Database configuration
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function queryPromptsTable() {
  let connection;
  
  try {
    // Create a connection to the database
    connection = await mysql.createConnection(config);
    console.log('Connected to the database!');
    
    // Query the structure of the prompts table
    console.log('\n=== prompts table structure ===');
    const [rows] = await connection.execute('DESCRIBE prompts');
    rows.forEach(row => {
      console.log(`${row.Field} ${row.Type} ${row.Null} ${row.Key} ${row.Default} ${row.Extra}`);
    });
    
    // Query the first few rows of data
    console.log('\n=== Sample data from prompts ===');
    const [dataRows] = await connection.execute('SELECT * FROM prompts LIMIT 3');
    dataRows.forEach((row, index) => {
      console.log(`Row ${index + 1}:`, row);
    });
    
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
queryPromptsTable();
