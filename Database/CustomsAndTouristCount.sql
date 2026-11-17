-- Install after ChildParticipation.sql. No participation records are created.
BEGIN;

CREATE OR REPLACE PROCEDURE public.coursework_customs_by_flight(
    IN p_flight_id INTEGER, IN p_category TEXT, INOUT p_result JSONB
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_flight_id IS NOT NULL AND (p_flight_id < 1 OR NOT EXISTS (
        SELECT 1 FROM public."Flights" WHERE flight_id = p_flight_id
    )) THEN
        RAISE EXCEPTION 'Invalid flight' USING ERRCODE = '22023';
    END IF;

    WITH adult_flights AS (
        SELECT tourist_id, flight_id FROM public."Tourist Information" WHERE flight_id IS NOT NULL
        UNION
        SELECT tourist_id, flight_id FROM public."Tourist Visits" WHERE flight_id IS NOT NULL
    ), child_flights AS (
        SELECT DISTINCT cv.child_id, cv.tourist_id, v.flight_id
        FROM public."Child Visits" cv
        JOIN public."Tourist Visits" v ON v.visit_id = cv.visit_id AND v.tourist_id = cv.tourist_id
        WHERE v.flight_id IS NOT NULL
    ), passengers AS (
        SELECT 'Взрослый'::TEXT AS participant_type,
               CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)::TEXT AS full_name,
               t.category::TEXT AS category, NULL::TEXT AS guardian_name,
               passports.numbers AS passport_number, NULL::TEXT AS birth_certificate_number,
               f.flight_number::TEXT AS flight_number, f.flight_date::DATE AS flight_date,
               f.flight_id
        FROM adult_flights af
        JOIN public."Tourist Information" t ON t.tourist_id = af.tourist_id
        JOIN public."Flights" f ON f.flight_id = af.flight_id
        LEFT JOIN LATERAL (
            SELECT STRING_AGG(DISTINCT CONCAT_WS(' ', p.type_passport, p.passport_serial, p.passport_number),
                              '; ' ORDER BY CONCAT_WS(' ', p.type_passport, p.passport_serial, p.passport_number))::TEXT AS numbers
            FROM public."Tourist's Passport Details" p WHERE p.tourist_id = t.tourist_id
        ) passports ON TRUE
        WHERE (p_flight_id IS NULL OR f.flight_id = p_flight_id)
          AND (p_category IS NULL OR t.category = p_category)
        UNION ALL
        SELECT 'Ребёнок'::TEXT, CONCAT_WS(' ', c.last_name, c.first_name, c.patronymic)::TEXT,
               t.category::TEXT, CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)::TEXT,
               NULL::TEXT, c.birth_certificate_number::TEXT, f.flight_number::TEXT, f.flight_date::DATE, f.flight_id
        FROM child_flights cf
        JOIN public."Tourist Children" c ON c.child_id = cf.child_id AND c.tourist_id = cf.tourist_id
        JOIN public."Tourist Information" t ON t.tourist_id = cf.tourist_id
        JOIN public."Flights" f ON f.flight_id = cf.flight_id
        WHERE (p_flight_id IS NULL OR f.flight_id = p_flight_id)
          AND (p_category IS NULL OR t.category = p_category)
    )
    SELECT COALESCE(JSONB_AGG(TO_JSONB(passengers) ORDER BY flight_date, flight_number, flight_id, full_name, participant_type), '[]'::JSONB)
    INTO p_result FROM passengers;
END;
$$;

CREATE OR REPLACE PROCEDURE public.coursework_tourist_count_with_children(
    IN p_start_date DATE, IN p_end_date DATE, IN p_category TEXT, INOUT p_result JSONB
)
LANGUAGE plpgsql AS $$
DECLARE
    v_adults BIGINT;
    v_children BIGINT;
BEGIN
    IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_start_date > p_end_date THEN
        RAISE EXCEPTION 'Invalid date range' USING ERRCODE = '22023';
    END IF;

    SELECT COUNT(DISTINCT v.tourist_id), COUNT(DISTINCT cv.child_id)
    INTO v_adults, v_children
    FROM public."Tourist Visits" v
    JOIN public."Tourist Information" t ON t.tourist_id = v.tourist_id
    LEFT JOIN public."Child Visits" cv ON cv.visit_id = v.visit_id AND cv.tourist_id = v.tourist_id
    WHERE (p_start_date IS NULL OR v.arrival_date >= p_start_date)
      AND (p_end_date IS NULL OR v.arrival_date <= p_end_date)
      AND (p_category IS NULL OR t.category = p_category);

    p_result := JSONB_BUILD_OBJECT(
        'adult_count', v_adults, 'children_count', v_children,
        'total_tourists', v_adults + v_children, 'category', COALESCE(p_category, 'Все категории'),
        'start_date', p_start_date, 'end_date', p_end_date
    );
END;
$$;

COMMIT;
