DROP TABLE IF EXISTS warehouse, item, stock, district, customer, history, oorder, order_line, new_order ;
-- TRUNCATE TABLE warehouse, item, stock, district, customer, history, oorder, order_line, new_order CASCADE ;

CREATE UNLOGGED TABLE IF NOT EXISTS warehouse (
    w_id int8 NOT NULL,
    w_ytd numeric(12, 2) NOT NULL,
    w_tax numeric(4, 4) NOT NULL,
    w_name varchar(10) NOT NULL,
    w_street_1 varchar(20) NOT NULL,
    w_street_2 varchar(20) NOT NULL,
    w_city varchar(20) NOT NULL,
    w_state char(2) NOT NULL,
    w_zip char(9) NOT NULL,
    PRIMARY KEY (w_id)
);

CREATE UNLOGGED TABLE IF NOT EXISTS item (
    i_id int NOT NULL,
    i_name varchar(24) NOT NULL,
    i_price numeric(5, 2) NOT NULL,
    i_data varchar(50) NOT NULL,
    i_im_id int NOT NULL,
    PRIMARY KEY (i_id)
);

CREATE UNLOGGED TABLE IF NOT EXISTS stock (
    s_w_id int8 NOT NULL,
    s_i_id int NOT NULL,
    s_quantity int NOT NULL,
    s_ytd numeric(8, 2) NOT NULL,
    s_order_cnt int NOT NULL,
    s_remote_cnt int NOT NULL,
    s_data varchar(50) NOT NULL,
    s_dist_01 char(24) NOT NULL,
    s_dist_02 char(24) NOT NULL,
    s_dist_03 char(24) NOT NULL,
    s_dist_04 char(24) NOT NULL,
    s_dist_05 char(24) NOT NULL,
    s_dist_06 char(24) NOT NULL,
    s_dist_07 char(24) NOT NULL,
    s_dist_08 char(24) NOT NULL,
    s_dist_09 char(24) NOT NULL,
    s_dist_10 char(24) NOT NULL,
    s_mtime timestamp,
    FOREIGN KEY (s_w_id) REFERENCES warehouse (w_id),
    FOREIGN KEY (s_i_id) REFERENCES item (i_id),
    PRIMARY KEY (s_w_id, s_i_id)
);
CREATE INDEX IF NOT EXISTS stock_mtime ON stock(s_mtime) WHERE s_mtime NOTNULL;  -- ADDED

CREATE UNLOGGED TABLE IF NOT EXISTS district (
    d_w_id int8 NOT NULL,
    d_id int NOT NULL,
    d_ytd numeric(12, 2) NOT NULL,
    d_tax numeric(4, 4) NOT NULL,
    d_next_o_id int8 NOT NULL,
    d_name varchar(10) NOT NULL,
    d_street_1 varchar(20) NOT NULL,
    d_street_2 varchar(20) NOT NULL,
    d_city varchar(20) NOT NULL,
    d_state char(2) NOT NULL,
    d_zip char(9) NOT NULL,
    FOREIGN KEY (d_w_id) REFERENCES warehouse (w_id),
    PRIMARY KEY (d_w_id, d_id)
);

CREATE UNLOGGED TABLE IF NOT EXISTS customer (
    c_w_id int8 NOT NULL,
    c_d_id int NOT NULL,
    c_id int NOT NULL,
    c_discount numeric(4, 4) NOT NULL,
    c_credit char(2) NOT NULL,
    c_last varchar(16) NOT NULL,
    c_first varchar(16) NOT NULL,
    c_credit_lim numeric(12, 2) NOT NULL,
    c_balance numeric(12, 2) NOT NULL,
    c_ytd_payment float NOT NULL,
    c_payment_cnt int NOT NULL,
    c_delivery_cnt int NOT NULL,
    c_street_1 varchar(20) NOT NULL,
    c_street_2 varchar(20) NOT NULL,
    c_city varchar(20) NOT NULL,
    c_state char(2) NOT NULL,
    c_zip char(9) NOT NULL,
    c_phone char(16) NOT NULL,
    c_since timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    c_middle char(2) NOT NULL,
    c_data varchar(500) NOT NULL,
    c_mtime timestamp,
    FOREIGN KEY (c_w_id, c_d_id) REFERENCES district (d_w_id, d_id),
    PRIMARY KEY (c_w_id, c_d_id, c_id)
);
CREATE INDEX IF NOT EXISTS customer_mtime ON customer(c_mtime) WHERE c_mtime NOTNULL;  -- ADDED

