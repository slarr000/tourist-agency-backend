-- Проверка совместимости PostgreSQL-структуры с текущим ASP.NET backend
-- Запускать в pgAdmin Query Tool после создания базы "Touristic Firma"

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Ключевые таблицы и колонки, которые ждёт backend
SELECT 'Bookings', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Bookings'
UNION ALL
SELECT 'Flights', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Flights'
UNION ALL
SELECT 'Hotels', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Hotels'
UNION ALL
SELECT 'Tourist Information', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Tourist Information'
UNION ALL
SELECT 'Tourist Cargo', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Tourist Cargo'
UNION ALL
SELECT 'Finances', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Finances'
UNION ALL
SELECT 'Excursions', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Excursions'
UNION ALL
SELECT 'Excursion Bookings', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Excursion Bookings'
UNION ALL
SELECT 'Tourist Visits', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Tourist Visits'
UNION ALL
SELECT 'Tourist''s Passport Details', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Tourist''s Passport Details'
UNION ALL
SELECT 'Tourist Children', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'Tourist Children'
ORDER BY table_name, column_name;

-- Проверка, что в Touristic system есть данные, которые можно вывести
SELECT COUNT(*) AS tourists_count FROM public."Tourist Information";
SELECT COUNT(*) AS bookings_count FROM public."Bookings";
SELECT COUNT(*) AS flights_count FROM public."Flights";
SELECT COUNT(*) AS hotels_count FROM public."Hotels";

-- Расширения отчетности по ТЗ: вместимость рейса, привязка финансов
-- к группе/туристу и учет проданных/невостребованных путевок.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (
      (table_name = 'Flights' AND column_name = 'seat_capacity')
      OR (table_name = 'Finances' AND column_name IN ('flight_id', 'tourist_id'))
  )
ORDER BY table_name, column_name;

SELECT
    to_regclass('public."Tour Packages"') AS tour_packages_table,
    to_regclass('public."Tour Package Sales"') AS tour_package_sales_table;
