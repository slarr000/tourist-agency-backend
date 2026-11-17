-- Adds a sizeable, fully synthetic dataset for coursework demonstrations.
-- No real personal data is used. The marker makes re-running this script safe.
-- Run after StoredProcedures.sql and CourseworkEnhancements.sql.

DO $$
DECLARE
    dataset_marker CONSTANT TEXT := 'CW-SYNTH-001';
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public."Flights"
        WHERE flight_number = dataset_marker
    ) THEN
        RAISE NOTICE 'Coursework synthetic dataset already exists; skipping inserts.';
        RETURN;
    END IF;

    INSERT INTO public."Flights"
        (flight_number, flight_date, aircraft_type, flight_type, seat_capacity)
    SELECT
        'CW-SYNTH-' || lpad(n::TEXT, 3, '0'),
        DATE '2026-11-15' + ((n - 1) * 30),
        (ARRAY['Airbus A320', 'Airbus A321', 'Boeing 737', 'Boeing 757'])[((n - 1) % 4) + 1],
        'Пассажирский',
        40
    FROM generate_series(1, 12) AS n;

    INSERT INTO public."Hotels"
        (hotel_name, stars_count, address, price_per_night, country)
    SELECT
        'CW-SYNTH-HOTEL-' || lpad(n::TEXT, 2, '0'),
        3 + (n % 3),
        'Тестовый адрес ' || n || ', Анталья',
        75.00 + (n * 12.50),
        CASE WHEN n % 2 = 0 THEN 'Турция' ELSE 'Греция' END
    FROM generate_series(1, 8) AS n;

    INSERT INTO public."Agencies" (agency_name, quality_rating)
    SELECT 'CW-SYNTH-AGENCY-' || lpad(n::TEXT, 2, '0'),
           6.00 + (n * 0.60)
    FROM generate_series(1, 6) AS n;

    INSERT INTO public."Tourist Information" (
        tourist_name,
        tourist_surname,
        tourist_patronymic,
        tourist_date_of_birth,
        tourist_gender,
        tourist_children,
        tourist_cargo,
        flight_id,
        category,
        has_visa
    )
    SELECT
        CASE WHEN n % 2 = 0 THEN
            (ARRAY[
                'Александр', 'Алексей', 'Андрей', 'Виктор', 'Дмитрий',
                'Иван', 'Кирилл', 'Михаил', 'Сергей', 'Тимур'
            ])[(((n / 2) - 1) % 10) + 1]
        ELSE
            (ARRAY[
                'Анна', 'Валерия', 'Дарья', 'Екатерина', 'Елена',
                'Ирина', 'Мария', 'Наталья', 'Ольга', 'Юлия'
            ])[(((n - 1) / 2) % 10) + 1]
        END,
        CASE WHEN n % 2 = 0 THEN
            (ARRAY[
                'Смирнов', 'Иванов', 'Кузнецов', 'Попов', 'Соколов',
                'Лебедев', 'Козлов', 'Новиков', 'Морозов', 'Петров',
                'Волков', 'Соловьев', 'Васильев', 'Зайцев', 'Павлов'
            ])[(((n - 1) / 20) % 15) + 1]
        ELSE
            (ARRAY[
                'Смирнова', 'Иванова', 'Кузнецова', 'Попова', 'Соколова',
                'Лебедева', 'Козлова', 'Новикова', 'Морозова', 'Петрова',
                'Волкова', 'Соловьева', 'Васильева', 'Зайцева', 'Павлова'
            ])[(((n - 1) / 20) % 15) + 1]
        END,
        CASE WHEN n % 2 = 0 THEN
            (ARRAY[
                'Александрович', 'Алексеевич', 'Андреевич', 'Викторович',
                'Дмитриевич', 'Иванович', 'Кириллович', 'Михайлович',
                'Сергеевич', 'Тимурович'
            ])[(((n / 2) - 1) % 10) + 1]
        ELSE
            (ARRAY[
                'Александровна', 'Алексеевна', 'Андреевна', 'Викторовна',
                'Дмитриевна', 'Ивановна', 'Кирилловна', 'Михайловна',
                'Сергеевна', 'Тимуровна'
            ])[(((n - 1) / 2) % 10) + 1]
        END,
        DATE '2005-01-01' - ((n * 487) % 14000),
        CASE WHEN n % 2 = 0 THEN 'Мужской' ELSE 'Женский' END,
        CASE WHEN n % 5 = 0 THEN 'Да' ELSE 'Нет' END,
        CASE WHEN n % 4 = 0 THEN 'Да' ELSE 'Нет' END,
        f.flight_id,
        CASE n % 3
            WHEN 0 THEN 'Отдых'
            WHEN 1 THEN 'Шоп-тур'
            ELSE 'Деловая поездка'
        END,
        n % 11 <> 0
    FROM generate_series(1, 300) AS n
    JOIN public."Flights" f
      ON f.flight_number = 'CW-SYNTH-' || lpad((((n - 1) / 25) + 1)::TEXT, 3, '0');

    INSERT INTO public."Tourist's Passport Details" (
        tourist_id,
        type_passport,
        passport_serial,
        passport_number,
        date_of_issue,
        issued_by,
        latin_name,
        expiry_date,
        department_code,
        registration_address
    )
    SELECT
        t.tourist_id,
        'Заграничный',
        'CWTEST',
        'CW-TEST-' || lpad(ROW_NUMBER() OVER (ORDER BY t.tourist_id)::TEXT, 4, '0'),
        DATE '2017-01-01' + (ROW_NUMBER() OVER (ORDER BY t.tourist_id)::INTEGER % 1800),
        'Учебные данные; не является реальным документом',
        'SYNTHETIC TOURIST ' || lpad(ROW_NUMBER() OVER (ORDER BY t.tourist_id)::TEXT, 4, '0'),
        DATE '2027-01-01' + (ROW_NUMBER() OVER (ORDER BY t.tourist_id)::INTEGER % 1800),
        'CW-' || lpad(ROW_NUMBER() OVER (ORDER BY t.tourist_id)::TEXT, 6, '0'),
        'Тестовый адрес, г. Анталья'
    FROM public."Tourist Information" t
    JOIN public."Flights" f ON f.flight_id = t.flight_id
    WHERE f.flight_number LIKE 'CW-SYNTH-%';

    INSERT INTO public."Tourist Children" (
        tourist_id,
        first_name,
        last_name,
        patronymic,
        date_of_birth,
        gender,
        birth_certificate_number,
        date_of_issue,
        issued_by
    )
    SELECT
        t.tourist_id,
        CASE WHEN seq % 2 = 0 THEN
            (ARRAY['Артем', 'Илья', 'Тимур'])[((seq / 2 - 1) % 3) + 1]
        ELSE
            (ARRAY['Алиса', 'Вера', 'Милана'])[(((seq - 1) / 2) % 3) + 1]
        END,
        t.tourist_surname,
        NULL,
        DATE '2012-01-01' + (seq % 3200),
        CASE WHEN seq % 2 = 0 THEN 'Мужской' ELSE 'Женский' END,
        'CW-CHILD-' || lpad(seq::TEXT, 4, '0'),
        DATE '2012-01-08' + (seq % 3200),
        'Учебные данные; не является реальным документом'
    FROM (
        SELECT t.tourist_id,
               t.tourist_surname,
               ROW_NUMBER() OVER (ORDER BY t.tourist_id)::INTEGER AS seq
        FROM public."Tourist Information" t
        JOIN public."Flights" f ON f.flight_id = t.flight_id
        WHERE f.flight_number LIKE 'CW-SYNTH-%'
          AND t.tourist_children = 'Да'
    ) t;

    INSERT INTO public."Bookings"
        (tourist_id, hotel_id, check_in_date, check_out_date, room_number)
    SELECT
        t.tourist_id,
        h.hotel_id,
        f.flight_date,
        f.flight_date + 7 + (t.seq % 3),
        'CW-' || lpad(t.seq::TEXT, 4, '0')
    FROM (
        SELECT t.tourist_id,
               t.flight_id,
               ROW_NUMBER() OVER (ORDER BY t.tourist_id)::INTEGER AS seq
        FROM public."Tourist Information" t
        JOIN public."Flights" f ON f.flight_id = t.flight_id
        WHERE f.flight_number LIKE 'CW-SYNTH-%'
    ) t
    JOIN public."Flights" f ON f.flight_id = t.flight_id
    JOIN public."Hotels" h
      ON h.hotel_name = 'CW-SYNTH-HOTEL-' || lpad((((t.seq - 1) % 8) + 1)::TEXT, 2, '0');

    INSERT INTO public."Tourist Visits"
        (tourist_id, flight_id, arrival_date, departure_date)
    SELECT
        t.tourist_id,
        t.flight_id,
        f.flight_date,
        f.flight_date + 7 + (ROW_NUMBER() OVER (ORDER BY t.tourist_id)::INTEGER % 3)
    FROM public."Tourist Information" t
    JOIN public."Flights" f ON f.flight_id = t.flight_id
    WHERE f.flight_number LIKE 'CW-SYNTH-%';

    INSERT INTO public."Tourist Cargo" (
        tourist_id,
        cargo_type,
        places_count,
        actual_weight,
        volume_weight,
        marking,
        tags,
        packaging_cost,
        insurance_cost,
        total_amount,
        flight_id
    )
    SELECT
        t.tourist_id,
        (ARRAY['Личные вещи', 'Текстиль', 'Сувениры', 'Спортивный инвентарь'])[((seq - 1) % 4) + 1],
        1 + (seq % 4),
        (8 + (seq % 35))::NUMERIC(8, 2),
        (10 + (seq % 40))::NUMERIC(8, 2),
        'CW-MARK-' || lpad(seq::TEXT, 4, '0'),
        'CW-TAG-' || lpad(seq::TEXT, 4, '0'),
        (10 + (seq % 20))::NUMERIC(8, 2),
        (5 + (seq % 15))::NUMERIC(8, 2),
        (15 + (seq % 35))::NUMERIC(8, 2),
        t.flight_id
    FROM (
        SELECT t.tourist_id,
               t.flight_id,
               ROW_NUMBER() OVER (ORDER BY t.tourist_id)::INTEGER AS seq
        FROM public."Tourist Information" t
        JOIN public."Flights" f ON f.flight_id = t.flight_id
        WHERE f.flight_number LIKE 'CW-SYNTH-%'
          AND t.tourist_cargo = 'Да'
    ) t;

    INSERT INTO public."Excursions"
        (agency_id, excursion_name, schedule_date, price)
    SELECT
        a.agency_id,
        'CW-SYNTH-EXC-' || right(f.flight_number, 3) || '-' || excursion_option.code,
        (f.flight_date + excursion_option.day_offset) + TIME '09:00',
        excursion_option.price
    FROM public."Flights" f
    JOIN public."Agencies" a
      ON a.agency_name = 'CW-SYNTH-AGENCY-' ||
         lpad(((((right(f.flight_number, 3)::INTEGER - 1) % 6) + 1))::TEXT, 2, '0')
    CROSS JOIN (VALUES
        ('A', 1, 45.00::NUMERIC),
        ('B', 2, 65.00::NUMERIC)
    ) AS excursion_option(code, day_offset, price)
    WHERE f.flight_number LIKE 'CW-SYNTH-%';

    INSERT INTO public."Excursion Bookings" (tourist_id, excursion_id)
    SELECT t.tourist_id, e.excursion_id
    FROM (
        SELECT t.tourist_id,
               t.flight_id,
               ROW_NUMBER() OVER (PARTITION BY t.flight_id ORDER BY t.tourist_id)::INTEGER AS group_seq
        FROM public."Tourist Information" t
        JOIN public."Flights" f ON f.flight_id = t.flight_id
        WHERE f.flight_number LIKE 'CW-SYNTH-%'
    ) t
    JOIN public."Flights" f ON f.flight_id = t.flight_id
    JOIN public."Excursions" e
      ON e.excursion_name = 'CW-SYNTH-EXC-' || right(f.flight_number, 3) ||
                            CASE WHEN t.group_seq % 2 = 0 THEN '-A' ELSE '-B' END;

    INSERT INTO public."Finances" (
        transaction_type,
        category,
        amount,
        transaction_date,
        description,
        flight_id,
        tourist_id
    )
    SELECT
        'Доход',
        'Продажа путевки',
        CASE t.category
            WHEN 'Шоп-тур' THEN 520.00
            WHEN 'Деловая поездка' THEN 680.00
            ELSE 750.00
        END,
        f.flight_date,
        'CW-SYNTH: оплата туриста #' || lpad(ROW_NUMBER() OVER (ORDER BY t.tourist_id)::TEXT, 4, '0'),
        t.flight_id,
        t.tourist_id
    FROM public."Tourist Information" t
    JOIN public."Flights" f ON f.flight_id = t.flight_id
    WHERE f.flight_number LIKE 'CW-SYNTH-%';

    INSERT INTO public."Finances" (
        transaction_type,
        category,
        amount,
        transaction_date,
        description,
        flight_id
    )
    SELECT
        'Расход',
        'Групповой трансфер',
        180.00 + (right(f.flight_number, 3)::INTEGER * 10),
        f.flight_date,
        'CW-SYNTH: трансфер группы ' || f.flight_number,
        f.flight_id
    FROM public."Flights" f
    WHERE f.flight_number LIKE 'CW-SYNTH-%';
