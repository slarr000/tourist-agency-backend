-- Дополняет первоначальный DEMO-TF-2026 набор данными для отчетов.
-- Все записи синтетические. Повторный запуск не создает дубликаты.

DO $$
DECLARE
    october_flight_id INTEGER;
    november_flight_id INTEGER;
    coast_hotel_id INTEGER;
    city_hotel_id INTEGER;
    agency_id_value INTEGER;
    tourist_anna_id INTEGER;
    tourist_sergey_id INTEGER;
    tourist_elena_id INTEGER;
    tourist_mikhail_id INTEGER;
    tourist_olga_id INTEGER;
    tourist_pavel_id INTEGER;
    october_excursion_id INTEGER;
    november_excursion_id INTEGER;
BEGIN
    IF EXISTS (
        SELECT 1 FROM public."Flights"
        WHERE flight_number = 'DEMO-TF-OCT-2026'
    ) THEN
        RAISE NOTICE 'Расширенный демо-набор уже существует; вставка пропущена.';
        RETURN;
    END IF;

    INSERT INTO public."Flights" (flight_number, flight_date, aircraft_type, flight_type)
    VALUES ('DEMO-TF-OCT-2026', DATE '2026-10-15', 'Airbus A321', 'Пассажирский')
    RETURNING flight_id INTO october_flight_id;

    INSERT INTO public."Flights" (flight_number, flight_date, aircraft_type, flight_type)
    VALUES ('DEMO-TF-NOV-2026', DATE '2026-11-06', 'Boeing 737', 'Пассажирский')
    RETURNING flight_id INTO november_flight_id;

    INSERT INTO public."Hotels" (hotel_name, stars_count, address, price_per_night, country)
    VALUES ('DEMO Морской берег', 4, 'Набережная, 12', 145.00, 'Турция')
    RETURNING hotel_id INTO coast_hotel_id;

    INSERT INTO public."Hotels" (hotel_name, stars_count, address, price_per_night, country)
    VALUES ('DEMO Городской отель', 3, 'Центральная улица, 8', 95.00, 'Турция')
    RETURNING hotel_id INTO city_hotel_id;

    INSERT INTO public."Agencies" (agency_name, quality_rating)
    VALUES ('DEMO Культурные маршруты', 4.60)
    RETURNING agency_id INTO agency_id_value;

    INSERT INTO public."Tourist Information" (
        tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
        tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
    )
    VALUES ('Анна', 'Соколова', 'Игоревна', DATE '1988-03-14', 'Женский', 'Да', 'Нет', october_flight_id, 'Отдых', TRUE)
    RETURNING tourist_id INTO tourist_anna_id;

    INSERT INTO public."Tourist Information" (
        tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
        tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
    )
    VALUES ('Сергей', 'Волков', 'Петрович', DATE '1979-07-22', 'Мужской', 'Нет', 'Да', october_flight_id, 'Шоп-тур', TRUE)
    RETURNING tourist_id INTO tourist_sergey_id;

    INSERT INTO public."Tourist Information" (
        tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
        tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
    )
    VALUES ('Елена', 'Морозова', 'Андреевна', DATE '1994-11-02', 'Женский', 'Нет', 'Да', october_flight_id, 'Шоп-тур', TRUE)
    RETURNING tourist_id INTO tourist_elena_id;

    INSERT INTO public."Tourist Information" (
        tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
        tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
    )
    VALUES ('Михаил', 'Орлов', 'Сергеевич', DATE '1985-01-30', 'Мужской', 'Да', 'Нет', november_flight_id, 'Отдых', TRUE)
    RETURNING tourist_id INTO tourist_mikhail_id;

    INSERT INTO public."Tourist Information" (
        tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
        tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
    )
    VALUES ('Ольга', 'Кузнецова', 'Романовна', DATE '1991-06-18', 'Женский', 'Нет', 'Да', november_flight_id, 'Шоп-тур', TRUE)
    RETURNING tourist_id INTO tourist_olga_id;

    INSERT INTO public."Tourist Information" (
        tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
        tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
    )
    VALUES ('Павел', 'Федоров', 'Алексеевич', DATE '1982-09-09', 'Мужской', 'Нет', 'Да', november_flight_id, 'Шоп-тур', FALSE)
    RETURNING tourist_id INTO tourist_pavel_id;

    INSERT INTO public."Tourist's Passport Details" (
        tourist_id, type_passport, passport_serial, passport_number, date_of_issue,
        issued_by, latin_name, expiry_date, department_code, registration_address
    )
    VALUES
        (tourist_anna_id, 'Заграничный', 'DEMO', 'DEMO1010', DATE '2020-05-10', 'DEMO орган выдачи', 'ANNA SOKOLOVA', DATE '2030-05-10', 'DEMO-101', 'Demo address 10'),
        (tourist_sergey_id, 'Заграничный', 'DEMO', 'DEMO1011', DATE '2019-08-21', 'DEMO орган выдачи', 'SERGEY VOLKOV', DATE '2029-08-21', 'DEMO-102', 'Demo address 11'),
        (tourist_elena_id, 'Заграничный', 'DEMO', 'DEMO1012', DATE '2021-02-13', 'DEMO орган выдачи', 'ELENA MOROZOVA', DATE '2031-02-13', 'DEMO-103', 'Demo address 12'),
        (tourist_mikhail_id, 'Заграничный', 'DEMO', 'DEMO1101', DATE '2018-04-04', 'DEMO орган выдачи', 'MIKHAIL ORLOV', DATE '2028-04-04', 'DEMO-104', 'Demo address 13'),
        (tourist_olga_id, 'Заграничный', 'DEMO', 'DEMO1102', DATE '2022-10-01', 'DEMO орган выдачи', 'OLGA KUZNETSOVA', DATE '2032-10-01', 'DEMO-105', 'Demo address 14'),
        (tourist_pavel_id, 'Заграничный', 'DEMO', 'DEMO1103', DATE '2021-11-16', 'DEMO орган выдачи', 'PAVEL FEDOROV', DATE '2031-11-16', 'DEMO-106', 'Demo address 15');

    INSERT INTO public."Tourist Children" (
        tourist_id, first_name, last_name, patronymic, date_of_birth, gender,
        birth_certificate_number, date_of_issue, issued_by
    )
    VALUES
        (tourist_anna_id, 'Ирина', 'Соколова', NULL, DATE '2016-05-20', 'Женский', 'DEMO-CHILD-101', DATE '2016-05-25', 'DEMO орган регистрации'),
        (tourist_mikhail_id, 'Артем', 'Орлов', NULL, DATE '2017-12-11', 'Мужской', 'DEMO-CHILD-102', DATE '2017-12-15', 'DEMO орган регистрации');

    INSERT INTO public."Bookings" (tourist_id, hotel_id, check_in_date, check_out_date, room_number)
    VALUES
        (tourist_anna_id, coast_hotel_id, DATE '2026-10-15', DATE '2026-10-22', '201'),
        (tourist_sergey_id, city_hotel_id, DATE '2026-10-15', DATE '2026-10-20', '305'),
        (tourist_elena_id, city_hotel_id, DATE '2026-10-15', DATE '2026-10-21', '306'),
        (tourist_mikhail_id, coast_hotel_id, DATE '2026-11-06', DATE '2026-11-13', '202'),
        (tourist_olga_id, city_hotel_id, DATE '2026-11-06', DATE '2026-11-11', '307'),
        (tourist_pavel_id, city_hotel_id, DATE '2026-11-06', DATE '2026-11-12', '308');

    INSERT INTO public."Tourist Visits" (tourist_id, flight_id, arrival_date, departure_date)
    VALUES
        (tourist_anna_id, october_flight_id, DATE '2026-10-15', DATE '2026-10-22'),
        (tourist_sergey_id, october_flight_id, DATE '2026-10-15', DATE '2026-10-20'),
        (tourist_elena_id, october_flight_id, DATE '2026-10-15', DATE '2026-10-21'),
        (tourist_mikhail_id, november_flight_id, DATE '2026-11-06', DATE '2026-11-13'),
        (tourist_olga_id, november_flight_id, DATE '2026-11-06', DATE '2026-11-11'),
        (tourist_pavel_id, november_flight_id, DATE '2026-11-06', DATE '2026-11-12');

    INSERT INTO public."Tourist Cargo" (
        tourist_id, cargo_type, places_count, actual_weight, volume_weight, marking,
        tags, packaging_cost, insurance_cost, total_amount, flight_id
    )
    VALUES
        (tourist_sergey_id, 'Текстиль', 3, 34.00, 38.50, 'DEMO-OCT-01', 'DEMO-OCT-001, DEMO-OCT-002, DEMO-OCT-003', 30.00, 18.00, 48.00, october_flight_id),
        (tourist_elena_id, 'Электроника', 2, 19.50, 22.00, 'DEMO-OCT-02', 'DEMO-OCT-004, DEMO-OCT-005', 22.00, 24.00, 46.00, october_flight_id),
        (tourist_olga_id, 'Текстиль', 4, 41.00, 45.00, 'DEMO-NOV-01', 'DEMO-NOV-001, DEMO-NOV-002, DEMO-NOV-003, DEMO-NOV-004', 40.00, 25.00, 65.00, november_flight_id),
        (tourist_pavel_id, 'Сувениры', 2, 16.00, 14.50, 'DEMO-NOV-02', 'DEMO-NOV-005, DEMO-NOV-006', 18.00, 12.00, 30.00, november_flight_id);

    INSERT INTO public."Excursions" (agency_id, excursion_name, schedule_date, price)
    VALUES (agency_id_value, 'DEMO: Античный город и музей', TIMESTAMPTZ '2026-10-17 09:00:00+03', 65.00)
    RETURNING excursion_id INTO october_excursion_id;

    INSERT INTO public."Excursions" (agency_id, excursion_name, schedule_date, price)
    VALUES (agency_id_value, 'DEMO: Прогулка по старому городу', TIMESTAMPTZ '2026-11-08 10:00:00+03', 45.00)
    RETURNING excursion_id INTO november_excursion_id;

    INSERT INTO public."Excursion Bookings" (tourist_id, excursion_id)
    VALUES
        (tourist_anna_id, october_excursion_id),
        (tourist_sergey_id, october_excursion_id),
        (tourist_mikhail_id, november_excursion_id),
        (tourist_olga_id, november_excursion_id);

    INSERT INTO public."Finances" (transaction_type, category, amount, transaction_date, description)
    VALUES
        ('Доход', 'Экскурсии', 130.00, DATE '2026-10-17', 'DEMO: две оплаты экскурсии в октябре'),
        ('Расход', 'Гостиница', 520.00, DATE '2026-10-15', 'DEMO: размещение октябрьской группы'),
        ('Доход', 'Упаковка и страхование', 94.00, DATE '2026-10-15', 'DEMO: услуги по грузу октябрьской группы'),
        ('Расход', 'Трансфер', 110.00, DATE '2026-10-15', 'DEMO: трансфер октябрьской группы'),
        ('Доход', 'Экскурсии', 110.00, DATE '2026-11-08', 'DEMO: две оплаты экскурсии в ноябре'),
        ('Расход', 'Гостиница', 610.00, DATE '2026-11-06', 'DEMO: размещение ноябрьской группы'),
        ('Доход', 'Упаковка и страхование', 141.00, DATE '2026-11-06', 'DEMO: услуги по грузу ноябрьской группы'),
        ('Расход', 'Аэропортовые услуги', 85.00, DATE '2026-11-06', 'DEMO: аэропортовое обслуживание ноябрьской группы');
