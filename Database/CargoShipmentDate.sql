-- Historical shipments are not backfilled. Apply after CargoAndFlightReports.sql.
BEGIN;

ALTER TABLE public."Tourist Cargo" ADD COLUMN IF NOT EXISTS shipped_date DATE;

ALTER TABLE public."Tourist Cargo" DROP CONSTRAINT IF EXISTS ck_cargo_shipment_date;
ALTER TABLE public."Tourist Cargo" DROP CONSTRAINT IF EXISTS ck_cargo_shipment_after_receipt;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."Tourist Cargo"'::regclass
                   AND conname = 'ck_cargo_shipment_status') THEN
        ALTER TABLE public."Tourist Cargo"
            ADD CONSTRAINT ck_cargo_shipment_status CHECK (
                shipped_date IS NULL OR status = 'Отправлен'
            );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."Tourist Cargo"'::regclass
                   AND conname = 'ck_cargo_shipment_receipt_required') THEN
        ALTER TABLE public."Tourist Cargo"
            ADD CONSTRAINT ck_cargo_shipment_receipt_required CHECK (
                shipped_date IS NULL OR (received_date IS NOT NULL AND shipped_date >= received_date)
            ) NOT VALID;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.coursework_validate_cargo_shipment()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'Отправлен' AND NEW.shipped_date IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            RAISE EXCEPTION 'Укажите фактическую дату отправки груза.' USING ERRCODE = '23514';
        ELSIF OLD.status IS DISTINCT FROM 'Отправлен' OR OLD.shipped_date IS NOT NULL THEN
            RAISE EXCEPTION 'Укажите фактическую дату отправки груза.' USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_cargo_shipment ON public."Tourist Cargo";
CREATE TRIGGER trg_validate_cargo_shipment
    BEFORE INSERT OR UPDATE ON public."Tourist Cargo"
    FOR EACH ROW EXECUTE FUNCTION public.coursework_validate_cargo_shipment();

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

CREATE OR REPLACE PROCEDURE public.coursework_cargo_turnover_details(
    IN p_start_date DATE, IN p_end_date DATE, INOUT p_result JSONB
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_start_date > p_end_date THEN
        RAISE EXCEPTION 'Invalid date range' USING ERRCODE = '22023';
    END IF;
    SELECT TO_JSONB(report) || JSONB_BUILD_OBJECT(
        'unconfirmed_cargo_count', (
            SELECT COUNT(*) FROM public."Tourist Cargo" c
            WHERE c.received_date BETWEEN p_start_date AND p_end_date
              AND (c.status <> 'Отправлен' OR c.shipped_date IS NULL)
        ),
        'sent_without_date_count', (
            SELECT COUNT(*) FROM public."Tourist Cargo" c
            WHERE c.received_date BETWEEN p_start_date AND p_end_date
              AND c.status = 'Отправлен' AND c.shipped_date IS NULL
        )
    )
    INTO p_result FROM public.coursework_cargo_turnover(p_start_date, p_end_date) report;
END;
$$;

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

COMMIT;
