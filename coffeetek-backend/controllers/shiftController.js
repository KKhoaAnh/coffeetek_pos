const db = require('../config/db');

// Helper: Lấy thời gian hiện tại theo múi giờ Việt Nam để so sánh
// (Lưu ý: DB vẫn nên lưu UTC hoặc Server Time chuẩn, việc convert hiển thị để Frontend lo)

// [MỚI] 1. Lấy thông tin tổng hợp trước khi đóng ca
exports.getShiftSummary = async (req, res) => {
    try {
        const { shiftId } = req.query;
        if (!shiftId) return res.status(400).json({ message: 'Thiếu shiftId' });

        // Lấy thông tin ca
        const [shift] = await db.query("SELECT * FROM shifts WHERE shift_id = ?", [shiftId]);
        if (shift.length === 0) return res.status(404).json({ message: 'Không tìm thấy ca' });
        
        const currentShift = shift[0];

        // Tính tổng doanh thu TIỀN MẶT trong khoảng thời gian ca mở
        // Lưu ý: Chỉ tính đơn đã COMPLETED và payment_method = 'CASH'
        // (Bạn có thể mở rộng thêm logic cash_in/cash_out nếu sau này làm tính năng đó)
        const sqlSales = `
            SELECT SUM(total_amount) as cash_sales 
            FROM orders 
            WHERE status = 'COMPLETED' 
            AND payment_method = 'CASH'
            AND created_at >= ? 
            AND created_at <= NOW()
        `;

        // Vì ca chưa đóng nên end_time là NOW()
        const [sales] = await db.query(sqlSales, [currentShift.start_time]);
        
        const totalCashSales = parseFloat(sales[0].cash_sales) || 0;
        const initialFloat = parseFloat(currentShift.initial_float) || 0;

        // Bây giờ phép cộng sẽ chạy đúng (Số + Số)
        const expectedCash = initialFloat + totalCashSales;

        res.status(200).json({
            initial_float: initialFloat,
            total_cash_sales: totalCashSales,
            expected_cash: expectedCash
        });

    } catch (error) {
        console.error("Lỗi summary:", error);
        res.status(500).json({ message: 'Lỗi server' });
    }
};
exports.getTodayShifts = async (req, res) => {
    try {
        const userId = req.query.userId;
        // Logic: Lấy ca của userId cụ thể, HOẶC nếu là Admin thì lấy hết (tùy bạn, ở đây ta cứ lấy theo userId trước hoặc mở rộng sau)
        // Query có JOIN với bảng users để lấy full_name
        const sql = `
            SELECT s.*, u.full_name as user_name
            FROM shifts s
            JOIN users u ON s.user_id = u.user_id
            WHERE s.user_id = ? 
            AND DATE(s.start_time) = CURDATE() 
            ORDER BY s.start_time DESC
        `;
        
        const [rows] = await db.query(sql, [userId]);
        res.status(200).json(rows);
    } catch (error) {
        console.error("Lỗi lấy danh sách ca:", error);
        res.status(500).json({ message: 'Lỗi server' });
    }
};

// 2. [CẬP NHẬT] Mở ca có Ghi chú
exports.openShift = async (req, res) => {
    try {
        const { user_id, initial_float, note } = req.body; // Thêm note

        const checkSql = "SELECT shift_id FROM shifts WHERE user_id = ? AND status = 'OPEN'";
        const [existing] = await db.query(checkSql, [user_id]);
        
        if (existing.length > 0) return res.status(400).json({ message: 'Bạn đang có một ca chưa đóng!' });

        const sql = `
            INSERT INTO shifts (user_id, initial_float, start_time, status, note) 
            VALUES (?, ?, NOW(), 'OPEN', ?)
        `;
        
        await db.query(sql, [user_id, initial_float, note || '']);
        res.status(201).json({ message: 'Mở ca thành công' });

    } catch (error) {
        res.status(500).json({ message: 'Lỗi server khi mở ca' });
    }
};

// 3. [CẬP NHẬT] Đóng ca có Ghi chú & Logic float
exports.closeShift = async (req, res) => {
    try {
        const { shift_id, actual_cash, note } = req.body; // Thêm note

        // ... (Phần lấy currentShift và tính toán sales giữ nguyên như bước trước) ...
        // Copy lại logic tính toán ở câu trả lời trước nhé:
        const [shift] = await db.query("SELECT * FROM shifts WHERE shift_id = ?", [shift_id]);
        if (shift.length === 0) return res.status(404).json({ message: 'Ca không tồn tại' });
        const currentShift = shift[0];

        const sqlSales = `SELECT SUM(total_amount) as cash_sales FROM orders WHERE status = 'COMPLETED' AND payment_method = 'CASH' AND created_at >= ?`;
        const [sales] = await db.query(sqlSales, [currentShift.start_time]);

        const totalCashSales = parseFloat(sales[0].cash_sales) || 0;
        const initialFloat = parseFloat(currentShift.initial_float) || 0;
        const expectedCash = initialFloat + totalCashSales;
        const difference = actual_cash - expectedCash;

        // Update DB thêm cột note
        const sqlUpdate = `
            UPDATE shifts 
            SET status = 'CLOSED', 
                end_time = NOW(),
                total_cash_sales = ?,
                expected_cash = ?,
                actual_cash = ?,
                difference = ?,
                note = ?  -- Cập nhật ghi chú đóng ca (nếu muốn lưu đè hoặc cộng dồn)
            WHERE shift_id = ?
        `;
        
        // Mẹo: Ghi chú đóng ca nên nối tiếp ghi chú mở ca cho rõ ràng
        const closeNote = note ? `[Đóng ca]: ${note}` : '';
        const finalNote = currentShift.note ? `${currentShift.note} | ${closeNote}` : closeNote;

        await db.query(sqlUpdate, [
            totalCashSales, expectedCash, actual_cash, difference, finalNote, shift_id
        ]);
        
        // Trả về đầy đủ thông tin để Client in phiếu
        res.status(200).json({ 
            message: 'Đóng ca thành công',
            data: {
                shift_id,
                user_name: '', // Client tự điền hoặc query thêm
                start_time: currentShift.start_time,
                end_time: new Date(),
                initial_float: initialFloat,
                total_cash_sales: totalCashSales,
                expected_cash: expectedCash,
                actual_cash: actual_cash,
                difference: difference,
                note: finalNote
            }
        });

    } catch (error) {
        console.error("Lỗi đóng ca:", error);
        res.status(500).json({ message: 'Lỗi server' });
    }
};