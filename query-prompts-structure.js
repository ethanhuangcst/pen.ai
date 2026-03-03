const mysql = require('mysql2/promise');

async function queryPromptsStructure() {
    try {
        // Create a connection to the database
        const connection = await mysql.createConnection({
            host: '127.0.0.1',
            port: 3306,
            user: 'root',
            password: 'wingman',
            database: 'wingman_db'
        });

        console.log('Connected to database');

        // Query the prompts table structure
        const [rows, fields] = await connection.execute('DESCRIBE prompts;');
        console.log('\n=== Prompts Table Structure ===');
        console.table(rows);

        // Query the content_history table structure
        const [rows2, fields2] = await connection.execute('DESCRIBE content_history;');
        console.log('\n=== Content History Table Structure ===');
        console.table(rows2);

        // Close the connection
        await connection.end();
        console.log('\nConnection closed');
    } catch (error) {
        console.error('Error:', error);
    }
}

queryPromptsStructure();