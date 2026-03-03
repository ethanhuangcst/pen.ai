const mysql = require('mysql2/promise');

async function queryContentHistory() {
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

        // Query the content_history table data
        const [rows, fields] = await connection.execute('SELECT * FROM content_history ORDER BY enhance_datetime DESC LIMIT 10;');
        console.log('\n=== Content History Data ===');
        console.table(rows);

        // Close the connection
        await connection.end();
        console.log('\nConnection closed');
    } catch (error) {
        console.error('Error:', error);
    }
}

queryContentHistory();