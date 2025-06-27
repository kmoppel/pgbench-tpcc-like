-- 1. Get customer (by ID or by name)
SELECT c_id, c_first, c_middle, c_last, c_balance
FROM customer
WHERE c_w_id = :w_id AND c_d_id = :d_id AND c_id = :c_id;

-- 2. Get last order by customer
SELECT o_id, o_entry_d, o_carrier_id
FROM orders
WHERE o_w_id = :w_id AND o_d_id = :d_id AND o_c_id = :c_id
ORDER BY o_id DESC
LIMIT 1;

-- 3. Get all order lines for the order
SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d
FROM order_line
WHERE ol_w_id = :w_id AND ol_d_id = :d_id AND ol_o_id = :o_id;
