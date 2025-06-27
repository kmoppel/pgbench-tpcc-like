-- For each of 10 districts (d_id from 1 to 10):

-- 1. Find oldest unfulfilled order
SELECT no_o_id
FROM new_order
WHERE no_w_id = :w_id AND no_d_id = :d_id
ORDER BY no_o_id
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- 2. Delete from NEW_ORDER
DELETE FROM new_order
WHERE no_w_id = :w_id AND no_d_id = :d_id AND no_o_id = :o_id;

-- 3. Update order with carrier ID
UPDATE orders
SET o_carrier_id = :carrier_id
WHERE o_w_id = :w_id AND o_d_id = :d_id AND o_id = :o_id;

-- 4. Update order lines with delivery date
UPDATE order_line
SET ol_delivery_d = :delivery_d
WHERE ol_w_id = :w_id AND ol_d_id = :d_id AND ol_o_id = :o_id;

-- 5. Get customer ID from order
SELECT o_c_id
FROM orders
WHERE o_w_id = :w_id AND o_d_id = :d_id AND o_id = :o_id;

-- 6. Sum order line amounts
SELECT SUM(ol_amount) AS sum_amount
FROM order_line
WHERE ol_w_id = :w_id AND ol_d_id = :d_id AND ol_o_id = :o_id;

-- 7. Update customer balance and delivery count
UPDATE customer
SET c_balance = c_balance + :sum_amount,
    c_delivery_cnt = c_delivery_cnt + 1
WHERE c_w_id = :w_id AND c_d_id = :d_id AND c_id = :c_id;
