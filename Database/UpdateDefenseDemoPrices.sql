-- One-time update of the original ResetAndSeedDefenseDemo.sql dataset.
-- Does not reset the database. If any monetary rows differ, nothing is changed.
BEGIN;

LOCK TABLE public."Tour Packages", public."Tour Package Sales", public."Hotels",
    public."Excursions", public."Tourist Cargo", public."Finances",
    public."Flights", public."Tourist Information" IN SHARE ROW EXCLUSIVE MODE;

CREATE TEMP TABLE demo_package_prices (code TEXT PRIMARY KEY, old_price NUMERIC, new_price NUMERIC) ON COMMIT DROP;
INSERT INTO demo_package_prices VALUES
    ('DEF-OCT-REST',920,115000), ('DEF-OCT-SHOP',640,78000),
    ('DEF-NOV-REST',870,105000), ('DEF-NOV-SHOP',590,69000),
    ('DEF-DEC-REST',1050,125000), ('DEF-DEC-SHOP',720,89000),
    ('DEF-UNSOLD',1180,135000);

CREATE TEMP TABLE demo_hotel_prices (name TEXT PRIMARY KEY, old_price NUMERIC, new_price NUMERIC) ON COMMIT DROP;
INSERT INTO demo_hotel_prices VALUES
    ('Лазурный берег',168,14500), ('Старый город',124,9800),
    ('Босфор Палас',195,16900), ('Сити Гарден',96,7600);

CREATE TEMP TABLE demo_excursion_prices (name TEXT PRIMARY KEY, old_price NUMERIC, new_price NUMERIC) ON COMMIT DROP;
INSERT INTO demo_excursion_prices VALUES
    ('Калеичи: старый город и гавань',78,5500),
    ('Водопады Дюден и побережье',92,6800),
    ('Стамбул: Босфор и исторический центр',105,7900),
    ('Принцевы острова и морская прогулка',118,8500),
    ('Перге и Аспендос: наследие античности',112,8200),
    ('Термальные источники и каньон',98,7200);

CREATE TEMP TABLE demo_cargo_prices (marking TEXT PRIMARY KEY, old_pack NUMERIC, old_ins NUMERIC, new_pack NUMERIC, new_ins NUMERIC) ON COMMIT DROP;
INSERT INTO demo_cargo_prices VALUES
    ('Партия DEF401-A',32,18,2800,1500), ('Партия DEF401-B',24,15,2200,1300),
    ('Партия DEF512-A',38,24,3200,1900), ('Партия DEF512-B',28,42,2600,3800),
    ('Партия DEF520-A',55,35,4800,2800), ('Партия DEF520-B',36,28,3100,2400),
    ('Партия DEF520-C',40,25,3500,2100), ('Партия DEF520-D',18,16,1700,1400),
    ('Партия DEF604-A',30,21,2700,1800), ('Партия DEF604-B',22,19,2000,1600),
    ('Партия DEF604-C',44,52,3900,4500), ('Партия DEF401-C',25,17,2300,1400);

CREATE TEMP TABLE demo_expense_prices (flight TEXT, category TEXT, old_price NUMERIC, new_price NUMERIC, PRIMARY KEY (flight, category)) ON COMMIT DROP;
INSERT INTO demo_expense_prices VALUES
    ('DEF-401','Размещение группы',1860,185000), ('DEF-512','Размещение группы',2140,210000),
    ('DEF-520','Размещение группы',980,85000), ('DEF-604','Размещение группы',2280,225000),
    ('DEF-218','Размещение группы',1420,135000),
    ('DEF-401','Трансфер',220,24000), ('DEF-512','Трансфер',245,28000),
    ('DEF-520','Трансфер',180,21000), ('DEF-604','Трансфер',260,30000),
    ('DEF-218','Трансфер',190,20000),
    ('DEF-401','Аэропортовые услуги',145,16000), ('DEF-512','Аэропортовые услуги',190,22000),
    ('DEF-520','Аэропортовые услуги',310,35000), ('DEF-604','Аэропортовые услуги',205,23000),
    ('DEF-218','Аэропортовые услуги',130,15000);

CREATE TEMP TABLE demo_finance_updates (transaction_id INTEGER PRIMARY KEY, new_amount NUMERIC NOT NULL) ON COMMIT DROP;
INSERT INTO demo_finance_updates
SELECT f.transaction_id, m.new_price
FROM public."Finances" f
JOIN public."Tour Package Sales" s
  ON s.tourist_id = f.tourist_id AND s.flight_id = f.flight_id AND s.sold_date = f.transaction_date
JOIN public."Tour Packages" p ON p.package_id = s.package_id
JOIN demo_package_prices m ON m.code = p.package_code AND s.sale_price = m.old_price
JOIN public."Tourist Information" t ON t.tourist_id = s.tourist_id
WHERE f.transaction_type = 'Доход' AND f.category = 'Продажа путевки'
  AND f.amount = s.sale_price
  AND f.description = 'Демонстрационная продажа: ' || p.package_name || ' (' || t.tourist_name || ' ' || t.tourist_surname || ')';

