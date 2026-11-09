-- Добавляет небольшую демонстрационную группу для проверки отчетов.
-- Повторный запуск не дублирует данные: запись рейса выступает маркером набора.

DO $$
DECLARE
    demo_flight_id INTEGER;
    hotel_id_value INTEGER;
    agency_id_value INTEGER;
    tourist_rest_id INTEGER;
    tourist_shop_id INTEGER;
    excursion_id_value INTEGER;
BEGIN
    SELECT flight_id INTO demo_flight_id
    FROM public."Flights"
    WHERE flight_number = 'DEMO-TF-2026';

    IF demo_flight_id IS NOT NULL THEN
        RAISE NOTICE 'Демо-набор уже существует; вставка пропущена.';
        RETURN;
    END IF;

    INSERT INTO public."Flights" (flight_number, flight_date, aircraft_type, flight_type)
    VALUES ('DEMO-TF-2026', DATE '2026-09-15', 'Airbus A320', 'Пассажирский')
    RETURNING flight_id INTO demo_flight_id;

    INSERT INTO public."Hotels" (hotel_name, stars_count, address, price_per_night, country)
    VALUES ('DEMO Отель', 4, 'Demo Street 10', 120.00, 'Турция')
    RETURNING hotel_id INTO hotel_id_value;

    INSERT INTO public."Agencies" (agency_name, quality_rating)
    VALUES ('DEMO Экскурсионное агентство', 4.80)
    RETURNING agency_id INTO agency_id_value;

    INSERT INTO public."Tourist Information" (
        tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
        tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
    )
    VALUES (
        'Анна', 'Демонстрационная', NULL, DATE '1990-04-12',
        'Женский', 'Да', 'Нет', demo_flight_id, 'Отдых', TRUE
    )
    RETURNING tourist_id INTO tourist_rest_id;

    INSERT INTO public."Tourist Information" (
        tourist_name, tourist_surname, tourist_patronymic, tourist_date_of_birth,
        tourist_gender, tourist_children, tourist_cargo, flight_id, category, has_visa
    )
    VALUES (
        'Иван', 'Тестовый', NULL, DATE '1985-08-20',
        'Мужской', 'Нет', 'Да', demo_flight_id, 'Шоп-тур', TRUE
    )
    RETURNING tourist_id INTO tourist_shop_id;

    INSERT INTO public."Tourist Children" (
        tourist_id, first_name, last_name, patronymic, date_of_birth, gender,
        birth_certificate_number, date_of_issue, issued_by
    )
    VALUES (
        tourist_rest_id, 'Маша', 'Демонстрационная', NULL, DATE '2018-03-05', 'Женский',
        'DEMO-CHILD-001', DATE '2018-03-10', 'DEMO орган регистрации'
    );

    INSERT INTO public."Tourist's Passport Details" (
        tourist_id, type_passport, passport_serial, passport_number, date_of_issue,
        issued_by, latin_name, expiry_date, department_code, registration_address
    )
    VALUES
        (tourist_rest_id, 'Заграничный', 'DEMO', 'DEMO0001', DATE '2020-01-15',
         'DEMO орган выдачи', 'ANNA DEMO', DATE '2030-01-15', 'DEMO-001', 'Demo address 1'),
        (tourist_shop_id, 'Заграничный', 'DEMO', 'DEMO0002', DATE '2021-02-20',
         'DEMO орган выдачи', 'IVAN TEST', DATE '2031-02-20', 'DEMO-002', 'Demo address 2');

    INSERT INTO public."Bookings" (
        tourist_id, hotel_id, check_in_date, check_out_date, room_number
    )
    VALUES
        (tourist_rest_id, hotel_id_value, DATE '2026-09-15', DATE '2026-09-22', '101A'),
        (tourist_shop_id, hotel_id_value, DATE '2026-09-15', DATE '2026-09-20', '102B');

    INSERT INTO public."Tourist Visits" (tourist_id, flight_id, arrival_date, departure_date)
    VALUES
        (tourist_rest_id, demo_flight_id, DATE '2026-09-15', DATE '2026-09-22'),
        (tourist_shop_id, demo_flight_id, DATE '2026-09-15', DATE '2026-09-20');

    INSERT INTO public."Tourist Cargo" (
        tourist_id, cargo_type, places_count, actual_weight, volume_weight, marking,
        tags, packaging_cost, insurance_cost, total_amount, flight_id
    )
    VALUES (
        tourist_shop_id, 'Текстиль', 2, 28.50, 31.00, 'DEMO-MARK-01',
        'DEMO-TAG-01, DEMO-TAG-02', 20.00, 15.00, 35.00, demo_flight_id
    );

    INSERT INTO public."Excursions" (agency_id, excursion_name, schedule_date, price)
    VALUES (agency_id_value, 'DEMO: Экскурсия по старому городу', TIMESTAMPTZ '2026-09-17 09:00:00+03', 75.00)
    RETURNING excursion_id INTO excursion_id_value;

    INSERT INTO public."Excursion Bookings" (tourist_id, excursion_id)
    VALUES (tourist_rest_id, excursion_id_value);

    INSERT INTO public."Finances" (
        transaction_type, category, amount, transaction_date, description
    )
    VALUES
        ('Доход', 'Экскурсии', 75.00, DATE '2026-09-17', 'DEMO: оплата экскурсии'),
        ('Расход', 'Гостиница', 240.00, DATE '2026-09-15', 'DEMO: проживание группы');
END;
$$;

SELECT 'tourists' AS entity, COUNT(*) AS records
FROM public."Tourist Information" t
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number = 'DEMO-TF-2026'
UNION ALL
SELECT 'bookings', COUNT(*)
FROM public."Bookings" b
JOIN public."Tourist Information" t ON t.tourist_id = b.tourist_id
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number = 'DEMO-TF-2026'
UNION ALL
SELECT 'cargo', COUNT(*)
FROM public."Tourist Cargo" c
JOIN public."Flights" f ON f.flight_id = c.flight_id
WHERE f.flight_number = 'DEMO-TF-2026'
UNION ALL
SELECT 'excursions', COUNT(*)
FROM public."Excursions" e
JOIN public."Excursion Bookings" eb ON eb.excursion_id = e.excursion_id
JOIN public."Tourist Information" t ON t.tourist_id = eb.tourist_id
JOIN public."Flights" f ON f.flight_id = t.flight_id
WHERE f.flight_number = 'DEMO-TF-2026';
