-- Additive schema and report functions for the coursework requirements.
-- Existing rows are preserved; the script can be re-applied safely.

ALTER TABLE public."Finances"
    ADD COLUMN IF NOT EXISTS flight_id INTEGER,
    ADD COLUMN IF NOT EXISTS tourist_id INTEGER;

ALTER TABLE public."Flights"
    ADD COLUMN IF NOT EXISTS seat_capacity INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public."Excursion Bookings"
    ADD COLUMN IF NOT EXISTS child_id INTEGER;

ALTER TABLE public."Tourist Cargo"
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'Принят на склад';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'ck_tourist_cargo_status'
          AND conrelid = 'public."Tourist Cargo"'::regclass
    ) THEN
        ALTER TABLE public."Tourist Cargo"
            ADD CONSTRAINT ck_tourist_cargo_status
            CHECK (status IN ('Принят на склад', 'Упакован', 'Готов к отправке', 'Отправлен'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_finances_flight'
          AND conrelid = 'public."Finances"'::regclass
    ) THEN
        ALTER TABLE public."Finances"
            ADD CONSTRAINT fk_finances_flight
            FOREIGN KEY (flight_id) REFERENCES public."Flights"(flight_id)
            ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_finances_tourist'
          AND conrelid = 'public."Finances"'::regclass
    ) THEN
        ALTER TABLE public."Finances"
            ADD CONSTRAINT fk_finances_tourist
            FOREIGN KEY (tourist_id) REFERENCES public."Tourist Information"(tourist_id)
            ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_excursion_bookings_child'
          AND conrelid = 'public."Excursion Bookings"'::regclass
    ) THEN
        ALTER TABLE public."Excursion Bookings"
            ADD CONSTRAINT fk_excursion_bookings_child
            FOREIGN KEY (child_id) REFERENCES public."Tourist Children"(child_id)
            ON DELETE CASCADE;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.coursework_validate_tourist_age()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.tourist_date_of_birth > CURRENT_DATE - INTERVAL '18 years' THEN
        RAISE EXCEPTION 'Путешественники младше 18 лет должны оформляться как дети при взрослом туристе.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS coursework_tourist_age_guard ON public."Tourist Information";
CREATE TRIGGER coursework_tourist_age_guard
    BEFORE INSERT OR UPDATE OF tourist_date_of_birth, has_visa
    ON public."Tourist Information"
    FOR EACH ROW
    EXECUTE FUNCTION public.coursework_validate_tourist_age();

CREATE OR REPLACE FUNCTION public.coursework_validate_child_guardian()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.date_of_birth IS NULL
       OR NEW.date_of_birth <= CURRENT_DATE - INTERVAL '18 years'
       OR NEW.date_of_birth > CURRENT_DATE THEN
        RAISE EXCEPTION 'В таблице детей должны храниться лица младше 18 лет.'
            USING ERRCODE = '23514';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public."Tourist Information" t
        WHERE t.tourist_id = NEW.tourist_id
          AND t.tourist_date_of_birth <= CURRENT_DATE - INTERVAL '18 years'
    ) THEN
        RAISE EXCEPTION 'У ребенка должен быть совершеннолетний турист-родитель/сопровождающий.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS coursework_child_guardian_guard ON public."Tourist Children";
CREATE TRIGGER coursework_child_guardian_guard
    BEFORE INSERT OR UPDATE OF tourist_id, date_of_birth
    ON public."Tourist Children"
    FOR EACH ROW
    EXECUTE FUNCTION public.coursework_validate_child_guardian();

CREATE OR REPLACE FUNCTION public.coursework_prevent_orphaned_children()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public."Tourist Children" child
        WHERE child.tourist_id = OLD.tourist_id
    ) THEN
        RAISE EXCEPTION 'Сначала необходимо удалить или переназначить детей, затем удалять сопровождающего.'
            USING ERRCODE = '23514';
    END IF;

    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS coursework_prevent_orphaned_children_guard ON public."Tourist Information";
CREATE TRIGGER coursework_prevent_orphaned_children_guard
    BEFORE DELETE
    ON public."Tourist Information"
    FOR EACH ROW
    EXECUTE FUNCTION public.coursework_prevent_orphaned_children();

CREATE OR REPLACE FUNCTION public.coursework_require_adult_tourist()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM public."Tourist Information" t
        WHERE t.tourist_id = NEW.tourist_id
          AND t.tourist_date_of_birth <= CURRENT_DATE - INTERVAL '18 years'
    ) THEN
        RAISE EXCEPTION 'Отель и экскурсию можно бронировать только на совершеннолетнего туриста-сопровождающего.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS coursework_booking_adult_guard ON public."Bookings";
CREATE TRIGGER coursework_booking_adult_guard
    BEFORE INSERT OR UPDATE OF tourist_id
    ON public."Bookings"
    FOR EACH ROW
    EXECUTE FUNCTION public.coursework_require_adult_tourist();

DROP TRIGGER IF EXISTS coursework_excursion_adult_guard ON public."Excursion Bookings";
CREATE TRIGGER coursework_excursion_adult_guard
    BEFORE INSERT OR UPDATE OF tourist_id, child_id
    ON public."Excursion Bookings"
    FOR EACH ROW
    EXECUTE FUNCTION public.coursework_require_adult_tourist();

CREATE OR REPLACE FUNCTION public.coursework_validate_excursion_child()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_guardian_id INTEGER;
BEGIN
    IF NEW.child_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT child.tourist_id
    INTO v_guardian_id
    FROM public."Tourist Children" child
    WHERE child.child_id = NEW.child_id;

    IF v_guardian_id IS DISTINCT FROM NEW.tourist_id THEN
        RAISE EXCEPTION 'Ребенок может быть записан только вместе со своим сопровождающим.'
            USING ERRCODE = '23514';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public."Excursion Bookings" guardian_booking
        WHERE guardian_booking.tourist_id = NEW.tourist_id
          AND guardian_booking.excursion_id = NEW.excursion_id
          AND guardian_booking.child_id IS NULL
          AND guardian_booking.booking_id <> COALESCE(NEW.booking_id, -1)
    ) THEN
        RAISE EXCEPTION 'Сначала необходимо записать на эту экскурсию взрослого сопровождающего.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS coursework_excursion_child_guard ON public."Excursion Bookings";
