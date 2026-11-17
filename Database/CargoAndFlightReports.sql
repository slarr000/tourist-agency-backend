-- Reports 12 and 15. Existing cargo and participation records are not modified.
BEGIN;

ALTER TABLE public."Tourist Cargo" ADD COLUMN IF NOT EXISTS shipped_date DATE;

CREATE OR REPLACE FUNCTION public.coursework_cargo_type_statistics(
    p_start_date DATE DEFAULT NULL, p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (cargo_type TEXT, total_places BIGINT, total_weight NUMERIC,
               total_volume_weight NUMERIC, percentage NUMERIC)
LANGUAGE sql STABLE AS $$
    WITH sent AS (
        SELECT c.cargo_type, c.places_count, c.actual_weight, c.volume_weight
        FROM public."Tourist Cargo" c
        WHERE c.status = 'Отправлен' AND c.shipped_date IS NOT NULL
          AND (p_start_date IS NULL OR c.shipped_date >= p_start_date)
          AND (p_end_date IS NULL OR c.shipped_date <= p_end_date)
    )
    SELECT s.cargo_type::TEXT, SUM(s.places_count)::BIGINT, SUM(s.actual_weight)::NUMERIC,
           SUM(s.volume_weight)::NUMERIC,
           ROUND(SUM(s.actual_weight) * 100.0 / NULLIF(SUM(SUM(s.actual_weight)) OVER (), 0), 2)::NUMERIC
    FROM sent s GROUP BY s.cargo_type ORDER BY SUM(s.actual_weight) DESC, s.cargo_type;
$$;

CREATE OR REPLACE PROCEDURE public.coursework_flight_details_by_id(
    IN p_flight_id INTEGER, INOUT p_result JSONB
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_flight_id IS NULL OR p_flight_id < 1 OR NOT EXISTS (
        SELECT 1 FROM public."Flights" WHERE flight_id = p_flight_id
    ) THEN
        RAISE EXCEPTION 'Invalid flight' USING ERRCODE = '22023';
    END IF;

    WITH adult_flights AS (
        SELECT tourist_id FROM public."Tourist Information" WHERE flight_id = p_flight_id
        UNION SELECT tourist_id FROM public."Tourist Visits" WHERE flight_id = p_flight_id
    ), passengers AS (
        SELECT f.flight_number::TEXT, f.flight_date,
               CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)::TEXT AS full_name,
               t.category::TEXT, t.has_visa, h.hotel_name, h.room_number,
               c.cargo_type::TEXT, c.places_count, c.actual_weight::NUMERIC AS cargo_weight,
               c.volume_weight::NUMERIC, c.tags::TEXT, c.marking::TEXT
        FROM public."Flights" f
        JOIN adult_flights af ON TRUE
        JOIN public."Tourist Information" t ON t.tourist_id = af.tourist_id
        LEFT JOIN LATERAL (
            SELECT STRING_AGG(FORMAT('%s (номер %s, %s — %s)', h.hotel_name, b.room_number, b.check_in_date, b.check_out_date), '; ' ORDER BY b.check_in_date)::TEXT AS hotel_name,
                   STRING_AGG(DISTINCT b.room_number, ', ' ORDER BY b.room_number)::TEXT AS room_number
            FROM public."Bookings" b
            JOIN public."Hotels" h ON h.hotel_id = b.hotel_id
            JOIN public."Tourist Visits" v ON v.visit_id = b.visit_id
            WHERE b.tourist_id = t.tourist_id AND v.flight_id = f.flight_id
        ) h ON TRUE
        LEFT JOIN public."Tourist Cargo" c ON c.tourist_id = t.tourist_id AND c.flight_id = f.flight_id
        WHERE f.flight_id = p_flight_id
        UNION ALL
        SELECT f.flight_number::TEXT, f.flight_date,
               CONCAT_WS(' ', child.last_name, child.first_name, child.patronymic)::TEXT,
               'Ребёнок'::TEXT, NULL::BOOLEAN, h.hotel_name, h.room_number,
               NULL::TEXT, NULL::INTEGER, NULL::NUMERIC, NULL::NUMERIC, NULL::TEXT, NULL::TEXT
        FROM public."Flights" f
        JOIN (
            SELECT DISTINCT cv.child_id
            FROM public."Child Visits" cv
            JOIN public."Tourist Visits" v ON v.visit_id = cv.visit_id
            WHERE v.flight_id = p_flight_id
        ) passengers ON TRUE
        JOIN public."Tourist Children" child ON child.child_id = passengers.child_id
        LEFT JOIN LATERAL (
            SELECT STRING_AGG(FORMAT('%s (номер %s, %s — %s)', h.hotel_name, b.room_number, b.check_in_date, b.check_out_date), '; ' ORDER BY b.check_in_date)::TEXT AS hotel_name,
                   STRING_AGG(DISTINCT b.room_number, ', ' ORDER BY b.room_number)::TEXT AS room_number
            FROM public."Child Bookings" cb
            JOIN public."Bookings" b ON b.booking_id = cb.booking_id
            JOIN public."Hotels" h ON h.hotel_id = b.hotel_id
            JOIN public."Tourist Visits" v ON v.visit_id = cb.visit_id
            WHERE cb.child_id = child.child_id AND v.flight_id = f.flight_id
        ) h ON TRUE
        WHERE f.flight_id = p_flight_id
    )
    SELECT COALESCE(JSONB_AGG(TO_JSONB(passengers) ORDER BY full_name, cargo_type, marking), '[]'::JSONB)
    INTO p_result FROM passengers;
END;
$$;

COMMIT;
