-- Requires util.* functions from 0_schema.sql !

INSERT INTO item (i_id, i_im_id, i_name, i_price, i_data)
SELECT
  gs,
  random()*1e4,
  tpcc_utils.random_text_uuid_based(14, 24),
  tpcc_utils.random_float(1, 100),
  CASE
    WHEN random() < 0.1 THEN tpcc_utils.random_text_uuid_based(10, 20) || ' ORIGINAL ' || tpcc_utils.random_text_uuid_based(10, 20)
    ELSE tpcc_utils.random_text_uuid_based(26, 50)
  END CASE
FROM generate_series(1, 1e5) gs
WHERE NOT EXISTS (select * from item limit 1);


INSERT INTO warehouse (
  w_id,
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
  (extract(epoch from now()) * 1e6 )::int8,
  'wh-' || tpcc_utils.random_text_uuid_based(3,7),
  'str-' || tpcc_utils.random_text_uuid_based(6,16),
  'str-' || tpcc_utils.random_text_uuid_based(6,16),
  'ct-' || tpcc_utils.random_text_uuid_based(6,16),
  tpcc_utils.random_text(2, 2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  tpcc_utils.random_text(5, 5, '0123456789'), -- W_ZIP generated accord ing to Clause 4.3.2.7
  tpcc_utils.random_float(0, 0.2),
  300000
RETURNING w_id \gset


INSERT INTO stock (s_w_id, s_i_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06,
    s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_ytd, s_order_cnt, s_remote_cnt, s_data)
SELECT
  :w_id,
  gs,
  tpcc_utils.random_int(10, 100),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  tpcc_utils.random_text_uuid_based(24, 24),
  0,
  0,
  0,
  CASE
    WHEN random() < 0.1 THEN tpcc_utils.random_text_uuid_based(10, 20) || ' ORIGINAL ' || tpcc_utils.random_text_uuid_based(10, 20)
    ELSE tpcc_utils.random_text_uuid_based(26, 50)
  END CASE
FROM generate_series(1, 1e5) gs;





INSERT INTO district (
  d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id
)
SELECT
  gs_dist,
  :w_id,
  tpcc_utils.random_text(6,10, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  'str-' || tpcc_utils.random_text_uuid_based(6,16),
  'str-' || tpcc_utils.random_text_uuid_based(6,16),
  'ct-' || tpcc_utils.random_text_uuid_based(6,16),
  tpcc_utils.random_text(2, 2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  tpcc_utils.random_text(5, 5, '0123456789'), -- W_ZIP generated according to Clause 4.3.2.7
  tpcc_utils.random_float(0, 0.2),
  30000,
  3001
FROM generate_series(1, 10) gs_dist ;



INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip,
    c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_ytd_payment, c_payment_cnt, c_delivery_cnt, c_data)
SELECT
  gs_cust,
  gs_dist,
  :w_id,
  tpcc_utils.random_text_uuid_based(8, 16),  -- c_first
  'OE',  -- c_middle
  CASE WHEN gs_cust <= 1000 THEN tpcc_utils.c_last_name_from_random_syllables() ELSE tpcc_utils.nurand(255,0,999)::text END CASE,
  'str-' || tpcc_utils.random_text_uuid_based(6,16),
  'str-' || tpcc_utils.random_text_uuid_based(6,16),
  'ct-' || tpcc_utils.random_text_uuid_based(6,16),
  tpcc_utils.random_text(2, 2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  tpcc_utils.random_text(5, 5, '0123456789'), -- W_ZIP generated accord ing to Clause 4.3.2.7
  tpcc_utils.random_text(16, 16, '0123456789'),
  CASE WHEN gs_dist % 10 = 0 THEN 'BC' ELSE 'GC' END CASE,
  50000,
  tpcc_utils.random_float(0, 0.5),
  -10,
  10,
  1,
  0,
  repeat(gen_random_uuid()::text||gen_random_uuid()::text, 5) -- c_data
-- For each row in the DISTRICT table 3000 rows in the CUSTOMER table
FROM generate_series(1, 10) gs_dist, generate_series(1, 3000) gs_cust ;



INSERT INTO history (h_c_id, h_d_id, h_c_d_id, h_c_w_id, h_w_id, h_date, h_amount, h_data)
SELECT
  gs_cust,
  gs_dist,
  gs_dist,
  :w_id,
  :w_id,
  now(),
  10.0,
  tpcc_utils.random_text_uuid_based(12, 24)
-- For each row in the CUSTOMER table 1 row in the HISTORY table
FROM generate_series(1, 10) gs_dist, generate_series(1, 3000) gs_cust ;


INSERT INTO oorder (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local)
SELECT
  :w_id + gs_dist * 3000 + gs_cust,
  gs_cust,
  gs_dist,
  :w_id,
  now() AS o_entry_d,
  case when gs_cust < 2011 then random()*10 else null end case,
  ceil(random()*15) AS o_ol_cnt,
  1 AS o_all_local
-- For each DISTRICT 3,000 rows in the ORDER table
FROM generate_series(1, 10) gs_dist, generate_series(1, 3000) gs_cust
ORDER BY random();  -- O_C_ID selected sequentially from a random permutation of [1 .. 3,000]


INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d,
           ol_quantity, ol_amount, ol_dist_info )
SELECT
  o_id,
  o_d_id,
  o_w_id,
  gs,
  tpcc_utils.random_int(1, 100000),
  o_w_id,
  case when o_id < o_w_id + o_d_id*3000 + o_c_id + 2101 then o_entry_d else null end case,
  5,
  case when o_id < o_w_id + o_d_id*3000 + o_c_id + 2101 then 0 else tpcc_utils.random_float(0.01, 9999.99) end case,
  tpcc_utils.random_text_uuid_based(24, 24)
-- For each row in the ORDER table a number of rows in the ORDER-LINE table equal to O_OL_CNT
FROM oorder, generate_series(1, oorder.o_ol_cnt) gs
WHERE o_w_id = :w_id ;
-- FROM generate_series(1, 10) gs_dist, generate_series(1, 3000), generate_series(1, oorder.o_ol_cnt) gs;


-- 900 rows in the NEW-ORDER table corresponding to the last 900 rows in the ORDER table for that district
INSERT INTO new_order (no_o_id, no_d_id, no_w_id)
SELECT
  o_id,
  o_d_id,
  o_w_id
FROM oorder
WHERE o_w_id = :w_id
AND o_id > o_w_id + o_d_id*3000 + 2100 ;
