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
    
    // Query the structure of the prompts table
    console.log('\n=== prompts table structure ===');
    const [rows] = await connection.execute('DESCRIBE prompts');
    // Print in a more compact format
    console.log('Field\tType\tNull\tKey\tDefault\tExtra');
    console.log('---\t---\t---\t---\t---\t---');
    rows.forEach(row => {
      console.log(`${row.Field}\t${row.Type}\t${row.Null}\t${row.Key}\t${row.Default}\t${row.Extra}`);
    });
    
    // Query sample data from the prompts table
    console.log('\n=== Sample data from prompts ===');
    const [dataRows] = await connection.execute('SELECT id, user_id, prompt_name, system_flag FROM prompts LIMIT 5');
    console.log('id\tuser_id\tprompt_name\tsystem_flag');
    console.log('---\t---\t---\t---');
    dataRows.forEach(row => {
      console.log(`${row.id}\t${row.user_id}\t${row.prompt_name}\t${row.system_flag}`);
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
queryDatabase();