INSERT INTO demo_finance_updates
SELECT f.transaction_id, m.new_price
FROM public."Finances" f
JOIN demo_excursion_prices m ON f.description = 'Демонстрационная запись на экскурсию: ' || m.name
WHERE f.transaction_type = 'Доход' AND f.category = 'Экскурсионное обслуживание' AND f.amount = m.old_price;

INSERT INTO demo_finance_updates
SELECT f.transaction_id, m.new_pack + m.new_ins
FROM public."Finances" f
JOIN public."Tourist Cargo" c ON c.tourist_id = f.tourist_id AND c.flight_id = f.flight_id
JOIN public."Flights" flight ON flight.flight_id = c.flight_id AND flight.flight_date::DATE = f.transaction_date
JOIN demo_cargo_prices m ON m.marking = c.marking
WHERE f.transaction_type = 'Доход' AND f.category = 'Упаковка и страхование'
  AND f.description = 'Демонстрационные складские услуги: ' || c.marking
  AND c.packaging_cost = m.old_pack AND c.insurance_cost = m.old_ins
  AND c.total_amount = m.old_pack + m.old_ins AND f.amount = c.total_amount;

INSERT INTO demo_finance_updates
SELECT f.transaction_id, m.new_price
FROM public."Finances" f
JOIN public."Flights" flight ON flight.flight_id = f.flight_id
JOIN demo_expense_prices m ON m.flight = flight.flight_number AND m.category = f.category
WHERE f.transaction_type = 'Расход' AND f.tourist_id IS NULL AND f.amount = m.old_price
  AND f.transaction_date = flight.flight_date::DATE
  AND f.description = 'Демонстрационные расходы группы рейса ' || flight.flight_number || ': ' || f.category;

DO $$
BEGIN
    IF current_database() <> 'Touristic Firma' THEN
        RAISE EXCEPTION 'Ожидалась база Touristic Firma; изменения отменены.';
    END IF;
    IF (SELECT COUNT(*) FROM public."Tour Packages") <> 7
       OR (SELECT COUNT(*) FROM public."Tour Packages" p JOIN demo_package_prices m ON m.code = p.package_code AND m.old_price = p.price) <> 7
       OR (SELECT COUNT(*) FROM public."Hotels") <> 4
       OR (SELECT COUNT(*) FROM public."Hotels" h JOIN demo_hotel_prices m ON m.name = h.hotel_name AND m.old_price = h.price_per_night) <> 4
       OR (SELECT COUNT(*) FROM public."Excursions") <> 6
       OR (SELECT COUNT(*) FROM public."Excursions" e JOIN demo_excursion_prices m ON m.name = e.excursion_name AND m.old_price = e.price) <> 6
       OR (SELECT COUNT(*) FROM public."Tourist Cargo") <> 12
       OR (SELECT COUNT(*) FROM public."Tourist Cargo" c JOIN demo_cargo_prices m ON m.marking = c.marking
           AND c.packaging_cost = m.old_pack AND c.insurance_cost = m.old_ins AND c.total_amount = m.old_pack + m.old_ins) <> 12
       OR (SELECT COUNT(*) FROM public."Tour Package Sales") <> 22
       OR (SELECT COUNT(*) FROM public."Tour Package Sales" s
           JOIN public."Tour Packages" p ON p.package_id = s.package_id
           JOIN demo_package_prices m ON m.code = p.package_code AND s.sale_price = m.old_price
           JOIN public."Flights" flight ON flight.flight_id = s.flight_id AND s.sold_date = flight.flight_date::DATE - 3) <> 22
       OR (SELECT COUNT(*) FROM public."Finances") <> 65
       OR (SELECT COUNT(*) FROM demo_finance_updates) <> 65 THEN
        RAISE EXCEPTION 'Демонстрационные денежные данные отличаются от исходного набора; изменения отменены. Необходимо проверить записи вручную.';
    END IF;
END;
$$;

UPDATE public."Tour Packages" p SET price = m.new_price FROM demo_package_prices m WHERE p.package_code = m.code;
UPDATE public."Tour Package Sales" s SET sale_price = m.new_price
FROM public."Tour Packages" p JOIN demo_package_prices m ON m.code = p.package_code
WHERE s.package_id = p.package_id;
UPDATE public."Hotels" h SET price_per_night = m.new_price FROM demo_hotel_prices m WHERE h.hotel_name = m.name;
UPDATE public."Excursions" e SET price = m.new_price FROM demo_excursion_prices m WHERE e.excursion_name = m.name;
UPDATE public."Tourist Cargo" c SET packaging_cost = m.new_pack, insurance_cost = m.new_ins,
    total_amount = m.new_pack + m.new_ins FROM demo_cargo_prices m WHERE c.marking = m.marking;
UPDATE public."Finances" f SET amount = m.new_amount FROM demo_finance_updates m WHERE f.transaction_id = m.transaction_id;

COMMIT;
