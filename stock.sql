-- 1. Get next order ID for the district
SELECT d_next_o_id
FROM district
WHERE d_w_id = :w_id AND d_id = :d_id;

-- 2. Get item IDs from the last 20 orders
SELECT DISTINCT ol_i_id
FROM order_line
WHERE ol_w_id = :w_id AND ol_d_id = :d_id
  AND ol_o_id >= :next_o_id - 20 AND ol_o_id < :next_o_id;

-- 3. Count items with low stock (< :threshold)
SELECT COUNT(*) AS low_stock
FROM stock
WHERE s_w_id = :w_id AND s_i_id IN (:item_id_list)
  AND s_quantity < :threshold;