CREATE UNLOGGED TABLE IF NOT EXISTS history (
    h_c_id int NOT NULL,
    h_c_d_id int NOT NULL,
    h_c_w_id int8 NOT NULL,
    h_d_id int NOT NULL,
    h_w_id int8 NOT NULL,
    h_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    h_amount numeric(6, 2) NOT NULL,
    h_data varchar(24) NOT NULL,
    FOREIGN KEY (h_c_w_id, h_c_d_id, h_c_id) REFERENCES customer (c_w_id, c_d_id, c_id),
    FOREIGN KEY (h_w_id, h_d_id) REFERENCES district (d_w_id, d_id)
);

CREATE UNLOGGED TABLE IF NOT EXISTS oorder (
    o_w_id int8 NOT NULL,
    o_d_id int NOT NULL,
    o_id int8 NOT NULL,
    o_c_id int NOT NULL,
    o_carrier_id int DEFAULT NULL,
    o_ol_cnt int NOT NULL,
    o_all_local int NOT NULL,
    o_entry_d timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (o_w_id, o_d_id, o_id),
    FOREIGN KEY (o_w_id, o_d_id, o_c_id) REFERENCES customer (c_w_id, c_d_id, c_id),
    UNIQUE (o_w_id, o_d_id, o_c_id, o_id)
);


CREATE UNLOGGED TABLE IF NOT EXISTS order_line (
    ol_w_id int8 NOT NULL,
    ol_d_id int NOT NULL,
    ol_o_id int8 NOT NULL,
    ol_number int NOT NULL,
    ol_i_id int NOT NULL,
    ol_delivery_d timestamp NULL DEFAULT NULL,
    ol_amount numeric(6, 2) NOT NULL,
    ol_supply_w_id int8 NOT NULL,
    ol_quantity numeric(6, 2) NOT NULL,
    ol_dist_info char(24) NOT NULL,
    FOREIGN KEY (ol_w_id, ol_d_id, ol_o_id) REFERENCES oorder (o_w_id, o_d_id, o_id),
    FOREIGN KEY (ol_supply_w_id, ol_i_id) REFERENCES stock (s_w_id, s_i_id),
    PRIMARY KEY (ol_w_id, ol_d_id, ol_o_id, ol_number)
);


CREATE UNLOGGED TABLE IF NOT EXISTS new_order (
    no_w_id int8 NOT NULL,
    no_d_id int NOT NULL,
    no_o_id int8 NOT NULL,
    FOREIGN KEY (no_w_id, no_d_id, no_o_id) REFERENCES oorder (o_w_id, o_d_id, o_id),
    PRIMARY KEY (no_w_id, no_d_id, no_o_id)
);


/* TPCC_UTILS schema + functions
   Helpers to generate random / dummy data
*/

CREATE SCHEMA IF NOT EXISTS tpcc_utils ;
GRANT USAGE ON SCHEMA tpcc_utils TO public ;

CREATE OR REPLACE FUNCTION tpcc_utils.c_last_name_from_random_syllables() RETURNS text
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
CREATE OR REPLACE FUNCTION tpcc_utils.nurand(A INTEGER, x INTEGER, y INTEGER)
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


create or replace function
  tpcc_utils.random_text(
    min_len int,
    max_len int default 0,
    allowed_chars text default 'abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789'
  ) returns text
language plpgsql
as $$
declare
  ret_string text;
  len int;
begin
    if max_len = 0 then
        len := min_len;
    else
        len := min_len + floor(random()*(max_len - min_len))::int;
    end if;
    select array_to_string(array(select substr(allowed_chars, (1 + floor(random()*length(allowed_chars))::int), 1) from generate_series(1, len)), '') INTO ret_string;
    return ret_string;
