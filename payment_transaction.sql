-- 1. Update warehouse YTD
UPDATE warehouse
SET w_ytd = w_ytd + :amount
WHERE w_id = :w_id;

-- 2. Update district YTD
UPDATE district
SET d_ytd = d_ytd + :amount
WHERE d_w_id = :w_id AND d_id = :d_id;

-- 3. Get customer by ID or name (if using name, fetch mid-record by last name)
SELECT c_id, c_balance, c_credit, c_data
FROM customer
WHERE c_w_id = :c_w_id AND c_d_id = :c_d_id AND c_id = :c_id
FOR UPDATE;

-- 4. Update customer balance
UPDATE customer
SET c_balance = c_balance - :amount,
    c_ytd_payment = c_ytd_payment + :amount,
    c_payment_cnt = c_payment_cnt + 1
WHERE c_w_id = :c_w_id AND c_d_id = :c_d_id AND c_id = :c_id;

-- 5. If customer is bad credit, update c_data
-- (Additional logic omitted for brevity)

-- 6. Insert into history
INSERT INTO history (
    h_c_id, h_c_d_id, h_c_w_id,
    h_d_id, h_w_id, h_date, h_amount, h_data
)
VALUES (
    :c_id, :c_d_id, :c_w_id,
    :d_id, :w_id, :h_date, :amount, :h_data
);
