const mysql = require('mysql2/promise');

async function checkContentHistoryData() {
    console.log('=== Checking content_history data ===');
    
    try {
        // Create connection
        const connection = await mysql.createConnection({
            host: '101.132.156.250',
            port: 33320,
            user: 'wingmandev',
            password: 'Wing123_Man',
            database: 'wingman_db'
        });
        
        console.log('Connected to database');
        
        // Query content_history table
        const [rows] = await connection.execute('SELECT uuid, user_id, enhance_datetime, created_at FROM content_history WHERE user_id = ? LIMIT 10', ['4']);
        
        console.log('\nContent history data:');
        console.log('UUID\t\t\t\t\t\tUser ID\tEnhance Datetime\t\tCreated At');
        console.log('================================================================================================');
        
        rows.forEach(row => {
            console.log(`${row.uuid}\t${row.user_id}\t${row.enhance_datetime}\t${row.created_at}`);
        });
        
        // Check if enhance_datetime is null or empty
        const [nullCheck] = await connection.execute('SELECT COUNT(*) as null_count FROM content_history WHERE user_id = ? AND (enhance_datetime IS NULL OR enhance_datetime = "")', ['4']);
        console.log(`\nNumber of records with null/empty enhance_datetime: ${nullCheck[0].null_count}`);
        
        // Close connection
        await connection.end();
        
    } catch (error) {
        console.error('Error checking content history data:', error);
    }
}

// Run the script
checkContentHistoryData();
