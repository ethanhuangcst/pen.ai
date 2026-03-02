const mysql = require('mysql2/promise');

// Database configuration
const config = {
  host: '101.132.156.250',
  port: 33320,
  user: 'wingmandev',
  password: 'Wing123_Man',
  database: 'wingman_db'
};

async function addIsDefaultColumn() {
    let connection;
    
    try {
        connection = await mysql.createConnection(config);
        console.log('Connected to database');
        
        // Add is_default column to prompts table
        console.log('Adding is_default column to prompts table...');
        await connection.execute(`
            ALTER TABLE prompts
            ADD COLUMN is_default tinyint(1) NOT NULL DEFAULT 0
        `);
        console.log('is_default column added successfully!');
        
        // Set existing default prompts to is_default = 1
        console.log('Setting existing default prompts to is_default = 1...');
        await connection.execute(`
            UPDATE prompts
            SET is_default = 1
            WHERE id = 'DEFAULT' OR id LIKE 'DEFAULT-%'
        `);
        console.log('Existing default prompts updated successfully!');
        
        // Verify the table structure
        console.log('\n=== prompts table structure ===');
        const [structureRows] = await connection.execute('DESCRIBE prompts');
        console.log('Field\tType\tNull\tKey\tDefault\tExtra');
        structureRows.forEach(row => {
            console.log(`${row.Field}\t${row.Type}\t${row.Null}\t${row.Key}\t${row.Default}\t${row.Extra}`);
        });
        
        // Verify the data
        console.log('\n=== Checking default prompts ===');
        const [defaultRows] = await connection.execute('SELECT id, user_id, is_default FROM prompts WHERE is_default = 1');
        console.log(`Found ${defaultRows.length} default prompts`);
        defaultRows.forEach(row => {
            console.log(`ID: ${row.id}, User ID: ${row.user_id}, is_default: ${row.is_default}`);
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

addIsDefaultColumn();
