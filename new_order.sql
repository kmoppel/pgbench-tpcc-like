/*
SPEC: For any given terminal, the home warehouse number (W_ID) is constant over the whole measurement interval (see Clause 5.5).
Let's use Postgres session vars for that -- client_id
*/

SELECT coalesce(current_setting('tpcc_like.client_id_'||:client_id, true)::int, 0) AS w_id \gset

\if :w_id
    SELECT 'OK - session is using w_id ' || :w_id ;
\else
    -- Pick a random warehouse for the whole duration of the session
    SELECT w_id AS w_id FROM warehouse ORDER BY random() LIMIT 1 \gset
    SELECT set_config( 'tpcc_like.client_id_'|| :client_id, ':w_id', false) ;
\endif

\set d_id random(1, 10)

-- SPEC: The non-uniform random customer number (C_ID) is selected using the NURand (1023,1,3000) function
-- Here: just apply Pareto, i.e. 20% of hot customers
\set c_id random_zipfian(1, 3000, 0.86)

-- 1. Get district and warehouse tax
SELECT d_tax, w_tax FROM district d JOIN warehouse w ON w.w_id = d.d_w_id WHERE d_w_id = :w_id AND d_id = :d_id \gset

-- 2. Get customer discount and credit status
SELECT c_discount, c_last, c_credit
FROM customer
WHERE c_w_id = :w_id AND c_d_id = :d_id AND c_id = :c_id \gset

-- 3. Update district's next order ID
UPDATE district
SET d_next_o_id = d_next_o_id + 1
WHERE d_w_id = :w_id AND d_id = :d_id;

\set o_ol_cnt random(1,15)
-- 4. Insert new order into ORDERS
INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local)
VALUES (:o_id, :d_id, :w_id, :c_id, now(), o_ol_cnt, 1);

-- 5. Insert into NEW_ORDER
INSERT INTO new_order (no_o_id, no_d_id, no_w_id)
VALUES (:o_id, :d_id, :w_id);

-- 6. For each item in the order:
-- TODO for each loop a new item!
\set i_id random(1, 100000)
\set qty random(1, 10)


SELECT i_price, i_name, i_data FROM item WHERE i_id = :i_id \gset

-- Get stock info
SELECT s_quantity, s_data, s_dist_01 -- (district depends on d_id)
FROM stock
WHERE s_i_id = :i_id AND s_w_id = :w_id
FOR UPDATE;

-- Update stock quantity
UPDATE stock
SET s_quantity = s_quantity - :qty,
    s_ytd = s_ytd + :qty,
    s_order_cnt = s_order_cnt + 1,
    s_remote_cnt = s_remote_cnt + :remote_flag
WHERE s_i_id = :i_id AND s_w_id = :w_id;

\set ol_quantity 1
\set ol_amount :qty * :i_price * (1 + :w_tax + :d_tax) * (1 - :c_discount)

-- Insert order line
INSERT INTO order_line (
    ol_o_id, ol_d_id, ol_w_id, ol_number,
    ol_i_id, ol_supply_w_id, ol_delivery_d,
    ol_quantity, ol_amount, ol_dist_info
)
VALUES (
    :o_id, :d_id, :w_id, 1, -- TODO loop counter
    :i_id, :w_id, NULL,
    :qty, :amount, :dist_info
);
