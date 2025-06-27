-- 1. Get district tax and next order id
SELECT d_tax, d_next_o_id
FROM district
WHERE d_w_id = :w_id AND d_id = :d_id
FOR UPDATE;

-- 2. Get customer discount and credit status
SELECT c_discount, c_last, c_credit
FROM customer
WHERE c_w_id = :w_id AND c_d_id = :d_id AND c_id = :c_id;

-- 3. Update district's next order ID
UPDATE district
SET d_next_o_id = d_next_o_id + 1
WHERE d_w_id = :w_id AND d_id = :d_id;

-- 4. Insert new order into ORDERS
INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local)
VALUES (:o_id, :d_id, :w_id, :c_id, :entry_d, :ol_cnt, :all_local);

-- 5. Insert into NEW_ORDER
INSERT INTO new_order (no_o_id, no_d_id, no_w_id)
VALUES (:o_id, :d_id, :w_id);

-- 6. For each item in the order:
-- Get item price
SELECT i_price, i_name, i_data
FROM item
WHERE i_id = :i_id;

-- Get stock info
SELECT s_quantity, s_data, s_dist_01 -- (district depends on d_id)
FROM stock
WHERE s_i_id = :i_id AND s_w_id = :supp_w_id
FOR UPDATE;

-- Update stock quantity
UPDATE stock
SET s_quantity = s_quantity - :qty,
    s_ytd = s_ytd + :qty,
    s_order_cnt = s_order_cnt + 1,
    s_remote_cnt = s_remote_cnt + :remote_flag
WHERE s_i_id = :i_id AND s_w_id = :supp_w_id;

-- Insert order line
INSERT INTO order_line (
    ol_o_id, ol_d_id, ol_w_id, ol_number,
    ol_i_id, ol_supply_w_id, ol_delivery_d,
    ol_quantity, ol_amount, ol_dist_info
)
VALUES (
    :o_id, :d_id, :w_id, :line_num,
    :i_id, :supp_w_id, NULL,
    :qty, :amount, :dist_info
);