END;
$$;

SELECT 'Рейсы' AS entity, COUNT(*) AS records
FROM public."Flights" WHERE flight_number LIKE 'CW-SYNTH-%'
UNION ALL
SELECT 'Туристы', COUNT(*)
FROM public."Tourist Information" t
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number LIKE 'CW-SYNTH-%'
UNION ALL
SELECT 'Гостиницы', COUNT(*)
FROM public."Hotels" WHERE hotel_name LIKE 'CW-SYNTH-HOTEL-%'
UNION ALL
SELECT 'Агентства', COUNT(*)
FROM public."Agencies" WHERE agency_name LIKE 'CW-SYNTH-AGENCY-%'
UNION ALL
SELECT 'Паспорта', COUNT(*)
FROM public."Tourist's Passport Details" p
JOIN public."Tourist Information" t ON t.tourist_id = p.tourist_id
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number LIKE 'CW-SYNTH-%'
UNION ALL
SELECT 'Дети', COUNT(*)
FROM public."Tourist Children" c
JOIN public."Tourist Information" t ON t.tourist_id = c.tourist_id
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number LIKE 'CW-SYNTH-%'
UNION ALL
SELECT 'Гостиничные бронирования', COUNT(*)
FROM public."Bookings" b
JOIN public."Tourist Information" t ON t.tourist_id = b.tourist_id
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number LIKE 'CW-SYNTH-%'
UNION ALL
SELECT 'Посещения', COUNT(*)
FROM public."Tourist Visits" v
JOIN public."Flights" f ON f.flight_id = v.flight_id
WHERE f.flight_number LIKE 'CW-SYNTH-%'
UNION ALL
SELECT 'Грузовые записи', COUNT(*)
FROM public."Tourist Cargo" c
JOIN public."Flights" f ON f.flight_id = c.flight_id
WHERE f.flight_number LIKE 'CW-SYNTH-%'
UNION ALL
SELECT 'Записи на экскурсии', COUNT(*)
FROM public."Excursion Bookings" eb
JOIN public."Tourist Information" t ON t.tourist_id = eb.tourist_id
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number LIKE 'CW-SYNTH-%'
UNION ALL
SELECT 'Экскурсии', COUNT(*)
FROM public."Excursions" WHERE excursion_name LIKE 'CW-SYNTH-EXC-%'
UNION ALL
SELECT 'Финансовые операции', COUNT(*)
FROM public."Finances"
WHERE description LIKE 'CW-SYNTH:%';
