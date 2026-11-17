-- Исправление отчета №15. Данные не изменяются.
-- Сначала необходимо установить LinkBookingsToVisits.sql.
CREATE OR REPLACE FUNCTION public.coursework_flight_tourist_details(p_flight_number TEXT)
RETURNS TABLE (flight_number TEXT, flight_date DATE, full_name TEXT, category TEXT, has_visa BOOLEAN,
               hotel_name TEXT, room_number TEXT, cargo_type TEXT, places_count INTEGER,
               cargo_weight NUMERIC, volume_weight NUMERIC, tags TEXT, marking TEXT)
LANGUAGE sql STABLE AS $$
    WITH adult_flights AS (
        SELECT tourist_id, flight_id FROM public."Tourist Information" WHERE flight_id IS NOT NULL
        UNION SELECT tourist_id, flight_id FROM public."Tourist Visits"
    ), rows AS (
        SELECT f.flight_number::TEXT, f.flight_date,
               CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)::TEXT AS full_name,
               t.category::TEXT, t.has_visa, h.hotel_name, h.room_number,
               c.cargo_type::TEXT, c.places_count, c.actual_weight::NUMERIC AS cargo_weight,
               c.volume_weight::NUMERIC, c.tags::TEXT, c.marking::TEXT
        FROM public."Flights" f
        JOIN adult_flights af ON af.flight_id = f.flight_id
        JOIN public."Tourist Information" t ON t.tourist_id = af.tourist_id
        LEFT JOIN LATERAL (
            SELECT STRING_AGG(FORMAT('%s (номер %s, %s — %s)', h.hotel_name, b.room_number, b.check_in_date, b.check_out_date), '; ' ORDER BY b.check_in_date)::TEXT AS hotel_name,
                   STRING_AGG(DISTINCT b.room_number, ', ' ORDER BY b.room_number)::TEXT AS room_number
            FROM public."Bookings" b JOIN public."Hotels" h ON h.hotel_id = b.hotel_id
            JOIN public."Tourist Visits" v ON v.visit_id = b.visit_id
            WHERE b.tourist_id = t.tourist_id AND v.flight_id = f.flight_id
        ) h ON TRUE
        LEFT JOIN public."Tourist Cargo" c ON c.tourist_id = t.tourist_id AND c.flight_id = f.flight_id
        WHERE f.flight_number = BTRIM(p_flight_number)
        UNION ALL
        SELECT f.flight_number::TEXT, f.flight_date,
               CONCAT_WS(' ', child.last_name, child.first_name, child.patronymic)::TEXT,
               'Ребёнок'::TEXT, NULL::BOOLEAN, h.hotel_name, h.room_number,
               NULL::TEXT, NULL::INTEGER, NULL::NUMERIC, NULL::NUMERIC, NULL::TEXT, NULL::TEXT
        FROM public."Flights" f
        JOIN (SELECT DISTINCT visit.flight_id, cv.child_id
              FROM public."Child Visits" cv JOIN public."Tourist Visits" visit ON visit.visit_id = cv.visit_id) passengers
          ON passengers.flight_id = f.flight_id
        JOIN public."Tourist Children" child ON child.child_id = passengers.child_id
        LEFT JOIN LATERAL (
            SELECT STRING_AGG(FORMAT('%s (номер %s, %s — %s)', h.hotel_name, b.room_number, b.check_in_date, b.check_out_date), '; ' ORDER BY b.check_in_date)::TEXT AS hotel_name,
                   STRING_AGG(DISTINCT b.room_number, ', ' ORDER BY b.room_number)::TEXT AS room_number
            FROM public."Child Bookings" cb JOIN public."Bookings" b ON b.booking_id = cb.booking_id
            JOIN public."Hotels" h ON h.hotel_id = b.hotel_id
            JOIN public."Tourist Visits" visit ON visit.visit_id = cb.visit_id
            WHERE cb.child_id = child.child_id AND visit.flight_id = f.flight_id
        ) h ON TRUE
        WHERE f.flight_number = BTRIM(p_flight_number)
    )
    SELECT * FROM rows ORDER BY flight_date, flight_number, full_name;
$$;
