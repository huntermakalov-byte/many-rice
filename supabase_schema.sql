-- ==========================================================
-- สคริปต์ฐานข้อมูล Supabase สำหรับระบบ POS ร้าน "นานาข้าว" (Nana Khao)
-- ใช้วางใน Supabase SQL Editor แล้วกด Run ได้ทันที
-- ==========================================================

-- 1. ตารางสินค้า (products)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0,
    cost_price NUMERIC(10, 2) DEFAULT 0,
    stock INTEGER NOT NULL DEFAULT 0,
    unit VARCHAR(50) DEFAULT 'แพ็ค',
    image_url TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. ตารางออเดอร์/การสั่งซื้อ (orders)
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) NOT NULL UNIQUE,
    customer_name VARCHAR(255) DEFAULT 'ลูกค้าทั่วไป',
    customer_phone VARCHAR(50),
    order_type VARCHAR(50) DEFAULT 'dine_in', -- dine_in, takeaway, delivery
    subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0,
    discount NUMERIC(10, 2) DEFAULT 0,
    vat NUMERIC(10, 2) DEFAULT 0,
    total NUMERIC(10, 2) NOT NULL DEFAULT 0,
    payment_method VARCHAR(50) NOT NULL, -- cash, qr
    cash_received NUMERIC(10, 2) DEFAULT 0,
    change_amount NUMERIC(10, 2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'completed', -- completed, cancelled, pending
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. ตารางรายการสินค้าในออเดอร์ (order_items)
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name VARCHAR(255) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    total_price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. ตารางบันทึกการเข้าใช้งานของลูกค้า (customer_logs)
CREATE TABLE IF NOT EXISTS public.customer_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    visit_type VARCHAR(100) DEFAULT 'dine_in', -- dine_in, takeaway, member_checkin, inquiries
    order_number VARCHAR(50),
    spent_amount NUMERIC(10, 2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- เพิ่มดัชนี (Indexes) เพื่อการสืบค้นที่รวดเร็ว
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_customer_logs_created ON public.customer_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);

-- เปิด Row Level Security (RLS) และอนุญาตให้เข้าถึงสำหรับการทำงานระบบ POS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_logs ENABLE ROW LEVEL SECURITY;

-- สร้าง Policy สำหรับ Anonymous / Public Access (หรือปรับแต่งตาม Auth ในภายหลัง)
DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow public all products" ON public.products;
    CREATE POLICY "Allow public all products" ON public.products FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow public all orders" ON public.orders;
    CREATE POLICY "Allow public all orders" ON public.orders FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow public all order_items" ON public.order_items;
    CREATE POLICY "Allow public all order_items" ON public.order_items FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow public all customer_logs" ON public.customer_logs;
    CREATE POLICY "Allow public all customer_logs" ON public.customer_logs FOR ALL USING (true) WITH CHECK (true);
END $$;

-- ข้อมูลตัวอย่างเริ่มต้น (Seed Initial Products พร้อมรูปภาพเฉพาะของแต่ละรายการ ไม่ซ้ำกัน 100%)
INSERT INTO public.products (name, category, price, cost_price, stock, unit, image_url, description)
VALUES
('ข้าวหอมมะลิแท้ทุ่งกุลาร้องไห้ (1 กก.)', 'ข้าวสารพรีเมียม', 119.00, 75.00, 60, 'ถุง', '/products/jasmine_rice.jpg', 'ข้าวหอมมะลิแท้ 100% คัดพิเศษ หอมนุ่ม เมล็ดเรียวยาว หุงขึ้นหม้อ'),
('ข้าวผัดมันกุ้งแม่น้ำกระทะร้อน', 'เมนูข้าวซิกเนเจอร์', 189.00, 95.00, 40, 'จาน', '/products/shrimp_fried_rice.jpg', 'ข้าวผัดมันกุ้งหอมกรุ่น เสิร์ฟพร้อมกุ้งแม่น้ำย่างเนื้อเด้งและไข่กุ้งกรุบกรอบ'),
('ข้าวไรซ์เบอร์รี่เกษตรอินทรีย์ (1 กก.)', 'ข้าวสารพรีเมียม', 135.00, 85.00, 45, 'ถุง', '/products/riceberry.jpg', 'ข้าวไรซ์เบอร์รี่เกรดออร์แกนิก ปลูกด้วยวิถีธรรมชาติ อุดมด้วยสารต้านอนุมูลอิสระ'),
('ข้าวหน้าหมูกรอบคั่วพริกเกลือ', 'เมนูข้าวซิกเนเจอร์', 145.00, 70.00, 35, 'จาน', '/products/crispy_pork_rice.jpg', 'หมูกรอบสูตรเด็ดทอดกรอบไม่อมน้ำมัน คั่วพริกเกลือกระเทียมสดหอมเตะจมูก'),
('ข้าวกล้องสังข์หยดพัทลุง (1 กก.)', 'ข้าวสารพรีเมียม', 140.00, 90.00, 30, 'ถุง', '/products/sangyod_rice.jpg', 'ข้าวพันธุ์พื้นเมืองพัทลุง ได้รับการขึ้นทะเบียน GI นุ่ม หอม กากใยสูง'),
('ข้าวเหนียวเขี้ยวงูเชียงราย (1 กก.)', 'ข้าวสารพรีเมียม', 95.00, 60.00, 50, 'ถุง', '/products/sticky_rice.jpg', 'ข้าวเหนียวพันธุ์เลื่องชื่อ นึ่งแล้วนุ่ม ขาว เงางาม หอมละมุน'),
('ข้าวยำเบญจรงค์สมุนไพรนานาข้าว', 'เมนูข้าวซิกเนเจอร์', 129.00, 55.00, 25, 'จาน', '/products/khao_yam.jpg', 'ข้าวยำปักษ์ใต้สูตรต้นตำรับ น้ำบูดูเคี่ยวอย่างพิถีพิถัน ผักสมุนไพรสด 10 ชนิด'),
('ชาข้าวหอมคั่วพรีเมียม (เย็น)', 'เครื่องดื่ม & ของหวาน', 65.00, 22.00, 80, 'แก้ว', '/products/roasted_rice_tea.jpg', 'ชาข้าวคั่วสไตล์ญี่ปุ่นผสมกลิ่นอายข้าวหอมมะลิไทย หอมละมุน สดชื่น'),
('น้ำข้าวกล้องงอกออร์แกนิกสูตรหวานน้อย', 'เครื่องดื่ม & ของหวาน', 55.00, 20.00, 70, 'ขวด', '/products/gaba_rice_drink.jpg', 'น้ำข้าวกล้องงอกสกัดสด อุดมด้วย GABA บำรุงสมอง ผ่อนคลาย ดื่มง่าย'),
('ข้าวเหนียวมะม่วงน้ำดอกไม้สีทอง', 'เครื่องดื่ม & ของหวาน', 120.00, 55.00, 30, 'ชุด', '/products/mango_sticky_rice.jpg', 'ข้าวเหนียวมูนกะทิสดแท้ทานคู่มะม่วงน้ำดอกไม้สุกหวานฉ่ำ ราดกะทิอบควันเทียน')
ON CONFLICT DO NOTHING;
