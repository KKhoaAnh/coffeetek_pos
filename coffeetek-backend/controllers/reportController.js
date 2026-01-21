const db = require('../config/db');

// Helper: Lấy tham số ngày từ Request
const getDateRange = (req) => {
    const today = new Date().toISOString().split('T')[0];
    const startDate = req.query.startDate || today;
    const endDate = req.query.endDate || today;
    return { startDate, endDate };
};

// 1. BÁO CÁO TỔNG HỢP (Đã sửa lỗi hiển thị 0)
exports.getSummaryReport = async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req);
        
        // [SỬA LỖI]: Tính net_revenue bằng công thức (total - discount)
        // Thay vì SUM(final_amount) có thể bị 0 ở các đơn cũ
        const sql = `
            SELECT 
                COUNT(*) as total_orders,
                SUM(total_amount) as total_sales,     
                SUM(discount_amount) as total_discount, 
                
                -- Công thức tính doanh thu thực an toàn cho cả dữ liệu cũ
                SUM(total_amount - IFNULL(discount_amount, 0)) as net_revenue
                
            FROM orders 
            WHERE status = 'COMPLETED' 
            AND DATE(created_at) BETWEEN ? AND ?
        `;

        const [rows] = await db.query(sql, [startDate, endDate]);
        
        // Xử lý trường hợp không có đơn nào (null) -> trả về 0
        const result = rows[0];
        res.status(200).json({
            total_orders: result.total_orders || 0,
            total_sales: result.total_sales || 0,
            total_discount: result.total_discount || 0,
            net_revenue: result.net_revenue || 0
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi báo cáo tổng hợp' });
    }
};

// ... Các hàm getCategoryReport và getProductReport giữ nguyên ...
exports.getCategoryReport = async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req);
        
        const sql = `
            SELECT 
                c.category_name, 
                SUM(od.quantity) as total_quantity,
                SUM(od.total_line_amount) as total_revenue
            FROM order_details od
            JOIN orders o ON od.order_id = o.order_id
            JOIN products p ON od.product_id = p.product_id
            JOIN categories c ON p.category_id = c.category_id
            WHERE o.status = 'COMPLETED'
            AND DATE(o.created_at) BETWEEN ? AND ?
            GROUP BY c.category_id, c.category_name
            ORDER BY total_revenue DESC
        `;

        const [rows] = await db.query(sql, [startDate, endDate]);
        res.status(200).json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi báo cáo nhóm món' });
    }
};

exports.getProductReport = async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req);
        
        const sql = `
            SELECT 
                p.product_name,
                c.category_name,
                SUM(od.quantity) as total_quantity,
                SUM(od.total_line_amount) as total_revenue
            FROM order_details od
            JOIN orders o ON od.order_id = o.order_id
            JOIN products p ON od.product_id = p.product_id
            JOIN categories c ON p.category_id = c.category_id
            WHERE o.status = 'COMPLETED'
            AND DATE(o.created_at) BETWEEN ? AND ?
            GROUP BY p.product_id, p.product_name, c.category_name
            ORDER BY total_quantity DESC
        `;

        const [rows] = await db.query(sql, [startDate, endDate]);
        res.status(200).json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi báo cáo chi tiết món' });
    }
};