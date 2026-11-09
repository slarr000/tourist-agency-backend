-- Destructively replaces all public-schema business data with a synthetic
-- defense/demo dataset. Employee accounts are preserved.
-- Run only against the intended coursework database after StoredProcedures.sql
-- and CourseworkEnhancements.sql have been applied.
-- The whole script is transactional: any error rolls back the cleanup and seed.

BEGIN;

DO $$
BEGIN
    IF current_database() <> 'Touristic Firma' THEN
        RAISE EXCEPTION 'Expected database "Touristic Firma", connected to "%". Reset cancelled.', current_database();
    END IF;
    IF to_regclass('public.employee_accounts') IS NULL THEN
        RAISE EXCEPTION 'public.employee_accounts was not found. Cleanup cancelled.';
    END IF;
END;
$$;

CREATE TEMP TABLE demo_reset_remaining ON COMMIT DROP AS
SELECT c.oid AS relation_id, c.relname AS relation_name
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')
  AND c.relname <> 'employee_accounts';

CREATE TEMP TABLE demo_reset_tables ON COMMIT DROP AS
SELECT relation_id, relation_name
FROM demo_reset_remaining
WITH NO DATA;

CREATE TEMP TABLE demo_employee_account_guard ON COMMIT DROP AS
SELECT
    COUNT(*)::BIGINT AS account_count,
    md5(COALESCE(
        string_agg(
            concat_ws('|', employee_id, login, password_hash, role, is_active, created_at),
            E'\n' ORDER BY employee_id
        ),
        ''
    )) AS account_signature
FROM public.employee_accounts;

-- Remove excursion child bookings before their adult guardian bookings;
-- coursework triggers intentionally prevent orphaning accompanying children.
DO $$
BEGIN
    IF to_regclass('public."Excursion Bookings"') IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'Excursion Bookings'
              AND column_name = 'child_id'
        ) THEN
            DELETE FROM public."Excursion Bookings" WHERE child_id IS NOT NULL;
        END IF;
        DELETE FROM public."Excursion Bookings";
    END IF;
END;
$$;

DO $$
DECLARE
    v_relation RECORD;
BEGIN
    IF to_regclass('public.employee_accounts') IS NULL THEN
        RAISE EXCEPTION 'public.employee_accounts was not found. Cleanup cancelled.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint fk
        JOIN demo_reset_remaining referenced
          ON referenced.relation_id = fk.confrelid
        WHERE fk.contype = 'f'
          AND fk.conrelid = 'public.employee_accounts'::regclass
    ) THEN
        RAISE EXCEPTION 'Employee accounts reference a business table; cleanup cancelled to protect account data.';
    END IF;

    LOOP
        SELECT candidate.relation_id, candidate.relation_name
        INTO v_relation
        FROM demo_reset_remaining candidate
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint fk
            JOIN demo_reset_remaining dependent
              ON dependent.relation_id = fk.conrelid
            WHERE fk.contype = 'f'
              AND fk.confrelid = candidate.relation_id
              AND fk.conrelid <> candidate.relation_id
        )
        ORDER BY candidate.relation_name
        LIMIT 1;

        EXIT WHEN NOT FOUND;

        EXECUTE format('DELETE FROM public.%I', v_relation.relation_name);
        INSERT INTO demo_reset_tables VALUES (v_relation.relation_id, v_relation.relation_name);
        DELETE FROM demo_reset_remaining WHERE relation_id = v_relation.relation_id;
    END LOOP;

    IF EXISTS (SELECT 1 FROM demo_reset_remaining) THEN
        RAISE EXCEPTION 'A foreign-key cycle was found in public tables; cleanup cancelled.';
    END IF;
END;
$$;

DO $$
DECLARE
    v_table RECORD;
    v_column RECORD;
    v_sequence TEXT;
BEGIN
    FOR v_table IN SELECT relation_name FROM demo_reset_tables LOOP
        FOR v_column IN
            SELECT a.attname AS column_name
            FROM pg_attribute a
            JOIN pg_class c ON c.oid = a.attrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public'
              AND c.relname = v_table.relation_name
              AND a.attnum > 0
              AND NOT a.attisdropped
        LOOP
            v_sequence := pg_get_serial_sequence(
                format('public.%I', v_table.relation_name),
                v_column.column_name
            );
            IF v_sequence IS NOT NULL THEN
                PERFORM setval(v_sequence, 1, FALSE);
            END IF;
        END LOOP;
    END LOOP;
END;
$$;

-- Ensure the coursework fields used by the stock and monthly reports exist.
ALTER TABLE public."Flights"
    ADD COLUMN IF NOT EXISTS seat_capacity INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public."Finances"
    ADD COLUMN IF NOT EXISTS flight_id INTEGER,
    ADD COLUMN IF NOT EXISTS tourist_id INTEGER;
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
END;
$$;

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

