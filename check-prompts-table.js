const mysql = require('mysql2/promise');

// Database configuration
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function checkPromptsTable() {
    let connection;
    
    try {
        connection = await mysql.createConnection(config);
        console.log('Connected to database');
        
        // Check table structure
        console.log('=== prompts table structure ===');
        const [structureRows] = await connection.execute('DESCRIBE prompts');
        console.log('Field\tType\tNull\tKey\tDefault\tExtra');
        structureRows.forEach(row => {
            console.log(`${row.Field}\t${row.Type}\t${row.Null}\t${row.Key}\t${row.Default}\t${row.Extra}`);
        });
        
        // Check if any default prompts exist
        console.log('\n=== Checking for default prompts ===');
        const [promptRows] = await connection.execute('SELECT id, user_id FROM prompts WHERE id = ?', ['DEFAULT']);
        console.log(`Found ${promptRows.length} default prompts`);
        promptRows.forEach(row => {
            console.log(`ID: ${row.id}, User ID: ${row.user_id}`);
        });
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        if (connection) {
            await connection.end();
            console.log('Database connection closed');
        }
    }
}

checkPromptsTable();
