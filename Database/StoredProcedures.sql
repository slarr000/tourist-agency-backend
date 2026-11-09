-- PostgreSQL-stored database layer for the tourism representative coursework system.
-- This script mirrors the report queries exposed by ReportRepository and keeps the
-- business logic in the database instead of in raw application code.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.employee_accounts (
    employee_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Admin' CHECK (role = 'Admin'),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_employee_accounts_login
    ON public.employee_accounts (LOWER(login));

CREATE OR REPLACE PROCEDURE public.app_create_employee_account_proc(
    IN p_login TEXT,
    IN p_password TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_login IS NULL OR BTRIM(p_login) = '' THEN
        RAISE EXCEPTION 'Employee login is required.' USING ERRCODE = '22023';
    END IF;
    IF p_password IS NULL OR CHAR_LENGTH(p_password) < 1 OR CHAR_LENGTH(p_password) > 6 THEN
        RAISE EXCEPTION 'Employee password must contain between 1 and 6 characters.' USING ERRCODE = '22023';
    END IF;

    INSERT INTO public.employee_accounts (login, password_hash, role)
    VALUES (BTRIM(p_login), public.crypt(p_password, public.gen_salt('bf', 12)), 'Admin');
END;
$$;

CREATE OR REPLACE PROCEDURE public.app_authenticate_employee_proc(
    IN p_login TEXT,
    IN p_password TEXT,
    INOUT p_employee JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_employee := NULL;
    IF p_login IS NULL OR BTRIM(p_login) = '' OR p_password IS NULL THEN
        RETURN;
    END IF;

    SELECT JSONB_BUILD_OBJECT(
        'employeeId', employee.employee_id,
        'login', employee.login,
        'role', employee.role
    )
    INTO p_employee
    FROM public.employee_accounts AS employee
    WHERE LOWER(employee.login) = LOWER(BTRIM(p_login))
      AND employee.is_active
      AND employee.role = 'Admin'
      AND employee.password_hash = public.crypt(p_password, employee.password_hash);
END;
$$;

CREATE OR REPLACE FUNCTION GetCustomsTouristList(p_category TEXT DEFAULT NULL)
RETURNS TABLE (
    full_name TEXT,
    passport_number TEXT,
    flight_number TEXT,
    category TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CONCAT(t.tourist_surname, ' ', t.tourist_name)::TEXT AS full_name,
        p.passport_number::TEXT AS passport_number,
        f.flight_number::TEXT AS flight_number,
        t.category::TEXT AS category
    FROM "Tourist Information" t
    LEFT JOIN "Tourist's Passport Details" p ON t.tourist_id = p.tourist_id
    LEFT JOIN "Flights" f ON t.flight_id = f.flight_id
    WHERE p_category IS NULL OR t.category = p_category
    ORDER BY f.flight_date, t.tourist_surname;
END;
$$;

DROP FUNCTION IF EXISTS public.gethotelcheckinlist(TEXT);

CREATE OR REPLACE FUNCTION GetHotelCheckInList(p_hotel_name TEXT DEFAULT NULL)
RETURNS TABLE (
    hotel_name TEXT,
    tourist_full_name TEXT,
    check_in_date DATE,
    check_out_date DATE,
    room_number TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.hotel_name::TEXT AS hotel_name,
        CONCAT(t.tourist_surname, ' ', t.tourist_name)::TEXT AS tourist_full_name,
        b.check_in_date::DATE AS check_in_date,
        b.check_out_date::DATE AS check_out_date,
        b.room_number::TEXT AS room_number
    FROM "Bookings" b
    JOIN "Hotels" h ON b.hotel_id = h.hotel_id
    JOIN "Tourist Information" t ON b.tourist_id = t.tourist_id
    WHERE p_hotel_name IS NULL OR h.hotel_name = p_hotel_name
    ORDER BY h.hotel_name, b.check_in_date;
END;
$$;

CREATE OR REPLACE FUNCTION GetTouristCount(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_category TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    result_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT t.tourist_id)
    INTO result_count
    FROM "Tourist Information" t
    JOIN "Tourist Visits" tv ON t.tourist_id = tv.tourist_id
    WHERE (p_start_date IS NULL OR tv.arrival_date >= p_start_date)
      AND (p_end_date IS NULL OR tv.arrival_date <= p_end_date)
      AND (p_category IS NULL OR t.category = p_category);

    RETURN result_count;
END;
$$;

CREATE OR REPLACE FUNCTION GetHotelOccupancy()
RETURNS TABLE (
    hotel_name TEXT,
    country TEXT,
    total_tourists BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.hotel_name::TEXT AS hotel_name,
        h.country::TEXT AS country,
        COUNT(b.tourist_id)::BIGINT AS total_tourists
    FROM "Hotels" h
    LEFT JOIN "Bookings" b ON h.hotel_id = b.hotel_id
    GROUP BY h.hotel_name, h.country
    ORDER BY total_tourists DESC;
END;
$$;

CREATE OR REPLACE FUNCTION GetExcursionTouristsCount(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    result_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT eb.tourist_id)
    INTO result_count
    FROM "Excursion Bookings" eb
    JOIN "Excursions" e ON eb.excursion_id = e.excursion_id
    WHERE e.schedule_date >= p_start_date AND e.schedule_date <= p_end_date;

    RETURN result_count;
END;
$$;

CREATE OR REPLACE FUNCTION GetExcursionSummary()
RETURNS TABLE (
    visit_place TEXT,
    total_tourists BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.excursion_name::TEXT AS visit_place,
        COUNT(eb.excursion_id)::BIGINT AS total_tourists
    FROM "Excursions" e
    LEFT JOIN "Excursion Bookings" eb ON e.excursion_id = eb.excursion_id
    GROUP BY e.excursion_name
    ORDER BY total_tourists DESC;
END;
$$;

CREATE OR REPLACE FUNCTION GetFlightLoadReport(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    flight_number TEXT,
    flight_date DATE,
    total_tourists BIGINT,
    tourists_with_children BIGINT,
    total_cargo_weight NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.flight_number::TEXT AS flight_number,
        f.flight_date::DATE AS flight_date,
        COUNT(DISTINCT t.tourist_id)::BIGINT AS total_tourists,
        COUNT(DISTINCT CASE WHEN t.tourist_children = 'Да' THEN t.tourist_id END)::BIGINT AS tourists_with_children,
        COALESCE(SUM(c.actual_weight), 0)::NUMERIC AS total_cargo_weight
    FROM "Flights" f
    LEFT JOIN "Tourist Information" t ON f.flight_id = t.flight_id
    LEFT JOIN "Tourist Cargo" c ON t.tourist_id = c.tourist_id
    WHERE f.flight_date >= p_start_date AND f.flight_date <= p_end_date
    GROUP BY f.flight_number, f.flight_date
    ORDER BY f.flight_date;
END;
$$;

CREATE OR REPLACE FUNCTION GetCargoSummaryReport()
RETURNS TABLE (
    flight_number TEXT,
    total_places BIGINT,
    total_actual_weight NUMERIC,
    total_insurance_cost NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.flight_number::TEXT AS flight_number,
        COALESCE(SUM(c.places_count), 0)::BIGINT AS total_places,
        COALESCE(SUM(c.actual_weight), 0)::NUMERIC AS total_actual_weight,
        COALESCE(SUM(c.insurance_cost), 0)::NUMERIC AS total_insurance_cost
    FROM "Flights" f
    JOIN "Tourist Information" t ON f.flight_id = t.flight_id
    JOIN "Tourist Cargo" c ON t.tourist_id = c.tourist_id
    GROUP BY f.flight_number
    ORDER BY total_actual_weight DESC;
END;
$$;

CREATE OR REPLACE FUNCTION GetFinancialSummary(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_income NUMERIC,
    total_expense NUMERIC,
    net_profit NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(CASE WHEN transaction_type = 'Доход' THEN amount ELSE 0 END), 0)::NUMERIC AS total_income,
        COALESCE(SUM(CASE WHEN transaction_type = 'Расход' THEN amount ELSE 0 END), 0)::NUMERIC AS total_expense,
        COALESCE(SUM(CASE WHEN transaction_type = 'Доход' THEN amount ELSE -amount END), 0)::NUMERIC AS net_profit
    FROM "Finances"
    WHERE transaction_date >= p_start_date AND transaction_date <= p_end_date;
END;
$$;

CREATE OR REPLACE FUNCTION GetCargoTypeStatistics()
RETURNS TABLE (
    cargo_type TEXT,
    total_weight NUMERIC,
    percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.cargo_type::TEXT AS cargo_type,
        SUM(c.actual_weight)::NUMERIC AS total_weight,
        ROUND((SUM(c.actual_weight) * 100.0 / NULLIF((SELECT SUM(actual_weight) FROM "Tourist Cargo"), 0)), 2)::NUMERIC AS percentage
    FROM "Tourist Cargo" c
    GROUP BY c.cargo_type
    ORDER BY total_weight DESC;
END;
$$;

CREATE OR REPLACE FUNCTION GetTouristsCategoryRatio(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    holiday_count BIGINT,
    shop_tour_count BIGINT,
    total_tourists BIGINT,
    holiday_percentage NUMERIC,
    shop_tour_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(CASE WHEN t.category = 'Отдых' THEN 1 END)::BIGINT AS holiday_count,
        COUNT(CASE WHEN t.category = 'Шоп-тур' THEN 1 END)::BIGINT AS shop_tour_count,
        COUNT(t.tourist_id)::BIGINT AS total_tourists,
        COALESCE(ROUND((COUNT(CASE WHEN t.category = 'Отдых' THEN 1 END) * 100.0 / NULLIF(COUNT(t.tourist_id), 0)), 2), 0)::NUMERIC AS holiday_percentage,
        COALESCE(ROUND((COUNT(CASE WHEN t.category = 'Шоп-тур' THEN 1 END) * 100.0 / NULLIF(COUNT(t.tourist_id), 0)), 2), 0)::NUMERIC AS shop_tour_percentage
    FROM "Tourist Information" t
    LEFT JOIN "Flights" f ON t.flight_id = f.flight_id
    WHERE (p_start_date IS NULL OR f.flight_date >= p_start_date)
      AND (p_end_date IS NULL OR f.flight_date <= p_end_date);
END;
$$;

CREATE OR REPLACE FUNCTION GetFlightTouristDetails(p_flight_number TEXT)
RETURNS TABLE (
    full_name TEXT,
    hotel_name TEXT,
    cargo_type TEXT,
    cargo_weight NUMERIC,
    tag_number TEXT,
    marking TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CONCAT(t.tourist_surname, ' ', t.tourist_name)::TEXT AS full_name,
        h.hotel_name::TEXT AS hotel_name,
        c.cargo_type::TEXT AS cargo_type,
        c.actual_weight::NUMERIC AS cargo_weight,
        c.tags::TEXT AS tag_number,
        c.marking::TEXT AS marking
    FROM "Tourist Information" t
    JOIN "Flights" f ON t.flight_id = f.flight_id
    LEFT JOIN "Bookings" b ON t.tourist_id = b.tourist_id
    LEFT JOIN "Hotels" h ON b.hotel_id = h.hotel_id
    LEFT JOIN "Tourist Cargo" c ON t.tourist_id = c.tourist_id
    WHERE f.flight_number = p_flight_number
    ORDER BY t.tourist_surname;
END;
$$;

CREATE OR REPLACE FUNCTION GetPassportControlReport()
RETURNS TABLE (
    full_name TEXT,
    passport_number TEXT,
    expiration_date DATE,
    days_until_expiration INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CONCAT(t.tourist_surname, ' ', t.tourist_name)::TEXT AS full_name,
        p.passport_number::TEXT AS passport_number,
        p.expiry_date::DATE AS expiration_date,
        (p.expiry_date - CURRENT_DATE)::INTEGER AS days_until_expiration
    FROM "Tourist Information" t
    JOIN "Tourist's Passport Details" p ON t.tourist_id = p.tourist_id
    ORDER BY p.expiry_date ASC;
END;
$$;

CREATE OR REPLACE FUNCTION GetFamilyToursReport()
RETURNS TABLE (
    parent_full_name TEXT,
    child_name TEXT,
    child_age INTEGER,
    flight_number TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CONCAT(t.tourist_surname, ' ', t.tourist_name)::TEXT AS parent_full_name,
        CONCAT(tc.last_name, ' ', tc.first_name)::TEXT AS child_name,
        EXTRACT(YEAR FROM AGE(tc.date_of_birth))::INTEGER AS child_age,
        f.flight_number::TEXT AS flight_number
    FROM "Tourist Information" t
    JOIN "Tourist Children" tc ON t.tourist_id = tc.tourist_id
    LEFT JOIN "Flights" f ON t.flight_id = f.flight_id
    ORDER BY f.flight_date, child_age;
END;
$$;

CREATE OR REPLACE FUNCTION GetVisaStatusReport(p_has_visa_filter BOOLEAN)
RETURNS TABLE (
    full_name TEXT,
    flight_number TEXT,
    flight_date DATE,
    has_visa BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CONCAT(t.tourist_surname, ' ', t.tourist_name)::TEXT AS full_name,
        f.flight_number::TEXT AS flight_number,
        f.flight_date::DATE AS flight_date,
        t.has_visa::BOOLEAN AS has_visa
    FROM "Tourist Information" t
    LEFT JOIN "Flights" f ON t.flight_id = f.flight_id
    WHERE t.has_visa = p_has_visa_filter
    ORDER BY f.flight_date;
END;
$$;

CREATE OR REPLACE FUNCTION GetTouristProfile(p_tourist_id INTEGER)
RETURNS TABLE (
    full_name TEXT,
    category TEXT,
    has_visa BOOLEAN,
    passport_number TEXT,
    flight_number TEXT,
    hotel_name TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CONCAT(t.tourist_surname, ' ', t.tourist_name)::TEXT AS full_name,
        t.category::TEXT AS category,
        t.has_visa::BOOLEAN AS has_visa,
        p.passport_number::TEXT AS passport_number,
        f.flight_number::TEXT AS flight_number,
        h.hotel_name::TEXT AS hotel_name
    FROM "Tourist Information" t
    LEFT JOIN "Tourist's Passport Details" p ON t.tourist_id = p.tourist_id
    LEFT JOIN "Flights" f ON t.flight_id = f.flight_id
    LEFT JOIN "Bookings" b ON t.tourist_id = b.tourist_id
    LEFT JOIN "Hotels" h ON b.hotel_id = h.hotel_id
    WHERE t.tourist_id = p_tourist_id;
END;
$$;

-- Generic data access functions used by CRUD repositories. Entity names are
-- mapped to fixed public tables; caller-supplied values are always parameters.
CREATE OR REPLACE FUNCTION public.app_entity_info(p_entity TEXT)
RETURNS TABLE (table_name TEXT, id_column TEXT)
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT mapping.table_name, mapping.id_column
    FROM (VALUES
        ('agency', 'Agencies', 'agency_id'),
        ('booking', 'Bookings', 'booking_id'),
        ('excursion_booking', 'Excursion Bookings', 'booking_id'),
        ('excursion', 'Excursions', 'excursion_id'),
        ('finance', 'Finances', 'transaction_id'),
        ('flight', 'Flights', 'flight_id'),
        ('hotel', 'Hotels', 'hotel_id'),
        ('passport', 'Tourist''s Passport Details', 'passport_id'),
        ('tourist_cargo', 'Tourist Cargo', 'cargo_id'),
        ('tourist_child', 'Tourist Children', 'child_id'),
        ('tourist', 'Tourist Information', 'tourist_id'),
        ('tourist_visit', 'Tourist Visits', 'visit_id'),
        ('tourist_directory', 'Tourists', 'Id')
    ) AS mapping(entity, table_name, id_column)
    WHERE mapping.entity = lower(p_entity);
$$;

CREATE OR REPLACE FUNCTION public.app_get_all(p_entity TEXT)
RETURNS SETOF JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_table TEXT;
    v_id TEXT;
BEGIN
    SELECT info.table_name, info.id_column
    INTO STRICT v_table, v_id
    FROM public.app_entity_info(p_entity) AS info;

    RETURN QUERY EXECUTE format(
        'SELECT to_jsonb(row_data) FROM public.%I AS row_data ORDER BY row_data.%I',
        v_table, v_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.app_get_by_id(p_entity TEXT, p_id INTEGER)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_table TEXT;
    v_id TEXT;
    v_record JSONB;
BEGIN
    SELECT info.table_name, info.id_column
    INTO STRICT v_table, v_id
    FROM public.app_entity_info(p_entity) AS info;

    EXECUTE format(
        'SELECT to_jsonb(row_data) FROM public.%I AS row_data WHERE row_data.%I = $1',
        v_table, v_id)
    INTO v_record
    USING p_id;

    RETURN v_record;
END;
$$;

CREATE OR REPLACE FUNCTION public.app_create(p_entity TEXT, p_data JSONB)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_table TEXT;
    v_id TEXT;
    v_data JSONB;
    v_columns TEXT;
    v_values TEXT;
    v_new_id INTEGER;
BEGIN
    SELECT info.table_name, info.id_column
    INTO STRICT v_table, v_id
    FROM public.app_entity_info(p_entity) AS info;

    SELECT COALESCE(jsonb_object_agg(column_info.column_name, input.value), '{}'::JSONB)
    INTO v_data
    FROM jsonb_each(p_data) AS input(key, value)
    JOIN information_schema.columns AS column_info
      ON column_info.table_schema = 'public'
     AND column_info.table_name = v_table
     AND lower(column_info.column_name) = lower(input.key)
     AND column_info.column_name <> v_id
     AND column_info.is_identity <> 'ALWAYS';

    IF (SELECT COUNT(*) FROM jsonb_object_keys(v_data))
       <> (SELECT COUNT(*) FROM jsonb_object_keys(p_data)) THEN
        RAISE EXCEPTION 'Unknown or non-writable fields for entity %', p_entity
            USING ERRCODE = '22023';
    END IF;

    SELECT
        string_agg(format('%I', column_info.column_name), ', ' ORDER BY column_info.ordinal_position),
        string_agg(
            format('(jsonb_populate_record(NULL::public.%I, $1)).%I', v_table, column_info.column_name),
            ', ' ORDER BY column_info.ordinal_position)
    INTO v_columns, v_values
    FROM information_schema.columns AS column_info
    WHERE column_info.table_schema = 'public'
      AND column_info.table_name = v_table
      AND v_data ? column_info.column_name;

    IF v_columns IS NULL THEN
        RAISE EXCEPTION 'No writable fields supplied for entity %', p_entity
            USING ERRCODE = '22023';
    END IF;

    EXECUTE format(
        'INSERT INTO public.%I (%s) SELECT %s RETURNING %I',
        v_table, v_columns, v_values, v_id)
    INTO v_new_id
    USING v_data;

    RETURN v_new_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.app_update(p_entity TEXT, p_id INTEGER, p_data JSONB)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_table TEXT;
    v_id TEXT;
    v_data JSONB;
    v_set_clause TEXT;
    v_rows INTEGER;
BEGIN
    SELECT info.table_name, info.id_column
    INTO STRICT v_table, v_id
    FROM public.app_entity_info(p_entity) AS info;

    SELECT COALESCE(jsonb_object_agg(column_info.column_name, input.value), '{}'::JSONB)
    INTO v_data
    FROM jsonb_each(p_data) AS input(key, value)
    JOIN information_schema.columns AS column_info
      ON column_info.table_schema = 'public'
     AND column_info.table_name = v_table
     AND lower(column_info.column_name) = lower(input.key)
     AND column_info.column_name <> v_id
     AND column_info.is_identity <> 'ALWAYS';

    IF (SELECT COUNT(*) FROM jsonb_object_keys(v_data))
       <> (SELECT COUNT(*) FROM jsonb_object_keys(p_data)) THEN
        RAISE EXCEPTION 'Unknown or non-writable fields for entity %', p_entity
            USING ERRCODE = '22023';
    END IF;

    SELECT string_agg(
        format('%I = (jsonb_populate_record(NULL::public.%I, $1)).%I',
            column_info.column_name, v_table, column_info.column_name),
        ', ' ORDER BY column_info.ordinal_position)
    INTO v_set_clause
    FROM information_schema.columns AS column_info
    WHERE column_info.table_schema = 'public'
      AND column_info.table_name = v_table
      AND v_data ? column_info.column_name;

    IF v_set_clause IS NULL THEN
        RAISE EXCEPTION 'No writable fields supplied for entity %', p_entity
            USING ERRCODE = '22023';
    END IF;

    EXECUTE format(
        'UPDATE public.%I AS target SET %s WHERE target.%I = $2',
        v_table, v_set_clause, v_id)
    USING v_data, p_id;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN v_rows > 0;
END;
$$;

CREATE OR REPLACE FUNCTION public.app_delete(p_entity TEXT, p_id INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_table TEXT;
    v_id TEXT;
    v_rows INTEGER;
BEGIN
    SELECT info.table_name, info.id_column
    INTO STRICT v_table, v_id
    FROM public.app_entity_info(p_entity) AS info;

    EXECUTE format('DELETE FROM public.%I WHERE %I = $1', v_table, v_id)
    USING p_id;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN v_rows > 0;
END;
$$;

CREATE OR REPLACE FUNCTION public.app_get_hotels(
    p_search_term TEXT,
    p_min_stars INTEGER,
    p_max_price NUMERIC,
    p_page_size INTEGER,
    p_page_number INTEGER
)
RETURNS SETOF JSONB
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page_size < 1 OR p_page_size > 100 OR p_page_number < 1 THEN
        RAISE EXCEPTION 'Invalid hotel pagination parameters'
            USING ERRCODE = '22023';
    END IF;

    RETURN QUERY
    SELECT to_jsonb(h)
    FROM public."Hotels" AS h
    WHERE (p_search_term IS NULL OR h.hotel_name ILIKE '%' || p_search_term || '%')
      AND (p_min_stars IS NULL OR h.stars_count >= p_min_stars)
      AND (p_max_price IS NULL OR h.price_per_night <= p_max_price)
    ORDER BY h.hotel_id
    LIMIT p_page_size
    OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

-- PostgreSQL procedures used by the application. The existing functions above
-- contain the reusable SQL implementation; these CALL entry points expose it
-- through actual CREATE PROCEDURE objects as required by the coursework.
CREATE OR REPLACE PROCEDURE public.app_get_all_proc(
    IN p_entity TEXT,
    INOUT p_result JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(jsonb_agg(records.value), '[]'::JSONB)
    INTO p_result
    FROM public.app_get_all(p_entity) AS records(value);
END;
$$;

CREATE OR REPLACE PROCEDURE public.app_get_by_id_proc(
    IN p_entity TEXT,
    IN p_id INTEGER,
    INOUT p_result JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_result := public.app_get_by_id(p_entity, p_id);
END;
$$;

CREATE OR REPLACE PROCEDURE public.app_create_proc(
    IN p_entity TEXT,
    IN p_data JSONB,
    INOUT p_result INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_result := public.app_create(p_entity, p_data);
END;
$$;

CREATE OR REPLACE PROCEDURE public.app_update_proc(
    IN p_entity TEXT,
    IN p_id INTEGER,
    IN p_data JSONB,
    INOUT p_result BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_result := public.app_update(p_entity, p_id, p_data);
END;
$$;

CREATE OR REPLACE PROCEDURE public.app_delete_proc(
    IN p_entity TEXT,
    IN p_id INTEGER,
    INOUT p_result BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_result := public.app_delete(p_entity, p_id);
END;
$$;

CREATE OR REPLACE PROCEDURE public.app_get_hotels_proc(
    IN p_search_term TEXT,
    IN p_min_stars INTEGER,
    IN p_max_price NUMERIC,
    IN p_page_size INTEGER,
    IN p_page_number INTEGER,
    INOUT p_result JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(jsonb_agg(records.value), '[]'::JSONB)
    INTO p_result
    FROM public.app_get_hotels(
        p_search_term, p_min_stars, p_max_price, p_page_size, p_page_number
    ) AS records(value);
END;
$$;