CREATE TABLE IF NOT EXISTS public."Tour Package Sales" (
    sale_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    package_id INTEGER NOT NULL REFERENCES public."Tour Packages"(package_id),
    tourist_id INTEGER NOT NULL REFERENCES public."Tourist Information"(tourist_id),
    flight_id INTEGER NOT NULL REFERENCES public."Flights"(flight_id),
    sold_date DATE NOT NULL,
    UNIQUE (package_id, tourist_id)
);

CREATE TEMP TABLE demo_flights (
    flight_code TEXT PRIMARY KEY,
    flight_id INTEGER NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE demo_hotels (
    hotel_code TEXT PRIMARY KEY,
    hotel_id INTEGER NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE demo_agencies (
    agency_code TEXT PRIMARY KEY,
    agency_id INTEGER NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE demo_people (
    person_code TEXT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    patronymic TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender TEXT NOT NULL,
    has_children BOOLEAN NOT NULL,
    has_cargo BOOLEAN NOT NULL,
    flight_code TEXT NOT NULL,
    category TEXT NOT NULL,
    has_visa BOOLEAN NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE demo_tourists (
    person_code TEXT PRIMARY KEY,
    tourist_id INTEGER NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE demo_children (
    child_code TEXT PRIMARY KEY,
    child_id INTEGER NOT NULL,
    parent_code TEXT NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE demo_excursions (
    excursion_code TEXT PRIMARY KEY,
    excursion_id INTEGER NOT NULL,
    price NUMERIC(10, 2) NOT NULL
) ON COMMIT DROP;

INSERT INTO public."Flights"
    (flight_number, flight_date, aircraft_type, flight_type, seat_capacity)
VALUES
    ('DEF-401', DATE '2026-10-15', 'Airbus A321', 'Пассажирский', 180),
    ('DEF-512', DATE '2026-11-06', 'Boeing 737-800', 'Грузо-пассажирский', 164),
    ('DEF-520', DATE '2026-11-20', 'Ил-76ТД', 'Грузовой', 0),
    ('DEF-604', DATE '2026-12-04', 'Boeing 737-800', 'Грузо-пассажирский', 164),
    ('DEF-218', DATE '2026-06-12', 'Airbus A320', 'Пассажирский', 150);

INSERT INTO demo_flights
SELECT flight_number, flight_id
FROM public."Flights"
WHERE flight_number IN ('DEF-401', 'DEF-512', 'DEF-520', 'DEF-604', 'DEF-218');

INSERT INTO public."Hotels" (hotel_name, stars_count, address, price_per_night, country)
VALUES
    ('Лазурный берег', 5, 'Анталья, улица Пальмовая, 18', 168.00, 'Турция'),
    ('Старый город', 4, 'Анталья, улица Калеичи, 7', 124.00, 'Турция'),
    ('Босфор Палас', 5, 'Стамбул, проспект Истикляль, 42', 195.00, 'Турция'),
    ('Сити Гарден', 3, 'Стамбул, улица Таксим, 11', 96.00, 'Турция');

INSERT INTO demo_hotels
SELECT
    CASE hotel_name
        WHEN 'Лазурный берег' THEN 'coast'
        WHEN 'Старый город' THEN 'old-town'
        WHEN 'Босфор Палас' THEN 'bosporus'
        WHEN 'Сити Гарден' THEN 'city'
    END,
    hotel_id
FROM public."Hotels"
WHERE hotel_name IN ('Лазурный берег', 'Старый город', 'Босфор Палас', 'Сити Гарден');

INSERT INTO public."Agencies" (agency_name, quality_rating)
VALUES
    ('Атлас Путешествий', 9.40),
    ('Исторический маршрут', 9.10),
    ('Море и горы', 8.70),
    ('Стамбул сегодня', 8.30);

INSERT INTO demo_agencies
SELECT
    CASE agency_name
        WHEN 'Атлас Путешествий' THEN 'atlas'
        WHEN 'Исторический маршрут' THEN 'history'
        WHEN 'Море и горы' THEN 'nature'
        WHEN 'Стамбул сегодня' THEN 'istanbul'
    END,
    agency_id
FROM public."Agencies"
WHERE agency_name IN ('Атлас Путешествий', 'Исторический маршрут', 'Море и горы', 'Стамбул сегодня');

INSERT INTO demo_people VALUES
    ('anna-sokolova', 'Анна', 'Соколова', 'Игоревна', DATE '1988-03-14', 'Женский', TRUE, FALSE, 'DEF-401', 'Отдых', TRUE),
    ('dmitry-sokolov', 'Дмитрий', 'Соколов', 'Игоревич', DATE '1985-09-22', 'Мужской', FALSE, TRUE, 'DEF-401', 'Шоп-тур', TRUE),
    ('marina-lebedeva', 'Марина', 'Лебедева', 'Олеговна', DATE '1992-06-03', 'Женский', FALSE, FALSE, 'DEF-401', 'Отдых', TRUE),
    ('pavel-lebedev', 'Павел', 'Лебедев', 'Олегович', DATE '1987-01-19', 'Мужской', FALSE, TRUE, 'DEF-401', 'Шоп-тур', TRUE),
    ('olga-morozova', 'Ольга', 'Морозова', 'Викторовна', DATE '1979-11-08', 'Женский', TRUE, FALSE, 'DEF-401', 'Отдых', TRUE),
    ('elena-volkova', 'Елена', 'Волкова', 'Андреевна', DATE '1990-04-25', 'Женский', TRUE, FALSE, 'DEF-512', 'Отдых', TRUE),
    ('kirill-volkov', 'Кирилл', 'Волков', 'Андреевич', DATE '1986-12-17', 'Мужской', FALSE, TRUE, 'DEF-512', 'Шоп-тур', TRUE),
    ('natalia-petrova', 'Наталья', 'Петрова', 'Сергеевна', DATE '1995-02-11', 'Женский', FALSE, FALSE, 'DEF-512', 'Отдых', TRUE),
    ('roman-petrov', 'Роман', 'Петров', 'Сергеевич', DATE '1982-08-29', 'Мужской', FALSE, TRUE, 'DEF-512', 'Шоп-тур', FALSE),
    ('sofia-orlova', 'София', 'Орлова', 'Михайловна', DATE '1989-10-06', 'Женский', TRUE, FALSE, 'DEF-512', 'Отдых', TRUE),
    ('victor-sidorov', 'Виктор', 'Сидоров', 'Павлович', DATE '1978-05-13', 'Мужской', FALSE, TRUE, 'DEF-520', 'Шоп-тур', TRUE),
    ('tatiana-sidorova', 'Татьяна', 'Сидорова', 'Павловна', DATE '1981-07-24', 'Женский', FALSE, TRUE, 'DEF-520', 'Шоп-тур', TRUE),
    ('mikhail-karpov', 'Михаил', 'Карпов', 'Денисович', DATE '1993-03-02', 'Мужской', FALSE, TRUE, 'DEF-520', 'Шоп-тур', TRUE),
    ('olga-karpova', 'Ольга', 'Карпова', 'Денисовна', DATE '1991-12-30', 'Женский', FALSE, TRUE, 'DEF-520', 'Шоп-тур', TRUE),
    ('irina-smirnova', 'Ирина', 'Смирнова', 'Алексеевна', DATE '1986-02-18', 'Женский', TRUE, FALSE, 'DEF-604', 'Отдых', TRUE),
    ('alexey-smirnov', 'Алексей', 'Смирнов', 'Алексеевич', DATE '1984-05-09', 'Мужской', FALSE, TRUE, 'DEF-604', 'Шоп-тур', TRUE),
    ('vera-fedorova', 'Вера', 'Федорова', 'Ильинична', DATE '1996-08-15', 'Женский', FALSE, FALSE, 'DEF-604', 'Отдых', TRUE),
    ('denis-fedorov', 'Денис', 'Федоров', 'Ильич', DATE '1988-09-27', 'Мужской', FALSE, TRUE, 'DEF-604', 'Шоп-тур', TRUE),
    ('yulia-belova', 'Юлия', 'Белова', 'Романовна', DATE '1990-01-31', 'Женский', FALSE, FALSE, 'DEF-604', 'Отдых', TRUE),
    ('anton-belov', 'Антон', 'Белов', 'Романович', DATE '1983-04-12', 'Мужской', FALSE, TRUE, 'DEF-604', 'Шоп-тур', TRUE),
    ('sergey-ivanov', 'Сергей', 'Иванов', 'Петрович', DATE '1980-06-07', 'Мужской', FALSE, TRUE, 'DEF-401', 'Шоп-тур', TRUE),
    ('ekaterina-ivanova', 'Екатерина', 'Иванова', 'Петровна', DATE '1984-11-16', 'Женский', TRUE, FALSE, 'DEF-401', 'Отдых', TRUE);

INSERT INTO public."Tourist Information" (
    tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
    tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
)
SELECT
    p.first_name,
    p.last_name,
    p.patronymic,
    p.date_of_birth,
    p.gender,
    CASE WHEN p.has_children THEN 'Да' ELSE 'Нет' END,
    CASE WHEN p.has_cargo THEN 'Да' ELSE 'Нет' END,
    f.flight_id,
    p.category,
    p.has_visa
FROM demo_people p
JOIN demo_flights f ON f.flight_code = p.flight_code;

INSERT INTO demo_tourists
SELECT p.person_code, t.tourist_id
FROM demo_people p
JOIN public."Tourist Information" t
  ON t.tourist_name = p.first_name
 AND t.tourist_surname = p.last_name
 AND t.flight_id = (SELECT flight_id FROM demo_flights WHERE flight_code = p.flight_code);

INSERT INTO public."Tourist's Passport Details" (
    tourist_id, type_passport, passport_serial, passport_number, date_of_issue,
    issued_by, latin_name, expiry_date, department_code, registration_address
)
SELECT
    t.tourist_id,
    'Заграничный',
    'DEMO',
    'DEF-2026-' || lpad(ROW_NUMBER() OVER (ORDER BY p.person_code)::TEXT, 4, '0'),
    DATE '2018-01-01' + (ROW_NUMBER() OVER (ORDER BY p.person_code)::INTEGER % 2000),
    'Демонстрационные данные, орган выдачи условный',
    upper(p.first_name || ' ' || p.last_name),
    DATE '2028-01-01' + (ROW_NUMBER() OVER (ORDER BY p.person_code)::INTEGER % 2000),
    'DEMO-' || lpad(ROW_NUMBER() OVER (ORDER BY p.person_code)::TEXT, 3, '0'),
    'Демонстрационный адрес, не является реальными персональными данными'
FROM demo_people p
JOIN demo_tourists t USING (person_code);

INSERT INTO public."Tourist Children" (
    tourist_id, first_name, last_name, patronymic, date_of_birth, gender,
    birth_certificate_number, date_of_issue, issued_by
)
SELECT
    parent.tourist_id,
    child.first_name,
    child.last_name,
    child.patronymic,
    child.date_of_birth,
    child.gender,
    child.child_code,
    child.date_of_birth + 7,
    'Демонстрационные данные, орган регистрации условный'
FROM (VALUES
    ('child-anna', 'anna-sokolova', 'Алиса', 'Соколова', 'Дмитриевна', DATE '2016-05-20', 'Женский'),
    ('child-olga', 'olga-morozova', 'Марк', 'Морозов', 'Ильич', DATE '2014-09-03', 'Мужской'),
    ('child-elena', 'elena-volkova', 'Ева', 'Волкова', 'Кирилловна', DATE '2017-02-12', 'Женский'),
    ('child-sofia', 'sofia-orlova', 'Лев', 'Орлов', 'Романович', DATE '2015-07-08', 'Мужской'),
    ('child-irina', 'irina-smirnova', 'Мия', 'Смирнова', 'Алексеевна', DATE '2018-01-26', 'Женский'),
    ('child-ekaterina', 'ekaterina-ivanova', 'Артем', 'Иванов', 'Сергеевич', DATE '2013-04-14', 'Мужской')
) AS child(child_code, parent_code, first_name, last_name, patronymic, date_of_birth, gender)
JOIN demo_tourists parent ON parent.person_code = child.parent_code
RETURNING child_id, birth_certificate_number;

INSERT INTO demo_children
SELECT
    c.birth_certificate_number,
    c.child_id,
    d.parent_code
FROM public."Tourist Children" c
JOIN (VALUES
    ('child-anna', 'anna-sokolova'),
    ('child-olga', 'olga-morozova'),
    ('child-elena', 'elena-volkova'),
    ('child-sofia', 'sofia-orlova'),
    ('child-irina', 'irina-smirnova'),
    ('child-ekaterina', 'ekaterina-ivanova')
) AS d(child_code, parent_code) ON d.child_code = c.birth_certificate_number
JOIN demo_tourists t ON t.person_code = d.parent_code AND t.tourist_id = c.tourist_id;

INSERT INTO public."Bookings" (tourist_id, hotel_id, check_in_date, check_out_date, room_number)
SELECT
    tourist.tourist_id,
    hotel.hotel_id,
    flight.flight_date,
    flight.flight_date + CASE WHEN person.category = 'Шоп-тур' THEN 5 ELSE 8 END,
    'D-' || flight.flight_number || '-' || lpad(
        ROW_NUMBER() OVER (PARTITION BY flight.flight_id ORDER BY person.person_code)::TEXT, 3, '0')
FROM demo_people person
JOIN demo_tourists tourist USING (person_code)
JOIN demo_flights demo_flight ON demo_flight.flight_code = person.flight_code
JOIN public."Flights" flight ON flight.flight_id = demo_flight.flight_id
JOIN demo_hotels hotel
  ON hotel.hotel_code = CASE
       WHEN person.flight_code = 'DEF-401' AND person.category = 'Шоп-тур' THEN 'city'
       WHEN person.flight_code = 'DEF-512' AND person.category = 'Шоп-тур' THEN 'bosporus'
       WHEN person.flight_code = 'DEF-520' THEN 'city'
       WHEN person.flight_code = 'DEF-604' AND person.category = 'Шоп-тур' THEN 'city'
       WHEN person.flight_code = 'DEF-218' AND person.category = 'Шоп-тур' THEN 'city'
       ELSE 'coast'
     END;

INSERT INTO public."Tourist Visits" (tourist_id, flight_id, arrival_date, departure_date)
SELECT tourist.tourist_id, flight.flight_id, flight.flight_date, flight.flight_date + 7
FROM demo_people person
JOIN demo_tourists tourist USING (person_code)
JOIN demo_flights demo_flight ON demo_flight.flight_code = person.flight_code
JOIN public."Flights" flight ON flight.flight_id = demo_flight.flight_id;

-- Repeat visits make the individual history report meaningful.
INSERT INTO public."Tourist Visits" (tourist_id, flight_id, arrival_date, departure_date)
SELECT tourist.tourist_id, previous_flight.flight_id, DATE '2026-06-12', DATE '2026-06-19'
FROM demo_tourists tourist
JOIN demo_flights previous_flight ON previous_flight.flight_code = 'DEF-218'
WHERE tourist.person_code IN ('anna-sokolova', 'dmitry-sokolov', 'marina-lebedeva');
-- Two returning travelers also have a prior summer visit.
INSERT INTO public."Tourist Visits" (tourist_id, flight_id, arrival_date, departure_date)
SELECT tourist.tourist_id, previous_flight.flight_id, DATE '2026-06-12', DATE '2026-06-19'
FROM demo_tourists tourist
JOIN demo_flights previous_flight ON previous_flight.flight_code = 'DEF-218'
WHERE tourist.person_code IN ('sergey-ivanov', 'ekaterina-ivanova');

INSERT INTO public."Tour Packages" (
    package_code, package_name, destination, category, price, monthly_capacity, available_from, available_until
)
VALUES
    ('DEF-OCT-REST', 'Золотая осень на Средиземном море', 'Анталья', 'Отдых', 920.00, 12, DATE '2026-10-01', DATE '2026-10-31'),
    ('DEF-OCT-SHOP', 'Стамбул: шопинг и город', 'Стамбул', 'Шоп-тур', 640.00, 12, DATE '2026-10-01', DATE '2026-10-31'),
    ('DEF-NOV-REST', 'Ноябрьские каникулы у моря', 'Анталья', 'Отдых', 870.00, 12, DATE '2026-11-01', DATE '2026-11-30'),
    ('DEF-NOV-SHOP', 'Стамбул: сезон выгодных покупок', 'Стамбул', 'Шоп-тур', 590.00, 12, DATE '2026-11-01', DATE '2026-11-30'),
    ('DEF-DEC-REST', 'Зимняя неделя в Анталье', 'Анталья', 'Отдых', 1050.00, 12, DATE '2026-12-01', DATE '2026-12-31'),
    ('DEF-DEC-SHOP', 'Предновогодний шоп-тур', 'Стамбул', 'Шоп-тур', 720.00, 12, DATE '2026-12-01', DATE '2026-12-31'),
    ('DEF-UNSOLD', 'Зимний тур: специальное предложение', 'Каппадокия', 'Отдых', 1180.00, 8, DATE '2026-12-01', DATE '2027-01-31');

INSERT INTO public."Tour Package Sales" (package_id, tourist_id, flight_id, sold_date)
SELECT
    package.package_id,
    tourist.tourist_id,
    flight.flight_id,
    flight.flight_date - 3
FROM demo_people person
JOIN demo_tourists tourist USING (person_code)
JOIN demo_flights demo_flight ON demo_flight.flight_code = person.flight_code
JOIN public."Flights" flight ON flight.flight_id = demo_flight.flight_id
JOIN public."Tour Packages" package
  ON package.package_code = CASE
       WHEN person.flight_code IN ('DEF-401', 'DEF-218') AND person.category = 'Отдых' THEN 'DEF-OCT-REST'
       WHEN person.flight_code IN ('DEF-401', 'DEF-218') THEN 'DEF-OCT-SHOP'
       WHEN person.flight_code IN ('DEF-512', 'DEF-520') AND person.category = 'Отдых' THEN 'DEF-NOV-REST'
       WHEN person.flight_code IN ('DEF-512', 'DEF-520') THEN 'DEF-NOV-SHOP'
       WHEN person.flight_code = 'DEF-604' AND person.category = 'Отдых' THEN 'DEF-DEC-REST'
       ELSE 'DEF-DEC-SHOP'
     END;

INSERT INTO public."Excursions" (agency_id, excursion_name, schedule_date, price)
VALUES
    ((SELECT agency_id FROM demo_agencies WHERE agency_code = 'history'), 'Калеичи: старый город и гавань', TIMESTAMPTZ '2026-10-17 09:00:00+03', 78.00),
    ((SELECT agency_id FROM demo_agencies WHERE agency_code = 'nature'), 'Водопады Дюден и побережье', TIMESTAMPTZ '2026-10-19 08:30:00+03', 92.00),
    ((SELECT agency_id FROM demo_agencies WHERE agency_code = 'istanbul'), 'Стамбул: Босфор и исторический центр', TIMESTAMPTZ '2026-11-08 09:00:00+03', 105.00),
    ((SELECT agency_id FROM demo_agencies WHERE agency_code = 'atlas'), 'Принцевы острова и морская прогулка', TIMESTAMPTZ '2026-11-10 08:00:00+03', 118.00),
    ((SELECT agency_id FROM demo_agencies WHERE agency_code = 'history'), 'Перге и Аспендос: наследие античности', TIMESTAMPTZ '2026-12-06 08:00:00+03', 112.00),
    ((SELECT agency_id FROM demo_agencies WHERE agency_code = 'nature'), 'Термальные источники и каньон', TIMESTAMPTZ '2026-12-08 08:30:00+03', 98.00);

INSERT INTO demo_excursions
SELECT
    CASE excursion_name
        WHEN 'Калеичи: старый город и гавань' THEN 'oct-old-town'
        WHEN 'Водопады Дюден и побережье' THEN 'oct-waterfall'
        WHEN 'Стамбул: Босфор и исторический центр' THEN 'nov-bosphorus'
        WHEN 'Принцевы острова и морская прогулка' THEN 'nov-islands'
        WHEN 'Перге и Аспендос: наследие античности' THEN 'dec-perge'
        WHEN 'Термальные источники и каньон' THEN 'dec-canyon'
    END,
    excursion_id,
    price
FROM public."Excursions"
WHERE excursion_name IN (
    'Калеичи: старый город и гавань',
    'Водопады Дюден и побережье',
    'Стамбул: Босфор и исторический центр',
    'Принцевы острова и морская прогулка',
    'Перге и Аспендос: наследие античности',
    'Термальные источники и каньон'
);

-- Only leisure tourists book excursions; accompanying children are registered
-- separately after their parent has been booked, as required by the rules.
INSERT INTO public."Excursion Bookings" (tourist_id, excursion_id)
SELECT tourist.tourist_id, excursion.excursion_id
FROM demo_people person
JOIN demo_tourists tourist USING (person_code)
JOIN demo_excursions excursion ON excursion.excursion_code = CASE person.flight_code
    WHEN 'DEF-401' THEN CASE WHEN person.person_code IN ('anna-sokolova', 'olga-morozova') THEN 'oct-old-town' ELSE 'oct-waterfall' END
    WHEN 'DEF-512' THEN CASE WHEN person.person_code IN ('elena-volkova', 'sofia-orlova') THEN 'nov-bosphorus' ELSE 'nov-islands' END
    WHEN 'DEF-604' THEN CASE WHEN person.person_code IN ('irina-smirnova', 'vera-fedorova') THEN 'dec-perge' ELSE 'dec-canyon' END
    ELSE NULL
END
WHERE person.category = 'Отдых';

INSERT INTO public."Excursion Bookings" (tourist_id, excursion_id, child_id)
SELECT parent.tourist_id, adult_booking.excursion_id, child.child_id
FROM demo_children child
JOIN demo_tourists parent ON parent.person_code = child.parent_code
JOIN public."Excursion Bookings" adult_booking
  ON adult_booking.tourist_id = parent.tourist_id
 AND adult_booking.child_id IS NULL
JOIN demo_excursions excursion ON excursion.excursion_id = adult_booking.excursion_id
WHERE child.parent_code IN (
    'anna-sokolova', 'olga-morozova', 'elena-volkova',
    'sofia-orlova', 'irina-smirnova', 'ekaterina-ivanova'
);

INSERT INTO public."Tourist Cargo" (
    tourist_id, cargo_type, places_count, actual_weight, volume_weight,
    marking, tags, packaging_cost, insurance_cost, total_amount, flight_id, status
)
SELECT
    tourist.tourist_id,
    cargo.cargo_type,
    cargo.places_count,
    cargo.actual_weight,
    cargo.volume_weight,
    cargo.marking,
    cargo.tags,
    cargo.packaging_cost,
    cargo.insurance_cost,
    cargo.packaging_cost + cargo.insurance_cost,
    flight.flight_id,
    cargo.status
FROM (VALUES
    ('dmitry-sokolov', 'DEF-401', 'Текстиль', 3, 34.50::NUMERIC, 39.20::NUMERIC, 'Партия DEF401-A', 'DEF401-001, DEF401-002, DEF401-003', 32.00::NUMERIC, 18.00::NUMERIC, 'Отправлен'),
    ('pavel-lebedev', 'DEF-401', 'Кожаные изделия', 2, 21.00::NUMERIC, 24.00::NUMERIC, 'Партия DEF401-B', 'DEF401-004, DEF401-005', 24.00::NUMERIC, 15.00::NUMERIC, 'Отправлен'),
    ('kirill-volkov', 'DEF-512', 'Текстиль', 4, 42.00::NUMERIC, 47.50::NUMERIC, 'Партия DEF512-A', 'DEF512-001, DEF512-002, DEF512-003, DEF512-004', 38.00::NUMERIC, 24.00::NUMERIC, 'Готов к отправке'),
    ('roman-petrov', 'DEF-512', 'Электроника', 2, 18.40::NUMERIC, 22.00::NUMERIC, 'Партия DEF512-B', 'DEF512-005, DEF512-006', 28.00::NUMERIC, 42.00::NUMERIC, 'Упакован'),
    ('victor-sidorov', 'DEF-520', 'Текстиль', 6, 68.00::NUMERIC, 73.00::NUMERIC, 'Партия DEF520-A', 'DEF520-001 — DEF520-006', 55.00::NUMERIC, 35.00::NUMERIC, 'Принят на склад'),
    ('tatiana-sidorova', 'DEF-520', 'Посуда и декор', 3, 26.00::NUMERIC, 31.50::NUMERIC, 'Партия DEF520-B', 'DEF520-007, DEF520-008, DEF520-009', 36.00::NUMERIC, 28.00::NUMERIC, 'Принят на склад'),
    ('mikhail-karpov', 'DEF-520', 'Обувь', 4, 32.00::NUMERIC, 35.00::NUMERIC, 'Партия DEF520-C', 'DEF520-010 — DEF520-013', 40.00::NUMERIC, 25.00::NUMERIC, 'Упакован'),
    ('olga-karpova', 'DEF-520', 'Сувениры', 2, 12.50::NUMERIC, 15.00::NUMERIC, 'Партия DEF520-D', 'DEF520-014, DEF520-015', 18.00::NUMERIC, 16.00::NUMERIC, 'Готов к отправке'),
    ('alexey-smirnov', 'DEF-604', 'Текстиль', 3, 29.00::NUMERIC, 33.00::NUMERIC, 'Партия DEF604-A', 'DEF604-001, DEF604-002, DEF604-003', 30.00::NUMERIC, 21.00::NUMERIC, 'Принят на склад'),
    ('denis-fedorov', 'DEF-604', 'Косметика', 2, 15.00::NUMERIC, 17.50::NUMERIC, 'Партия DEF604-B', 'DEF604-004, DEF604-005', 22.00::NUMERIC, 19.00::NUMERIC, 'Принят на склад'),
    ('anton-belov', 'DEF-604', 'Бытовая техника', 2, 38.00::NUMERIC, 45.00::NUMERIC, 'Партия DEF604-C', 'DEF604-006, DEF604-007', 44.00::NUMERIC, 52.00::NUMERIC, 'Принят на склад'),
    ('sergey-ivanov', 'DEF-401', 'Текстиль', 2, 24.00::NUMERIC, 27.00::NUMERIC, 'Партия DEF401-C', 'DEF401-006, DEF401-007', 25.00::NUMERIC, 17.00::NUMERIC, 'Отправлен')
) AS cargo(person_code, flight_code, cargo_type, places_count, actual_weight, volume_weight, marking, tags, packaging_cost, insurance_cost, status)
JOIN demo_tourists tourist USING (person_code)
JOIN demo_flights flight USING (flight_code);

INSERT INTO public."Finances" (
    transaction_type, category, amount, transaction_date, description, flight_id, tourist_id
)
SELECT
    'Доход',
    'Продажа путевки',
    package.price,
    sale.sold_date,
    'Демонстрационная продажа: ' || package.package_name || ' (' || person.first_name || ' ' || person.last_name || ')',
    sale.flight_id,
    sale.tourist_id
FROM public."Tour Package Sales" sale
JOIN public."Tour Packages" package USING (package_id)
JOIN demo_tourists tourist USING (tourist_id)
JOIN demo_people person USING (person_code);

INSERT INTO public."Finances" (
    transaction_type, category, amount, transaction_date, description, flight_id
)
SELECT 'Расход', expense.category, expense.amount, flight.flight_date,
       'Демонстрационные расходы группы рейса ' || flight.flight_number || ': ' || expense.category,
       flight.flight_id
FROM demo_flights mapping
JOIN public."Flights" flight USING (flight_id)
CROSS JOIN LATERAL (
    VALUES
        ('Размещение группы', CASE flight.flight_number WHEN 'DEF-401' THEN 1860.00 WHEN 'DEF-512' THEN 2140.00 WHEN 'DEF-520' THEN 980.00 WHEN 'DEF-604' THEN 2280.00 ELSE 1420.00 END::NUMERIC),
        ('Трансфер', CASE flight.flight_number WHEN 'DEF-401' THEN 220.00 WHEN 'DEF-512' THEN 245.00 WHEN 'DEF-520' THEN 180.00 WHEN 'DEF-604' THEN 260.00 ELSE 190.00 END::NUMERIC),
        ('Аэропортовые услуги', CASE flight.flight_number WHEN 'DEF-401' THEN 145.00 WHEN 'DEF-512' THEN 190.00 WHEN 'DEF-520' THEN 310.00 WHEN 'DEF-604' THEN 205.00 ELSE 130.00 END::NUMERIC)
) AS expense(category, amount);

INSERT INTO public."Finances" (
    transaction_type, category, amount, transaction_date, description, flight_id, tourist_id
)
SELECT
    'Доход',
    'Экскурсионное обслуживание',
    excursion.price,
    excursion_record.schedule_date::DATE,
    'Демонстрационная запись на экскурсию: ' || excursion_record.excursion_name,
    person_flight.flight_id,
    booking.tourist_id
FROM public."Excursion Bookings" booking
JOIN public."Excursions" excursion_record ON excursion_record.excursion_id = booking.excursion_id
JOIN demo_excursions excursion ON excursion.excursion_id = booking.excursion_id
JOIN demo_tourists tourist ON tourist.tourist_id = booking.tourist_id
JOIN demo_people person USING (person_code)
JOIN demo_flights person_flight ON person_flight.flight_code = person.flight_code;

INSERT INTO public."Finances" (
    transaction_type, category, amount, transaction_date, description, flight_id, tourist_id
)
SELECT
    'Доход',
    'Упаковка и страхование',
    cargo.total_amount,
    flight.flight_date,
    'Демонстрационные складские услуги: ' || cargo.marking,
    cargo.flight_id,
    cargo.tourist_id
FROM public."Tourist Cargo" cargo
JOIN public."Flights" flight ON flight.flight_id = cargo.flight_id;

DO $$
DECLARE
    expected_accounts BIGINT;
    expected_account_signature TEXT;
    actual_account_signature TEXT;
BEGIN
    SELECT account_count, account_signature
    INTO expected_accounts, expected_account_signature
    FROM demo_employee_account_guard;
    SELECT md5(COALESCE(
        string_agg(
            concat_ws('|', employee_id, login, password_hash, role, is_active, created_at),
            E'\n' ORDER BY employee_id
        ),
        ''
    ))
    INTO actual_account_signature
    FROM public.employee_accounts;
    IF (SELECT COUNT(*) FROM public.employee_accounts) <> expected_accounts THEN
        RAISE EXCEPTION 'Employee account count changed; rolling back the demo reset.';
    END IF;
    IF actual_account_signature <> expected_account_signature THEN
        RAISE EXCEPTION 'Employee account data changed; rolling back the demo reset.';
    END IF;
    IF (SELECT COUNT(*) FROM public."Tourist Information") <> 22
       OR (SELECT COUNT(*) FROM public."Tourist Children") <> 6
       OR (SELECT COUNT(*) FROM public."Flights") <> 5
       OR (SELECT COUNT(*) FROM public."Tourist Cargo") <> 12
       OR (SELECT COUNT(*) FROM public."Tour Package Sales") <> 22 THEN
        RAISE EXCEPTION 'Demo dataset verification failed; rolling back the reset.';
    END IF;
END;
$$;

-- Compact verification summary shown by pgAdmin after the reset and seed.
SELECT 'Сотрудники (сохранены)' AS показатель, COUNT(*)::TEXT AS значение
FROM public.employee_accounts
UNION ALL SELECT 'Туристы', COUNT(*)::TEXT FROM public."Tourist Information"
UNION ALL SELECT 'Дети', COUNT(*)::TEXT FROM public."Tourist Children"
UNION ALL SELECT 'Рейсы', COUNT(*)::TEXT FROM public."Flights"
UNION ALL SELECT 'Гостиничные бронирования', COUNT(*)::TEXT FROM public."Bookings"
UNION ALL SELECT 'Экскурсии', COUNT(*)::TEXT FROM public."Excursions"
UNION ALL SELECT 'Записи на экскурсии', COUNT(*)::TEXT FROM public."Excursion Bookings"
UNION ALL SELECT 'Складские ведомости', COUNT(*)::TEXT FROM public."Tourist Cargo"
UNION ALL SELECT 'Продажи путевок', COUNT(*)::TEXT FROM public."Tour Package Sales"
UNION ALL SELECT 'Финансовые операции', COUNT(*)::TEXT FROM public."Finances"
ORDER BY 1;

COMMIT;
