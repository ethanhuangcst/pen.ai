const mysql = require('mysql2/promise');

const fs = require('fs');

async function checkColumnCase() {
    try {
        // Create a connection to the database
        const connection = await mysql.createConnection({
            host: '101.132.156.250',
            port: 33320,
            user: 'wingmandev',
            password: 'Wing123_Man',
            database: 'wingman_db'
        });

        console.log('Connected to database');

        // Query the content_history table structure
        const [columns] = await connection.execute('SHOW COLUMNS FROM content_history');
        console.log('\n=== Content History Table Columns ===');
        console.table(columns);

        // Query a sample row to see the actual column names
        const [rows] = await connection.execute('SELECT * FROM content_history LIMIT 1');
        console.log('\n=== Sample Row Column Names ===');
        if (rows.length > 0) {
            console.log('Column names:', Object.keys(rows[0]));
            console.log('Sample row:', rows[0]);
        }

        // Close the connection
        await connection.end();
        console.log('\nConnection closed');
    } catch (error) {
        console.error('Error:', error);
    }
}

checkColumnCase();