const mysql = require('mysql2');
require('dotenv').config();

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT,
    charset: 'utf8mb4_GENERAL_CI',
    timezone: '+07:00',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

pool.on('connection', (connection) => {
    connection.query("SET NAMES utf8mb4");
    connection.query("SET CHARACTER SET utf8mb4");
    connection.query("SET SESSION collation_connection = 'utf8mb4_unicode_ci'");
});

pool.getConnection((err, connection) => {
    if (err) {
        console.error('Lỗi kết nối MySQL:', err.message);
    } else {
        console.log('Đã kết nối thành công đến MySQL Database');
        connection.release();
    }
});

module.exports = pool.promise();