CREATE OR REPLACE FUNCTION pg_temp.c_last_name_from_random_syllables() RETURNS text
AS $$
DECLARE
  l_syllables text[] := array['BAR', 'OUGHT', 'ABLE', 'PRI', 'PRES', 'ESE', 'ANTI', 'CALLY', 'ATION', 'EING'];
  l_rand text[] := regexp_split_to_array(lpad((random() * 999)::int::text, 3, '0'), '');
BEGIN
  -- raise notice 'l_rand %', l_rand ;
  RETURN l_syllables[l_rand[1]::int+1] || l_syllables[l_rand[2]::int+1] || l_syllables[l_rand[3]::int+1];
END;
$$ LANGUAGE plpgsql ;



-- NURand function
CREATE OR REPLACE FUNCTION pg_temp.nurand(A INTEGER, x INTEGER, y INTEGER)
RETURNS INTEGER AS $$
DECLARE
    i INTEGER;
    j INTEGER;
    C INTEGER := 1;  -- Simplifying the standard here with C=1 so that the don't have to make the app "C-aware". As per standard:
                     -- C is a run-time constant randomly chosen within [0 .. A] that can be varied with out altering performance.
                     -- The same C value, per field (C_LAST, C_ID, and OL_I_ID), must be used by all emulated terminals.
BEGIN
    IF NOT (A = 255 OR A = 1023 OR A = 8191) THEN
        RAISE EXCEPTION 'Invalid A value: %. Must be 255, 1023, or 8191', A;
    END IF;

    -- Generate random values
    i := floor(random() * (A + 1))::INTEGER;     -- 0 to A
    j := floor(random() * (y - x + 1) + x)::INTEGER; -- x to y

    -- Calculate and return the NURand value
    -- PostgreSQL uses # for bitwise OR
    RETURN (((i # j) + C) % (y - x + 1)) + x;
END;
$$ LANGUAGE plpgsql;



INSERT INTO item (i_id, i_im_id, i_name, i_price, i_data)
SELECT
  gs,
  random()*1e4,
  tdgen.random_text(14, 24),
  tdgen.random_float(1, 100),
  CASE
    WHEN random() < 0.1 THEN tdgen.random_text(10, 20) || ' ORIGINAL ' || tdgen.random_text(10, 20)
    ELSE tdgen.random_text(26, 50)
  END CASE
FROM generate_series(1, 1e5) gs ;


INSERT INTO warehouse (
  w_name,
  w_street_1,
  w_street_2,
  w_city,
  w_state,
  w_zip,
  w_tax,
  w_ytd
)
SELECT
  'wh-' || tdgen.random_text(3,7),
  'str-' || tdgen.random_text(6,16),
  'str-' || tdgen.random_text(6,16),
  'ct-' || tdgen.random_text(6,16),
  tdgen.random_text(2, 2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  tdgen.random_text(5, 5, '0123456789'), -- W_ZIP generated accord ing to Clause 4.3.2.7
  tdgen.random_float(0, 0.2),
  300000
;


INSERT INTO stock (s_w_id, s_i_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06,
    s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_ytd, s_order_cnt, s_remote_cnt, s_data)
SELECT
  w_id,
  gs,
  tdgen.random_int(10, 100),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  tdgen.random_text(24, 24),
  0,
  0,
  0,
  CASE
    WHEN random() < 0.1 THEN tdgen.random_text(10, 20) || ' ORIGINAL ' || tdgen.random_text(10, 20)
    ELSE tdgen.random_text(26, 50)
  END CASE
FROM warehouse, generate_series(1, 1e5) gs;





INSERT INTO district (
  d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id
)
SELECT
  gs,
  w_id,
  tdgen.random_text(6,10, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  'str-' || tdgen.random_text(6,16),
  'str-' || tdgen.random_text(6,16),
  'ct-' || tdgen.random_text(6,16),
  tdgen.random_text(2, 2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  tdgen.random_text(5, 5, '0123456789'), -- W_ZIP generated accord ing to Clause 4.3.2.7
  tdgen.random_float(0, 0.2),
  30000,
  3001
FROM warehouse, generate_series(1, 10) gs ;



INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip,
    c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_ytd_payment, c_payment_cnt, c_delivery_cnt, c_data)
SELECT
  (d_w_id-1)*30000 + (d_id-1)*3000 + gs,
  d_id,
  d_w_id,
  tdgen.random_text(8, 16),  -- c_first
  'OE',  -- c_middle
  CASE WHEN gs <= 1000 THEN pg_temp.c_last_name_from_random_syllables() ELSE pg_temp.nurand(255,0,999)::text END CASE,
  'str-' || tdgen.random_text(6,16),
  'str-' || tdgen.random_text(6,16),
  'ct-' || tdgen.random_text(6,16),
  tdgen.random_text(2, 2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  tdgen.random_text(5, 5, '0123456789'), -- W_ZIP generated accord ing to Clause 4.3.2.7
  tdgen.random_text(16, 16, '0123456789'),
  CASE WHEN gs % 10 = 0 THEN 'BC' ELSE 'GC' END CASE,
  50000,
  tdgen.random_float(0, 0.5),
  -10,
  10,
  1,
  0,
  repeat(gen_random_uuid()::text||gen_random_uuid()::text, 5)
-- For each row in the DISTRICT table 3000 rows in the CUSTOMER table
FROM district, generate_series(1, 3000) gs;



INSERT INTO history (h_c_id, h_d_id, h_c_d_id, h_c_w_id, h_w_id, h_date, h_amount, h_data)
SELECT
  c_id,
  c_d_id,
  c_d_id,
  c_w_id,
  c_w_id,
  now(),
  10.0,
  tdgen.random_text(12, 24)
-- For each row in the CUSTOMER table 1 row in the H ISTORY table
FROM customer ;



INSERT INTO oorder (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local)
SELECT
  (d_w_id-1)*30000 + (d_id-1)*3000 + c_id AS o_id,
  c_id AS o_c_id,
  d_id AS o_d_id,
  d_w_id AS o_w_id,
  now() AS o_entry_d,
  case when c_id < (d_w_id-1)*30000 + (d_id-1)*3000 + 2011 then random()*10 else null end case,
  random()*15 AS o_ol_cnt,
  1 AS o_all_local
-- For each DISTRICT 3,000 rows in the ORDER table
FROM district d JOIN customer c ON c.c_d_id = d.d_id
ORDER BY random();  -- O_C_ID selected sequentially from a random permutation of [1 .. 3,000]



INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d,
           ol_quantity, ol_amount, ol_dist_info )
SELECT
  o_id,
  o_d_id,
  o_w_id,
  gs,
  tdgen.random_int(1, 100000),
  o_w_id,
  case when o_id < (o_w_id-1)*30000 + (o_d_id-1)*3000 + 2101 then o_entry_d else null end case,
  5,
  case when o_id < (o_w_id-1)*30000 + (o_d_id-1)*3000 + 2101 then 0 else tdgen.random_float(0.01, 9999.99) end case,
  tdgen.random_text(24, 24)
-- For each row in the ORDER table a number of rows in the ORDER-LINE table equal to O_OL_CNT
FROM oorder, generate_series(1, oorder.o_ol_cnt) gs;


-- 900 rows in the NEW-ORDER table corresponding to the last 900 rows in the ORDER table for that district
INSERT INTO new_order (no_o_id, no_d_id, no_w_id)
SELECT
  o_id,
  o_d_id,
  o_w_id
FROM oorder WHERE o_id > (o_w_id-1)*30000 + (o_d_id-1)*3000 + 2100 ;