END;
$$;

INSERT INTO public."Finances" (transaction_type, category, amount, transaction_date, description)
SELECT 'Доход', 'Продажа путевок', 2100.00, DATE '2026-10-15', 'DEMO: продажа трех октябрьских турпакетов'
WHERE NOT EXISTS (
    SELECT 1 FROM public."Finances"
    WHERE description = 'DEMO: продажа трех октябрьских турпакетов'
);

INSERT INTO public."Finances" (transaction_type, category, amount, transaction_date, description)
SELECT 'Доход', 'Продажа путевок', 2400.00, DATE '2026-11-06', 'DEMO: продажа трех ноябрьских турпакетов'
WHERE NOT EXISTS (
    SELECT 1 FROM public."Finances"
    WHERE description = 'DEMO: продажа трех ноябрьских турпакетов'
);

SELECT 'demo_flights' AS entity, COUNT(*) AS records
FROM public."Flights"
WHERE flight_number IN ('DEMO-TF-2026', 'DEMO-TF-OCT-2026', 'DEMO-TF-NOV-2026')
UNION ALL
SELECT 'demo_tourists', COUNT(*)
FROM public."Tourist Information" t
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number LIKE 'DEMO-TF-%'
UNION ALL
SELECT 'demo_bookings', COUNT(*)
FROM public."Bookings" b
JOIN public."Tourist Information" t ON t.tourist_id = b.tourist_id
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number LIKE 'DEMO-TF-%'
UNION ALL
SELECT 'demo_cargo', COUNT(*)
FROM public."Tourist Cargo" c
JOIN public."Flights" f ON f.flight_id = c.flight_id
WHERE f.flight_number LIKE 'DEMO-TF-%'
UNION ALL
SELECT 'demo_excursion_bookings', COUNT(*)
FROM public."Excursion Bookings" eb
JOIN public."Tourist Information" t ON t.tourist_id = eb.tourist_id
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number LIKE 'DEMO-TF-%'
UNION ALL
SELECT 'demo_finances', COUNT(*)
FROM public."Finances"
WHERE description LIKE 'DEMO:%';
