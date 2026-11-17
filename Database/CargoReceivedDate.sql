-- Existing cargo dates remain unknown; no existing rows are changed.
BEGIN;

ALTER TABLE public."Tourist Cargo"
    ADD COLUMN IF NOT EXISTS received_date DATE,
    ADD COLUMN IF NOT EXISTS shipped_date DATE;

CREATE OR REPLACE FUNCTION public.coursework_cargo_turnover(p_start_date DATE, p_end_date DATE)
RETURNS TABLE (total_places BIGINT, actual_weight NUMERIC, volume_weight NUMERIC,
               flights_with_cargo BIGINT, cargo_only_flights BIGINT, passenger_cargo_flights BIGINT)
LANGUAGE sql STABLE AS $$
    WITH received AS (
        SELECT c.*, translate(f.flight_type::TEXT,
            'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ',
            'абвгдеёжзийклмнопрстуфхцчшщъыьэюя') AS flight_type
        FROM public."Tourist Cargo" c JOIN public."Flights" f ON f.flight_id = c.flight_id
        WHERE c.received_date BETWEEN p_start_date AND p_end_date
    )
    SELECT COALESCE(SUM(c.places_count), 0)::BIGINT,
           COALESCE(SUM(c.actual_weight), 0)::NUMERIC,
           COALESCE(SUM(c.volume_weight), 0)::NUMERIC,
           COUNT(DISTINCT c.flight_id) FILTER (WHERE c.status = 'Отправлен' AND c.shipped_date IS NOT NULL)::BIGINT,
           COUNT(DISTINCT c.flight_id) FILTER (WHERE c.status = 'Отправлен' AND c.shipped_date IS NOT NULL
               AND c.flight_type LIKE '%груз%' AND c.flight_type NOT LIKE '%пассаж%')::BIGINT,
           COUNT(DISTINCT c.flight_id) FILTER (WHERE c.status = 'Отправлен' AND c.shipped_date IS NOT NULL
               AND c.flight_type LIKE '%груз%' AND c.flight_type LIKE '%пассаж%')::BIGINT
    FROM received c;
$$;

COMMIT;
