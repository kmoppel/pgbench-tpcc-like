INSERT INTO item (i_im_id, i_name, i_price, i_data)
SELECT
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
  tdgen.random_text(5, 5, '0123456789'), -- W_ZIP generated accord ing to Clau se 4.3.2.7
  tdgen.random_float(0, 0.2),
  300000
;

INSERT INTO stock (s_w_id, s_i_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06,
    s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_ytd, s_order_cnt, s_remote_cnt, s_data)
SELECT
  (select max(w_id) from warehouse),
  ((select max(w_id) from warehouse) - 1) * 1e5 + gs,
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
FROM generate_series(1, 1e5) gs ;





INSERT INTO district (
  d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id
)
SELECT
  gs,
  (select max(w_id) from warehouse),
  tdgen.random_text(6,10, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  'str-' || tdgen.random_text(6,16),
  'str-' || tdgen.random_text(6,16),
  'ct-' || tdgen.random_text(6,16),
  tdgen.random_text(2, 2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  tdgen.random_text(5, 5, '0123456789'), -- W_ZIP generated accord ing to Clause 4.3.2.7
  tdgen.random_float(0, 0.2),
  30000,
  3001
FROM generate_series(1, 10) gs ;



INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip,
    c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_ytd_payment, c_payment_cnt, c_delivery_cnt, c_data)
SELECT
  ((select max(w_id) from warehouse) - 1) * 3000 + gsc,
  ((select max(w_id) from warehouse) - 1) * 10 + gsd,
  (select max(w_id) from warehouse),
  tdgen.random_text(8, 16),
  'OE',
  'cust-' || (random()*1000)::int::text, -- TODO NURand (255,0,999)
  'str-' || tdgen.random_text(6,16),
  'str-' || tdgen.random_text(6,16),
  'ct-' || tdgen.random_text(6,16),
  tdgen.random_text(2, 2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  tdgen.random_text(5, 5, '0123456789'), -- W_ZIP generated accord ing to Clause 4.3.2.7
  tdgen.random_text(16, 16, '0123456789'),
  CASE WHEN gsc % 10 = 0 THEN 'BC' ELSE 'GC' END CASE,
  50000,
  tdgen.random_float(0, 0.5),
  -10,
  10,
  1,
  0,
  repeat(gen_random_uuid()::text||gen_random_uuid()::text, 5)
-- For each row in the DISTRICT table 3000 rows in the CUSTOMER table
FROM generate_series(1, 3000) gsc, generate_series(1, 10) gsd;



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
  d_id * 3000 + gs,
  3000*random(),
  d_id,
  d_w_id,
  now(),
  case when gs < 2011 then random()*10 else null end case,
  random()*15,
  1
-- For each DISTRICT 3,000 rows in the ORDER table
FROM district, generate_series(1, 3000) gs;



INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d,
           ol_quantity, ol_amount, ol_dist_info )
SELECT
  o_id,
  o_d_id,
  o_w_id,
  gs,
  random()*1e5,
  o_w_id,
  case when o_id < 2101 then o_entry_d else null end case,
  5,
  case when o_id < 2101 then 0 else tdgen.random_float(0.01, 9999.99) end case,
  tdgen.random_text(24, 24)
-- For each row in the ORDER table a number of rows in the ORDER-LINE table equal to O_OL_CNT
FROM oorder, generate_series(1, oorder.o_ol_cnt) gs;


-- 900 rows in the NEW-ORDER table corresponding to the last 900 rows in the ORDER table for that district
INSERT INTO new_order (no_o_id, no_d_id, no_w_id)
SELECT
  o_id,
  o_d_id,
  o_w_id
FROM oorder WHERE o_id > 2100 ;