CREATE TRIGGER coursework_excursion_child_guard
    BEFORE INSERT OR UPDATE OF tourist_id, excursion_id, child_id
    ON public."Excursion Bookings"
    FOR EACH ROW
    EXECUTE FUNCTION public.coursework_validate_excursion_child();

CREATE UNIQUE INDEX IF NOT EXISTS ux_excursion_booking_child
    ON public."Excursion Bookings"(excursion_id, child_id)
    WHERE child_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.coursework_prevent_orphaned_excursion_child()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.child_id IS NULL AND EXISTS (
        SELECT 1
        FROM public."Excursion Bookings" child_booking
        WHERE child_booking.tourist_id = OLD.tourist_id
          AND child_booking.excursion_id = OLD.excursion_id
          AND child_booking.child_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Сначала снимите детей с экскурсии, затем отменяйте запись сопровождающего.'
            USING ERRCODE = '23514';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS coursework_excursion_guardian_booking_guard ON public."Excursion Bookings";
CREATE TRIGGER coursework_excursion_guardian_booking_guard
    BEFORE UPDATE OF tourist_id, excursion_id, child_id OR DELETE
    ON public."Excursion Bookings"
    FOR EACH ROW
    EXECUTE FUNCTION public.coursework_prevent_orphaned_excursion_child();

UPDATE public."Finances" f
SET flight_id = flights.flight_id
FROM public."Flights" flights
WHERE f.flight_id IS NULL
  AND f.description ILIKE '%DEMO%'
  AND flights.flight_number LIKE 'DEMO-TF-%'
  AND EXISTS (
      SELECT 1
      FROM public."Tourist Visits" visits
      WHERE visits.flight_id = flights.flight_id
        AND visits.arrival_date <= f.transaction_date
        AND visits.departure_date >= f.transaction_date
  );

CREATE TABLE IF NOT EXISTS public."Tour Packages" (
    package_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    package_code VARCHAR(60) NOT NULL UNIQUE,
    package_name VARCHAR(150) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    monthly_capacity INTEGER NOT NULL CHECK (monthly_capacity >= 0),
    available_from DATE,
    available_until DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE public."Tour Packages"
    ADD COLUMN IF NOT EXISTS available_from DATE,
    ADD COLUMN IF NOT EXISTS available_until DATE;

CREATE TABLE IF NOT EXISTS public."Tour Package Sales" (
    sale_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    package_id INTEGER NOT NULL REFERENCES public."Tour Packages"(package_id),
    tourist_id INTEGER NOT NULL REFERENCES public."Tourist Information"(tourist_id),
    flight_id INTEGER NOT NULL REFERENCES public."Flights"(flight_id),
    sold_date DATE NOT NULL,
    UNIQUE (package_id, tourist_id)
);

CREATE INDEX IF NOT EXISTS ix_tour_package_sales_sold_date
    ON public."Tour Package Sales"(sold_date);
CREATE INDEX IF NOT EXISTS ix_finances_flight_date
    ON public."Finances"(flight_id, transaction_date);

INSERT INTO public."Tour Packages"
    (package_code, package_name, destination, category, price, monthly_capacity, available_from, available_until)
VALUES
    ('DEMO-OCT-REST', 'Осенний отдых у моря', 'Анталья', 'Отдых', 700.00, 2, DATE '2026-10-01', DATE '2026-10-31'),
    ('DEMO-OCT-SHOP', 'Осенний шоп-тур', 'Стамбул', 'Шоп-тур', 480.00, 3, DATE '2026-10-01', DATE '2026-10-31'),
    ('DEMO-OCT-UNSOLD', 'Осенний тур без продаж', 'Измир', 'Отдых', 620.00, 4, DATE '2026-10-01', DATE '2026-10-31'),
    ('DEMO-NOV-REST', 'Ноябрьский отдых у моря', 'Анталья', 'Отдых', 760.00, 2, DATE '2026-11-01', DATE '2026-11-30'),
    ('DEMO-NOV-SHOP', 'Ноябрьский шоп-тур', 'Стамбул', 'Шоп-тур', 520.00, 3, DATE '2026-11-01', DATE '2026-11-30'),
    ('DEMO-NOV-UNSOLD', 'Ноябрьский тур без продаж', 'Измир', 'Отдых', 680.00, 4, DATE '2026-11-01', DATE '2026-11-30'),
    ('DEMO-UNSOLD', 'Зимний тур без продаж', 'Каппадокия', 'Отдых', 890.00, 8, DATE '2026-12-01', DATE '2027-01-31')
ON CONFLICT (package_code) DO NOTHING;

UPDATE public."Tour Packages"
SET available_from = CASE
        WHEN package_code LIKE 'DEMO-OCT-%' THEN DATE '2026-10-01'
        WHEN package_code LIKE 'DEMO-NOV-%' THEN DATE '2026-11-01'
        WHEN package_code = 'DEMO-UNSOLD' THEN DATE '2026-12-01'
        ELSE available_from
    END,
    available_until = CASE
        WHEN package_code LIKE 'DEMO-OCT-%' THEN DATE '2026-10-31'
        WHEN package_code LIKE 'DEMO-NOV-%' THEN DATE '2026-11-30'
        WHEN package_code = 'DEMO-UNSOLD' THEN DATE '2027-01-31'
        ELSE available_until
    END
WHERE package_code LIKE 'DEMO-%';

UPDATE public."Flights"
SET seat_capacity = CASE flight_number
    WHEN 'DEMO-TF-2026' THEN 180
    WHEN 'DEMO-TF-OCT-2026' THEN 220
    WHEN 'DEMO-TF-NOV-2026' THEN 189
    ELSE seat_capacity
END
WHERE flight_number IN ('DEMO-TF-2026', 'DEMO-TF-OCT-2026', 'DEMO-TF-NOV-2026');

INSERT INTO public."Tour Package Sales" (package_id, tourist_id, flight_id, sold_date)
SELECT p.package_id, t.tourist_id, f.flight_id, f.flight_date
FROM (VALUES
    ('DEMO-OCT-REST', 'Анна', 'Соколова', 'DEMO-TF-OCT-2026'),
    ('DEMO-OCT-SHOP', 'Сергей', 'Волков', 'DEMO-TF-OCT-2026'),
    ('DEMO-OCT-SHOP', 'Елена', 'Морозова', 'DEMO-TF-OCT-2026'),
    ('DEMO-NOV-REST', 'Михаил', 'Орлов', 'DEMO-TF-NOV-2026'),
    ('DEMO-NOV-SHOP', 'Ольга', 'Кузнецова', 'DEMO-TF-NOV-2026'),
    ('DEMO-NOV-SHOP', 'Павел', 'Федоров', 'DEMO-TF-NOV-2026')
) AS demo(package_code, tourist_name, tourist_surname, flight_number)
JOIN public."Tour Packages" p ON p.package_code = demo.package_code
JOIN public."Tourist Information" t
  ON t.tourist_name = demo.tourist_name AND t.tourist_surname = demo.tourist_surname
JOIN public."Flights" f ON f.flight_number = demo.flight_number
ON CONFLICT (package_id, tourist_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.coursework_hotel_check_in(
    p_hotel_name TEXT DEFAULT NULL,
    p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
    hotel_name TEXT,
    tourist_full_name TEXT,
    category TEXT,
    check_in_date DATE,
    check_out_date DATE,
    room_number TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT h.hotel_name::TEXT,
           CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)::TEXT,
           t.category::TEXT,
           b.check_in_date,
           b.check_out_date,
           b.room_number::TEXT
    FROM public."Bookings" b
    JOIN public."Hotels" h ON h.hotel_id = b.hotel_id
    JOIN public."Tourist Information" t ON t.tourist_id = b.tourist_id
    WHERE (NULLIF(BTRIM(p_hotel_name), '') IS NULL OR h.hotel_name ILIKE BTRIM(p_hotel_name))
      AND (NULLIF(BTRIM(p_category), '') IS NULL OR t.category = BTRIM(p_category))
    ORDER BY h.hotel_name, b.check_in_date, t.tourist_surname;
$$;

CREATE OR REPLACE FUNCTION public.coursework_hotel_check_in_with_children(
    p_hotel_name TEXT DEFAULT NULL,
    p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
    hotel_name TEXT,
    tourist_full_name TEXT,
    category TEXT,
    check_in_date DATE,
    check_out_date DATE,
    room_number TEXT,
    accompanying_children TEXT,
    children_count BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT h.hotel_name::TEXT,
           CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)::TEXT,
           t.category::TEXT,
           b.check_in_date,
           b.check_out_date,
           b.room_number::TEXT,
           COALESCE(children.names, 'Нет')::TEXT,
           COALESCE(children.child_count, 0)::BIGINT
    FROM public."Bookings" b
    JOIN public."Hotels" h ON h.hotel_id = b.hotel_id
    JOIN public."Tourist Information" t ON t.tourist_id = b.tourist_id
    LEFT JOIN LATERAL (
        SELECT STRING_AGG(
                   CONCAT_WS(' ', child.last_name, child.first_name, child.patronymic),
                   ', ' ORDER BY child.last_name, child.first_name
               ) AS names,
               COUNT(*)::BIGINT AS child_count
        FROM public."Tourist Children" child
        WHERE child.tourist_id = t.tourist_id
    ) children ON TRUE
    WHERE (NULLIF(BTRIM(p_hotel_name), '') IS NULL OR h.hotel_name ILIKE BTRIM(p_hotel_name))
      AND (NULLIF(BTRIM(p_category), '') IS NULL OR t.category = BTRIM(p_category))
    ORDER BY h.hotel_name, b.check_in_date, t.tourist_surname;
$$;

CREATE OR REPLACE FUNCTION public.coursework_hotel_occupancy(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
    hotel_name TEXT,
    country TEXT,
    occupied_rooms BIGINT,
    resident_tourists BIGINT,
    resident_children BIGINT,
    total_residents BIGINT
)
LANGUAGE sql
STABLE
AS $$
    WITH occupied AS (
        SELECT h.hotel_id,
               h.hotel_name::TEXT AS hotel_name,
               h.country::TEXT AS country,
               b.room_number,
               t.tourist_id
        FROM public."Bookings" b
        JOIN public."Hotels" h ON h.hotel_id = b.hotel_id
        JOIN public."Tourist Information" t ON t.tourist_id = b.tourist_id
        WHERE (p_start_date IS NULL OR b.check_out_date >= p_start_date)
          AND (p_end_date IS NULL OR b.check_in_date <= p_end_date)
          AND (NULLIF(BTRIM(p_category), '') IS NULL OR t.category = BTRIM(p_category))
    )
    SELECT o.hotel_name,
           o.country,
           COUNT(DISTINCT (o.hotel_id, o.room_number))::BIGINT,
           COUNT(DISTINCT o.tourist_id)::BIGINT,
           COUNT(DISTINCT child.child_id)::BIGINT,
           (COUNT(DISTINCT o.tourist_id) + COUNT(DISTINCT child.child_id))::BIGINT
    FROM occupied o
    LEFT JOIN public."Tourist Children" child ON child.tourist_id = o.tourist_id
    GROUP BY o.hotel_id, o.hotel_name, o.country
    ORDER BY COUNT(DISTINCT (o.hotel_id, o.room_number)) DESC, o.hotel_name;
$$;

CREATE OR REPLACE FUNCTION public.coursework_tourist_profile(p_tourist_id INTEGER)
RETURNS TABLE (
    tourist_id INTEGER,
    full_name TEXT,
    category TEXT,
    has_visa BOOLEAN,
    passport_number TEXT,
    total_visits BIGINT,
    visit_history TEXT[],
    hotel_history TEXT[],
    excursion_history TEXT[],
    cargo_history TEXT[]
)
LANGUAGE sql
STABLE
AS $$
    SELECT t.tourist_id,
           CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)::TEXT,
           t.category::TEXT,
           t.has_visa,
           passport.passport_number::TEXT,
           (SELECT COUNT(*)::BIGINT FROM public."Tourist Visits" v WHERE v.tourist_id = t.tourist_id),
           COALESCE((
               SELECT ARRAY_AGG(FORMAT('%s — %s, рейс %s', v.arrival_date, v.departure_date, f.flight_number)
                                ORDER BY v.arrival_date)
               FROM public."Tourist Visits" v
               LEFT JOIN public."Flights" f ON f.flight_id = v.flight_id
               WHERE v.tourist_id = t.tourist_id
           ), ARRAY[]::TEXT[]),
           COALESCE((
               SELECT ARRAY_AGG(FORMAT('%s, номер %s, %s — %s', h.hotel_name, b.room_number,
                                        b.check_in_date, b.check_out_date)
                                ORDER BY b.check_in_date)
               FROM public."Bookings" b
               JOIN public."Hotels" h ON h.hotel_id = b.hotel_id
               WHERE b.tourist_id = t.tourist_id
           ), ARRAY[]::TEXT[]),
           COALESCE((
               SELECT ARRAY_AGG(FORMAT('%s (%s), агентство: %s, оценка %s',
                                        excursion.excursion_name, excursion.schedule_date,
                                        excursion.agency_name, excursion.quality_rating)
                                ORDER BY excursion.schedule_date)
               FROM (
                   SELECT DISTINCT e.excursion_name, e.schedule_date::DATE AS schedule_date,
                                   a.agency_name, a.quality_rating
                   FROM public."Excursion Bookings" eb
                   JOIN public."Excursions" e ON e.excursion_id = eb.excursion_id
                   JOIN public."Agencies" a ON a.agency_id = e.agency_id
                   WHERE eb.tourist_id = t.tourist_id
               ) excursion
           ), ARRAY[]::TEXT[]),
           COALESCE((
               SELECT ARRAY_AGG(FORMAT('%s: %s мест, вес %s кг, объемный вес %s кг, бирки %s, маркировка %s',
                                        c.cargo_type, c.places_count, c.actual_weight, c.volume_weight,
                                        c.tags, c.marking)
                                ORDER BY c.cargo_id)
               FROM public."Tourist Cargo" c
               WHERE c.tourist_id = t.tourist_id
           ), ARRAY[]::TEXT[])
    FROM public."Tourist Information" t
    LEFT JOIN LATERAL (
        SELECT p.passport_number
        FROM public."Tourist's Passport Details" p
        WHERE p.tourist_id = t.tourist_id
        ORDER BY p.expiry_date DESC
        LIMIT 1
    ) passport ON TRUE
    WHERE t.tourist_id = p_tourist_id;
$$;

CREATE OR REPLACE FUNCTION public.coursework_excursion_summary()
RETURNS TABLE (
    excursion_name TEXT,
    agency_name TEXT,
    agency_quality NUMERIC,
    schedule_date DATE,
    price NUMERIC,
    total_tourists BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT e.excursion_name::TEXT,
           a.agency_name::TEXT,
           a.quality_rating::NUMERIC,
           e.schedule_date::DATE,
           e.price::NUMERIC,
           COUNT(DISTINCT eb.tourist_id)::BIGINT
    FROM public."Excursions" e
    JOIN public."Agencies" a ON a.agency_id = e.agency_id
    LEFT JOIN public."Excursion Bookings" eb ON eb.excursion_id = e.excursion_id
    GROUP BY e.excursion_id, e.excursion_name, a.agency_name, a.quality_rating,
             e.schedule_date, e.price
    ORDER BY COUNT(DISTINCT eb.tourist_id) DESC, a.quality_rating DESC, e.schedule_date;
$$;

CREATE OR REPLACE FUNCTION public.coursework_excursion_summary_with_children()
RETURNS TABLE (
    excursion_name TEXT,
    agency_name TEXT,
    agency_quality NUMERIC,
    schedule_date DATE,
    price NUMERIC,
    adult_tourists BIGINT,
    children BIGINT,
    total_tourists BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT e.excursion_name::TEXT,
           a.agency_name::TEXT,
           a.quality_rating::NUMERIC,
           e.schedule_date::DATE,
           e.price::NUMERIC,
           COUNT(DISTINCT eb.tourist_id) FILTER (WHERE eb.child_id IS NULL)::BIGINT,
           COUNT(DISTINCT eb.child_id)::BIGINT,
           (
               COUNT(DISTINCT eb.tourist_id) FILTER (WHERE eb.child_id IS NULL)
               + COUNT(DISTINCT eb.child_id)
           )::BIGINT
    FROM public."Excursions" e
    JOIN public."Agencies" a ON a.agency_id = e.agency_id
    LEFT JOIN public."Excursion Bookings" eb ON eb.excursion_id = e.excursion_id
    GROUP BY e.excursion_id, e.excursion_name, a.agency_name, a.quality_rating,
             e.schedule_date, e.price
    ORDER BY (
        COUNT(DISTINCT eb.tourist_id) FILTER (WHERE eb.child_id IS NULL)
        + COUNT(DISTINCT eb.child_id)
    ) DESC, a.quality_rating DESC, e.schedule_date;
$$;

CREATE OR REPLACE FUNCTION public.coursework_excursion_tourists_count(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_tourists BIGINT,
    adult_tourists BIGINT,
    children BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT (
               COUNT(DISTINCT booking.tourist_id) FILTER (WHERE booking.child_id IS NULL)
               + COUNT(DISTINCT booking.child_id)
           )::BIGINT,
           COUNT(DISTINCT booking.tourist_id) FILTER (WHERE booking.child_id IS NULL)::BIGINT,
           COUNT(DISTINCT booking.child_id)::BIGINT
    FROM public."Excursion Bookings" booking
    JOIN public."Excursions" excursion ON excursion.excursion_id = booking.excursion_id
    WHERE excursion.schedule_date::DATE BETWEEN p_start_date AND p_end_date;
$$;

CREATE OR REPLACE FUNCTION public.coursework_excursion_agency_quality()
RETURNS TABLE (
    agency_name TEXT,
    quality_rating NUMERIC,
    quality_rank BIGINT,
    excursion_count BIGINT,
    booked_participants BIGINT
)
LANGUAGE sql
STABLE
AS $$
    WITH agency_activity AS (
        SELECT agency.agency_id,
               agency.agency_name::TEXT AS agency_name,
               agency.quality_rating::NUMERIC AS quality_rating,
               COUNT(DISTINCT excursion.excursion_id)::BIGINT AS excursion_count,
               (
                   COUNT(booking.booking_id) FILTER (WHERE booking.child_id IS NULL)
                   + COUNT(booking.child_id)
               )::BIGINT AS booked_participants
        FROM public."Agencies" agency
        LEFT JOIN public."Excursions" excursion ON excursion.agency_id = agency.agency_id
        LEFT JOIN public."Excursion Bookings" booking ON booking.excursion_id = excursion.excursion_id
        GROUP BY agency.agency_id, agency.agency_name, agency.quality_rating
    )
    SELECT activity.agency_name,
           activity.quality_rating,
           RANK() OVER (ORDER BY activity.quality_rating DESC)::BIGINT,
           activity.excursion_count,
           activity.booked_participants
    FROM agency_activity activity
    ORDER BY activity.quality_rating DESC, activity.booked_participants DESC, activity.agency_name;
$$;

DROP FUNCTION IF EXISTS public.coursework_flight_load(DATE, DATE, TEXT);

CREATE OR REPLACE FUNCTION public.coursework_flight_load(
    p_start_date DATE,
    p_end_date DATE,
    p_flight_number TEXT DEFAULT NULL
)
RETURNS TABLE (
    flight_id INTEGER,
    flight_number TEXT,
    flight_date DATE,
    flight_type TEXT,
    seat_capacity INTEGER,
    passenger_count BIGINT,
    available_seats BIGINT,
    cargo_places BIGINT,
    actual_weight NUMERIC,
    volume_weight NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    WITH passenger_load AS (
        SELECT t.flight_id,
               (COUNT(DISTINCT t.tourist_id) + COUNT(DISTINCT child.child_id))::BIGINT AS passenger_count
        FROM public."Tourist Information" t
        LEFT JOIN public."Tourist Children" child ON child.tourist_id = t.tourist_id
        GROUP BY t.flight_id
    ),
    cargo_load AS (
        SELECT c.flight_id,
               COALESCE(SUM(c.places_count), 0)::BIGINT AS cargo_places,
               COALESCE(SUM(c.actual_weight), 0)::NUMERIC AS actual_weight,
               COALESCE(SUM(c.volume_weight), 0)::NUMERIC AS volume_weight
        FROM public."Tourist Cargo" c
        GROUP BY c.flight_id
    )
    SELECT f.flight_id,
           f.flight_number::TEXT,
           f.flight_date,
           f.flight_type::TEXT,
           f.seat_capacity,
           COALESCE(p.passenger_count, 0)::BIGINT,
           GREATEST(f.seat_capacity - COALESCE(p.passenger_count, 0), 0)::BIGINT,
           COALESCE(c.cargo_places, 0)::BIGINT,
           COALESCE(c.actual_weight, 0)::NUMERIC,
           COALESCE(c.volume_weight, 0)::NUMERIC
    FROM public."Flights" f
    LEFT JOIN passenger_load p ON p.flight_id = f.flight_id
    LEFT JOIN cargo_load c ON c.flight_id = f.flight_id
    WHERE f.flight_date BETWEEN p_start_date AND p_end_date
      AND (NULLIF(BTRIM(p_flight_number), '') IS NULL OR f.flight_number = BTRIM(p_flight_number))
    ORDER BY f.flight_date, f.flight_number;
$$;

CREATE OR REPLACE FUNCTION public.coursework_cargo_turnover(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_places BIGINT,
    actual_weight NUMERIC,
    volume_weight NUMERIC,
    flights_with_cargo BIGINT,
    cargo_only_flights BIGINT,
    passenger_cargo_flights BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(SUM(c.places_count), 0)::BIGINT,
           COALESCE(SUM(c.actual_weight), 0)::NUMERIC,
           COALESCE(SUM(c.volume_weight), 0)::NUMERIC,
           COUNT(DISTINCT f.flight_id)::BIGINT,
           COUNT(DISTINCT f.flight_id) FILTER (
               WHERE f.flight_type ILIKE '%груз%'
                 AND f.flight_type NOT ILIKE '%пассаж%'
           )::BIGINT,
           COUNT(DISTINCT f.flight_id) FILTER (
               WHERE f.flight_type ILIKE '%пассаж%' AND c.cargo_id IS NOT NULL
           )::BIGINT
    FROM public."Tourist Cargo" c
    JOIN public."Flights" f ON f.flight_id = c.flight_id
    WHERE f.flight_date BETWEEN p_start_date AND p_end_date;
$$;

CREATE OR REPLACE FUNCTION public.coursework_financial_items(
    p_start_date DATE,
    p_end_date DATE,
    p_flight_id INTEGER DEFAULT NULL,
    p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
    transaction_type TEXT,
    category TEXT,
    transaction_count BIGINT,
    amount NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    WITH scoped AS (
        SELECT f.transaction_id, f.transaction_type::TEXT, f.category::TEXT, f.amount,
               f.flight_id, f.tourist_id, t.category::TEXT AS tourist_category
        FROM public."Finances" f
        LEFT JOIN public."Tourist Information" t ON t.tourist_id = f.tourist_id
        WHERE f.transaction_date BETWEEN p_start_date AND p_end_date
          AND (p_flight_id IS NULL OR f.flight_id = p_flight_id)
    ),
    allocated AS (
        SELECT s.*,
               CASE
                   WHEN NULLIF(BTRIM(p_category), '') IS NULL THEN s.amount
                   WHEN s.tourist_id IS NOT NULL THEN
                       CASE WHEN s.tourist_category = BTRIM(p_category) THEN s.amount ELSE 0 END
                   WHEN s.flight_id IS NOT NULL THEN s.amount * COALESCE((
                       SELECT COUNT(*)::NUMERIC
                       FROM public."Tourist Information" t
                       WHERE t.flight_id = s.flight_id AND t.category = BTRIM(p_category)
                   ), 0) / NULLIF((
                       SELECT COUNT(*)::NUMERIC
                       FROM public."Tourist Information" t
                       WHERE t.flight_id = s.flight_id
                   ), 0)
                   ELSE 0
               END AS allocated_amount
        FROM scoped s
    )
    SELECT a.transaction_type,
           a.category,
           COUNT(*)::BIGINT,
           ROUND(COALESCE(SUM(a.allocated_amount), 0), 2)::NUMERIC
    FROM allocated a
    GROUP BY a.transaction_type, a.category
    ORDER BY a.transaction_type, a.category;
$$;

CREATE OR REPLACE FUNCTION public.coursework_financial_summary(
    p_start_date DATE,
    p_end_date DATE,
    p_flight_id INTEGER DEFAULT NULL,
    p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
    total_income NUMERIC,
    total_expense NUMERIC,
    net_profit NUMERIC,
    profitability_percent NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(SUM(i.amount) FILTER (WHERE i.transaction_type = 'Доход'), 0)::NUMERIC,
           COALESCE(SUM(i.amount) FILTER (WHERE i.transaction_type = 'Расход'), 0)::NUMERIC,
           ROUND((
               COALESCE(SUM(i.amount) FILTER (WHERE i.transaction_type = 'Доход'), 0)
               - COALESCE(SUM(i.amount) FILTER (WHERE i.transaction_type = 'Расход'), 0)
           ), 2)::NUMERIC,
           CASE
               WHEN COALESCE(SUM(i.amount) FILTER (WHERE i.transaction_type = 'Расход'), 0) = 0 THEN NULL
               ELSE ROUND((
                   (COALESCE(SUM(i.amount) FILTER (WHERE i.transaction_type = 'Доход'), 0)
                    - COALESCE(SUM(i.amount) FILTER (WHERE i.transaction_type = 'Расход'), 0)) * 100.0
                   / SUM(i.amount) FILTER (WHERE i.transaction_type = 'Расход')
               ), 2)::NUMERIC
           END
    FROM public.coursework_financial_items(p_start_date, p_end_date, p_flight_id, p_category) i;
$$;

DROP FUNCTION IF EXISTS public.coursework_monthly_business_report(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION public.coursework_monthly_business_report(
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    year INTEGER,
    month INTEGER,
    sold_vouchers BIGINT,
    issued_passports BIGINT,
    visas_processed BIGINT,
    child_documents_processed BIGINT,
    total_documents BIGINT,
    voucher_revenue NUMERIC,
    most_demanded_packages TEXT[],
    packages_without_sales TEXT[]
)
LANGUAGE sql
STABLE
AS $$
    WITH bounds AS (
        SELECT MAKE_DATE(p_year, p_month, 1) AS month_start,
               (MAKE_DATE(p_year, p_month, 1) + INTERVAL '1 month')::DATE AS next_month
    ),
    sales AS (
        SELECT s.package_id, p.package_name, p.price
        FROM public."Tour Package Sales" s
        JOIN public."Tour Packages" p ON p.package_id = s.package_id
        CROSS JOIN bounds b
        WHERE s.sold_date >= b.month_start AND s.sold_date < b.next_month
    ),
    package_demand AS (
        SELECT p.package_id, p.package_name, p.monthly_capacity,
               COUNT(s.sale_id)::BIGINT AS sold_count
        FROM public."Tour Packages" p
        LEFT JOIN public."Tour Package Sales" s
          ON s.package_id = p.package_id
         AND s.sold_date >= (SELECT month_start FROM bounds)
         AND s.sold_date < (SELECT next_month FROM bounds)
        WHERE p.is_active
          AND (p.available_from IS NULL OR p.available_from < (SELECT next_month FROM bounds))
          AND (p.available_until IS NULL OR p.available_until >= (SELECT month_start FROM bounds))
        GROUP BY p.package_id, p.package_name, p.monthly_capacity
    ),
    documents AS (
        SELECT COUNT(DISTINCT passport.passport_id)::BIGINT AS passport_count,
               COUNT(DISTINCT t.tourist_id) FILTER (WHERE t.has_visa)::BIGINT AS visa_count,
               COUNT(DISTINCT child.child_id)::BIGINT AS child_document_count
        FROM public."Tourist Visits" v
        JOIN public."Tourist Information" t ON t.tourist_id = v.tourist_id
        LEFT JOIN public."Tourist's Passport Details" passport ON passport.tourist_id = t.tourist_id
        LEFT JOIN public."Tourist Children" child ON child.tourist_id = t.tourist_id
        CROSS JOIN bounds b
        WHERE v.arrival_date >= b.month_start AND v.arrival_date < b.next_month
    ),
    demand AS (
        SELECT COALESCE(ARRAY_AGG(d.package_name || ' — ' || d.sold_count
                                  ORDER BY d.sold_count DESC, d.package_name)
                        FILTER (WHERE d.sold_count > 0 AND d.sold_count = max_demand.value),
                        ARRAY[]::TEXT[]) AS most_demanded
        FROM package_demand d
        CROSS JOIN (SELECT MAX(sold_count) AS value FROM package_demand) max_demand
    ),
    unsold AS (
        SELECT COALESCE(
            ARRAY_AGG(
                d.package_name || ' — мест: ' || d.monthly_capacity
                ORDER BY d.package_name
            ) FILTER (WHERE d.sold_count = 0),
            ARRAY[]::TEXT[]
        ) AS unsold_packages
        FROM package_demand d
    )
    SELECT p_year,
           p_month,
           (SELECT COUNT(*)::BIGINT FROM sales),
           documents.passport_count,
           documents.visa_count,
           documents.child_document_count,
           (documents.passport_count + documents.visa_count + documents.child_document_count)::BIGINT,
           COALESCE((SELECT SUM(price) FROM sales), 0)::NUMERIC,
           demand.most_demanded,
           unsold.unsold_packages
    FROM documents
    CROSS JOIN demand
    CROSS JOIN unsold;
$$;

CREATE OR REPLACE FUNCTION public.coursework_monthly_business_report_complete(
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    year INTEGER,
    month INTEGER,
    sold_vouchers BIGINT,
    issued_passports BIGINT,
    visas_processed BIGINT,
    child_documents_processed BIGINT,
    total_documents BIGINT,
    voucher_revenue NUMERIC,
    total_revenue NUMERIC,
    total_expenses NUMERIC,
    net_profit NUMERIC,
    most_demanded_packages TEXT[],
    packages_without_sales TEXT[]
)
LANGUAGE sql
STABLE
AS $$
    WITH bounds AS (
        SELECT MAKE_DATE(p_year, p_month, 1) AS month_start,
               (MAKE_DATE(p_year, p_month, 1) + INTERVAL '1 month')::DATE AS next_month
    ),
    sales AS (
        SELECT s.package_id, p.package_name, p.price
        FROM public."Tour Package Sales" s
        JOIN public."Tour Packages" p ON p.package_id = s.package_id
        CROSS JOIN bounds b
        WHERE s.sold_date >= b.month_start AND s.sold_date < b.next_month
    ),
    package_demand AS (
        SELECT p.package_id, p.package_name, p.monthly_capacity,
               COUNT(s.sale_id)::BIGINT AS sold_count
        FROM public."Tour Packages" p
        LEFT JOIN public."Tour Package Sales" s
          ON s.package_id = p.package_id
         AND s.sold_date >= (SELECT month_start FROM bounds)
         AND s.sold_date < (SELECT next_month FROM bounds)
        WHERE p.is_active
          AND (p.available_from IS NULL OR p.available_from < (SELECT next_month FROM bounds))
          AND (p.available_until IS NULL OR p.available_until >= (SELECT month_start FROM bounds))
        GROUP BY p.package_id, p.package_name, p.monthly_capacity
    ),
    documents AS (
        SELECT COUNT(DISTINCT passport.passport_id)::BIGINT AS passport_count,
               COUNT(DISTINCT t.tourist_id) FILTER (WHERE t.has_visa)::BIGINT AS visa_count,
               COUNT(DISTINCT child.child_id)::BIGINT AS child_document_count
        FROM public."Tourist Visits" v
        JOIN public."Tourist Information" t ON t.tourist_id = v.tourist_id
        LEFT JOIN public."Tourist's Passport Details" passport ON passport.tourist_id = t.tourist_id
        LEFT JOIN public."Tourist Children" child ON child.tourist_id = t.tourist_id
        CROSS JOIN bounds b
        WHERE v.arrival_date >= b.month_start AND v.arrival_date < b.next_month
    ),
    finances AS (
        SELECT COALESCE(SUM(f.amount) FILTER (WHERE f.transaction_type = 'Доход'), 0)::NUMERIC AS total_revenue,
               COALESCE(SUM(f.amount) FILTER (WHERE f.transaction_type = 'Расход'), 0)::NUMERIC AS total_expenses
        FROM public."Finances" f
        CROSS JOIN bounds b
        WHERE f.transaction_date >= b.month_start
          AND f.transaction_date < b.next_month
    ),
    demand AS (
        SELECT COALESCE(ARRAY_AGG(d.package_name || ' — ' || d.sold_count
                                  ORDER BY d.sold_count DESC, d.package_name)
                        FILTER (WHERE d.sold_count > 0 AND d.sold_count = max_demand.value),
                        ARRAY[]::TEXT[]) AS most_demanded
        FROM package_demand d
        CROSS JOIN (SELECT MAX(sold_count) AS value FROM package_demand) max_demand
    ),
    unsold AS (
        SELECT COALESCE(
            ARRAY_AGG(d.package_name || ' — мест: ' || d.monthly_capacity
                      ORDER BY d.package_name) FILTER (WHERE d.sold_count = 0),
            ARRAY[]::TEXT[]
        ) AS unsold_packages
        FROM package_demand d
    )
    SELECT p_year,
           p_month,
           (SELECT COUNT(*)::BIGINT FROM sales),
           documents.passport_count,
           documents.visa_count,
           documents.child_document_count,
           (documents.passport_count + documents.visa_count + documents.child_document_count)::BIGINT,
           COALESCE((SELECT SUM(price) FROM sales), 0)::NUMERIC,
           finances.total_revenue,
           finances.total_expenses,
           finances.total_revenue - finances.total_expenses,
           demand.most_demanded,
           unsold.unsold_packages
    FROM documents
    CROSS JOIN finances
    CROSS JOIN demand
    CROSS JOIN unsold;
$$;

CREATE OR REPLACE FUNCTION public.coursework_flight_tourist_details(p_flight_number TEXT)
RETURNS TABLE (
    flight_number TEXT,
    flight_date DATE,
    full_name TEXT,
    category TEXT,
    has_visa BOOLEAN,
    hotel_name TEXT,
    room_number TEXT,
    cargo_type TEXT,
    places_count INTEGER,
    cargo_weight NUMERIC,
    volume_weight NUMERIC,
    tags TEXT,
    marking TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT f.flight_number::TEXT,
           f.flight_date,
           CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)::TEXT,
           t.category::TEXT,
           t.has_visa,
           h.hotel_name,
           h.room_number,
           c.cargo_type::TEXT,
           c.places_count,
           c.actual_weight::NUMERIC,
           c.volume_weight::NUMERIC,
           c.tags::TEXT,
           c.marking::TEXT
    FROM public."Flights" f
    JOIN public."Tourist Information" t ON t.flight_id = f.flight_id
    LEFT JOIN LATERAL (
        SELECT STRING_AGG(
                   FORMAT('%s (номер %s, %s — %s)', hotel.hotel_name, booking.room_number,
                          booking.check_in_date, booking.check_out_date),
                   '; ' ORDER BY booking.check_in_date
               )::TEXT AS hotel_name,
               STRING_AGG(DISTINCT booking.room_number, ', ' ORDER BY booking.room_number)::TEXT AS room_number
        FROM public."Bookings" booking
        JOIN public."Hotels" hotel ON hotel.hotel_id = booking.hotel_id
        WHERE booking.tourist_id = t.tourist_id
    ) h ON TRUE
    LEFT JOIN public."Tourist Cargo" c ON c.tourist_id = t.tourist_id
    WHERE f.flight_number = BTRIM(p_flight_number)
    ORDER BY t.tourist_surname, t.tourist_name;
$$;

CREATE OR REPLACE FUNCTION public.coursework_cargo_type_statistics(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    cargo_type TEXT,
    total_places BIGINT,
    total_weight NUMERIC,
    total_volume_weight NUMERIC,
    percentage NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    WITH filtered AS (
        SELECT c.cargo_type, c.places_count, c.actual_weight, c.volume_weight
        FROM public."Tourist Cargo" c
        JOIN public."Flights" f ON f.flight_id = c.flight_id
        WHERE (p_start_date IS NULL OR f.flight_date >= p_start_date)
          AND (p_end_date IS NULL OR f.flight_date <= p_end_date)
    )
    SELECT f.cargo_type::TEXT,
           SUM(f.places_count)::BIGINT,
           SUM(f.actual_weight)::NUMERIC,
           SUM(f.volume_weight)::NUMERIC,
           ROUND(SUM(f.actual_weight) * 100.0 / NULLIF(SUM(SUM(f.actual_weight)) OVER (), 0), 2)::NUMERIC
    FROM filtered f
    GROUP BY f.cargo_type
    ORDER BY SUM(f.actual_weight) DESC, f.cargo_type;
$$;

-- Single stored-procedure entry point for report queries. Each report key is
-- explicitly whitelisted; request values are read from JSON and remain typed.
CREATE OR REPLACE PROCEDURE public.coursework_run_report(
    IN p_report_key TEXT,
    IN p_parameters JSONB,
    INOUT p_result JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date DATE := NULLIF(p_parameters ->> 'start_date', '')::DATE;
    v_end_date DATE := NULLIF(p_parameters ->> 'end_date', '')::DATE;
    v_category TEXT := NULLIF(BTRIM(p_parameters ->> 'category'), '');
    v_flight_id INTEGER := NULLIF(p_parameters ->> 'flight_id', '')::INTEGER;
    v_flight_number TEXT := NULLIF(BTRIM(p_parameters ->> 'flight_number'), '');
BEGIN
    CASE p_report_key
        WHEN 'customs_tourists' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.getcustomstouristlist(v_category) AS r;
        WHEN 'hotel_check_in' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.coursework_hotel_check_in_with_children(
                NULLIF(p_parameters ->> 'hotel_name', ''), v_category
            ) AS r;
        WHEN 'tourist_count' THEN
            p_result := jsonb_build_object(
                'total_tourists', public.gettouristcount(v_start_date, v_end_date, v_category),
                'category', COALESCE(v_category, 'Все категории'),
                'start_date', v_start_date,
                'end_date', v_end_date
            );
        WHEN 'tourist_profile' THEN
            SELECT to_jsonb(r) INTO p_result
            FROM public.coursework_tourist_profile(
                NULLIF(p_parameters ->> 'tourist_id', '')::INTEGER
            ) AS r;
            p_result := COALESCE(p_result, 'null'::JSONB);
        WHEN 'hotel_occupancy' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.coursework_hotel_occupancy(v_start_date, v_end_date, v_category) AS r;
        WHEN 'excursion_tourists_count' THEN
            SELECT to_jsonb(r) || jsonb_build_object(
                       'start_date', v_start_date,
                       'end_date', v_end_date
                   )
            INTO p_result
            FROM public.coursework_excursion_tourists_count(v_start_date, v_end_date) AS r;
        WHEN 'excursion_summary' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.coursework_excursion_summary_with_children() AS r;
        WHEN 'excursion_agency_quality' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.coursework_excursion_agency_quality() AS r;
        WHEN 'flight_load' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.coursework_flight_load(v_start_date, v_end_date, v_flight_number) AS r;
        WHEN 'cargo_summary' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.getcargosummaryreport() AS r;
        WHEN 'cargo_turnover' THEN
            SELECT to_jsonb(r) INTO p_result
            FROM public.coursework_cargo_turnover(v_start_date, v_end_date) AS r;
        WHEN 'financial_summary' THEN
            SELECT to_jsonb(r) INTO p_result
            FROM public.coursework_financial_summary(
                v_start_date, v_end_date, v_flight_id, v_category
            ) AS r;
        WHEN 'financial_items' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.coursework_financial_items(
                v_start_date, v_end_date, v_flight_id, v_category
            ) AS r;
        WHEN 'monthly_business' THEN
            SELECT to_jsonb(r) INTO p_result
            FROM public.coursework_monthly_business_report_complete(
                (p_parameters ->> 'year')::INTEGER,
                (p_parameters ->> 'month')::INTEGER
            ) AS r;
        WHEN 'cargo_type_statistics' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.coursework_cargo_type_statistics(v_start_date, v_end_date) AS r;
        WHEN 'tourists_category_ratio' THEN
            SELECT to_jsonb(r) INTO p_result
            FROM public.gettouristscategoryratio(v_start_date, v_end_date) AS r;
        WHEN 'flight_tourist_details' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.coursework_flight_tourist_details(v_flight_number) AS r;
        WHEN 'passport_control' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.getpassportcontrolreport() AS r;
        WHEN 'family_tours' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.getfamilytoursreport() AS r;
        WHEN 'visa_status' THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(r)), '[]'::JSONB)
            INTO p_result
            FROM public.getvisastatusreport(
                (p_parameters ->> 'has_visa_filter')::BOOLEAN
            ) AS r;
        ELSE
            RAISE EXCEPTION 'Unknown coursework report key: %', p_report_key
                USING ERRCODE = '22023';
    END CASE;
END;
$$;