end;
$$;



create or replace function
  tpcc_utils.random_text_uuid_based(
    min_len int,
    max_len int default 0
  ) returns text
language plpgsql
as $$
declare
  ret_string text := '';
  len int;
begin
    if max_len = 0 then
        len := min_len;
    else
        len := min_len + floor(random()*(max_len - min_len))::int;
    end if;

    loop
       ret_string := ret_string || gen_random_uuid() ;
       if length(ret_string) >= len then
           exit ;
       end if ;
    end loop ;
    return substring(ret_string, 1, len) ;
end;
$$;

create or replace function
  tpcc_utils.random_int(
    min_val int default 0,
    max_val int default 2147483647
  ) returns int
language sql
as $$
    select min_val + ((max_val - min_val)*random())::int;
$$;


create or replace function
  tpcc_utils.random_float(
    min_val float default 0,
    max_val float default 1E+308
  ) returns float
language sql
as $$
    select min_val + ((max_val - min_val)*random());
$$;





create or replace function tpcc_utils.new_order_add_line_items(warehouse_id int8, district_id int, order_id int8,
  ol_cnt int, d_tax numeric, w_tax numeric, c_discount numeric) returns void
language plpgsql
as $$
declare
  l_i_id int;
  l_i_price numeric;
  l_i_qty numeric;
  l_i_name text;
  l_i_data text;
  l_s_qty int;
  l_s_data text;
  l_dist_info text;
begin

  for i in 1 .. ol_cnt loop
    l_i_id := tpcc_utils.random_int(1, 100000);
    l_i_qty := tpcc_utils.random_int(1, 10);

    SELECT i_price, i_name, i_data INTO l_i_price, l_i_name, l_i_data FROM item WHERE i_id = l_i_id;

    -- Get stock info
    SELECT s_quantity, s_data, s_dist_01
    INTO l_s_qty, l_s_data, l_dist_info
    FROM stock
    WHERE s_i_id = l_i_id AND s_w_id = warehouse_id
    FOR UPDATE;

    -- Update stock quantity
    UPDATE stock
    SET s_quantity = s_quantity - l_i_qty,
        s_ytd = s_ytd + l_i_qty,
        s_order_cnt = s_order_cnt + 1,
        s_mtime = now()
    WHERE s_i_id = l_i_id AND s_w_id = warehouse_id;

    -- Insert order line
    INSERT INTO order_line (
        ol_o_id, ol_d_id, ol_w_id, ol_number,
        ol_i_id, ol_supply_w_id, ol_delivery_d,
        ol_quantity, ol_amount, ol_dist_info
    )
    VALUES (
        order_id, district_id, warehouse_id, i,
        l_i_id, warehouse_id, NULL,
        l_i_qty, l_i_qty * l_i_price * (1 + w_tax + d_tax) * (1 - c_discount), l_dist_info
    );

  end loop ;

end;
$$ ;


create or replace function tpcc_utils.get_low_stock_items(warehouse_id int8, district_id int, threshold int) returns TABLE(item_id int, stock int)
language plpgsql
as $$
declare
  l_next_o_id int8;
  l_item_ids int8[];
  r record;
begin

-- Get next order ID for the district
SELECT d_next_o_id into l_next_o_id
FROM district
WHERE d_w_id = warehouse_id AND d_id = district_id;

-- Examine all items on the last 20 orders for the district, comprised of:
-- (20 * items-per-order) row selections with data retrieval.
SELECT array_agg(DISTINCT ol_i_id) INTO l_item_ids
FROM order_line
WHERE ol_w_id = warehouse_id AND ol_d_id = district_id
  AND ol_o_id >= l_next_o_id - 20 AND ol_o_id < l_next_o_id;

-- Examine, for each distinct item selected, if the level of stock available at the home warehouse is below the threshold
RETURN QUERY
SELECT s_i_id, s_quantity
FROM stock
WHERE s_w_id = warehouse_id
AND s_i_id = ANY(l_item_ids::int8[])
AND s_quantity < threshold;

end;
$$;
