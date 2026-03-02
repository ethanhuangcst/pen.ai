const mysql = require('mysql2/promise');

// Database configuration from the config file
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function createSystemConfigTable() {
  let connection;
  
  try {
    // Create a connection to the database
    connection = await mysql.createConnection(config);
    console.log('Connected to the database!');
    
    // Create system_config table
    console.log('Creating system_config table...');
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS system_config (
        id INT PRIMARY KEY AUTO_INCREMENT,
        default_prompt_name VARCHAR(255),
        default_prompt_text TEXT,
        content_history_count_low INT NOT NULL DEFAULT 10,
        content_history_count_medium INT NOT NULL DEFAULT 20,
        content_history_count_high INT NOT NULL DEFAULT 40,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    console.log('system_config table created successfully!');
    
    // Insert default values if table is newly created
    console.log('Inserting default values...');
    await connection.execute(`
      INSERT INTO system_config (default_prompt_name, default_prompt_text, content_history_count_low, content_history_count_medium, content_history_count_high)
      SELECT 'Enhance English', 'Enhance English for the following text: ', 10, 20, 40
      WHERE NOT EXISTS (SELECT 1 FROM system_config)
    `);
    console.log('Default values inserted successfully!');
    
    // Verify the table structure
    console.log('\n=== system_config table structure ===');
    const [structureRows] = await connection.execute('DESCRIBE system_config');
    console.log('Field\tType\tNull\tKey\tDefault\tExtra');
    console.log('---\t---\t---\t---\t---\t---');
    structureRows.forEach(row => {
      console.log(`${row.Field}\t${row.Type}\t${row.Null}\t${row.Key}\t${row.Default}\t${row.Extra}`);
    });
    
    // Verify the data
    console.log('\n=== system_config table data ===');
    const [dataRows] = await connection.execute('SELECT * FROM system_config');
    dataRows.forEach(row => {
      console.log(`ID: ${row.id}`);
      console.log(`Default Prompt Name: ${row.default_prompt_name}`);
      console.log(`Default Prompt Text: ${row.default_prompt_text}`);
      console.log(`Content History Count Low: ${row.content_history_count_low}`);
      console.log(`Content History Count Medium: ${row.content_history_count_medium}`);
      console.log(`Content History Count High: ${row.content_history_count_high}`);
      console.log(`Created At: ${row.created_at}`);
      console.log(`Updated At: ${row.updated_at}`);
      console.log('---');
    });
    
  } catch (error) {
    console.error('Error creating system_config table:', error);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\nConnection closed');
    }
  }
}

// Run the function
createSystemConfigTable();