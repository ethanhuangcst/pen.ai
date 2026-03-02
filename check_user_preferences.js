const mysql = require('mysql2/promise');

async function checkUserPreferencesTable() {
    try {
        // Create connection
        const connection = await mysql.createConnection({
            host: '101.132.156.250',
            port: 33320,
            user: 'wingmandev',
            password: 'WingmanDev123!',
            database: 'wingman_db'
        });

        console.log('Connected to database successfully!');

        // Check if user_preferences table exists
        const [tables] = await connection.execute('SHOW TABLES LIKE ?', ['user_preferences']);
        
        if (tables.length > 0) {
            console.log('✓ user_preferences table exists');
            
            // Describe the table structure
            const [description] = await connection.execute('DESCRIBE user_preferences');
            
            console.log('\nTable structure:');
            console.log('---------------------------------');
            console.log('Column Name\tType\tNull\tKey\tDefault\tExtra');
            console.log('---------------------------------');
            
            description.forEach(row => {
                console.log(`${row.Field}\t${row.Type}\t${row.Null}\t${row.Key}\t${row.Default || ''}\t${row.Extra}`);
            });
            console.log('---------------------------------');
            
            // Check if there are any records
            const [countResult] = await connection.execute('SELECT COUNT(*) as count FROM user_preferences');
            const count = countResult[0].count;
            console.log(`\n✓ Found ${count} records in user_preferences table`);
            
        } else {
            console.log('✗ user_preferences table does not exist');
        }

        // Close connection
        await connection.end();
        
    } catch (error) {
        console.error('Error:', error);
    }
}

checkUserPreferencesTable();
