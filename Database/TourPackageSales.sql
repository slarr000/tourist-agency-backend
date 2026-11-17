-- Historical sale prices remain unknown; no existing rows are changed.
-- Apply DocumentEvents.sql before this script.
BEGIN;

ALTER TABLE public."Tour Package Sales"
    ADD COLUMN IF NOT EXISTS sale_price NUMERIC(12, 2);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_tour_package_sale_price'
                   AND conrelid = 'public."Tour Package Sales"'::regclass) THEN
        ALTER TABLE public."Tour Package Sales"
            ADD CONSTRAINT ck_tour_package_sale_price CHECK (sale_price >= 0);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.app_entity_info(p_entity TEXT)
RETURNS TABLE (table_name TEXT, id_column TEXT)
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT mapping.table_name, mapping.id_column
    FROM (VALUES
        ('agency', 'Agencies', 'agency_id'),
        ('booking', 'Bookings', 'booking_id'),
        ('child_visit', 'Child Visits', 'child_visit_id'),
        ('child_booking', 'Child Bookings', 'child_booking_id'),
        ('document_event', 'Document Events', 'document_event_id'),
        ('excursion_booking', 'Excursion Bookings', 'booking_id'),
        ('excursion', 'Excursions', 'excursion_id'),
        ('finance', 'Finances', 'transaction_id'),
        ('flight', 'Flights', 'flight_id'),
        ('hotel', 'Hotels', 'hotel_id'),
        ('passport', 'Tourist''s Passport Details', 'passport_id'),
        ('tour_package', 'Tour Packages', 'package_id'),
        ('tour_package_sale', 'Tour Package Sales', 'sale_id'),
        ('tourist_cargo', 'Tourist Cargo', 'cargo_id'),
        ('tourist_child', 'Tourist Children', 'child_id'),
        ('tourist', 'Tourist Information', 'tourist_id'),
        ('tourist_visit', 'Tourist Visits', 'visit_id'),
        ('tourist_directory', 'Tourists', 'Id')
    ) AS mapping(entity, table_name, id_column)
    WHERE mapping.entity = lower(p_entity);
$$;

CREATE OR REPLACE FUNCTION public.coursework_monthly_business_report(
    p_year INTEGER, p_month INTEGER
)
RETURNS TABLE (
    year INTEGER, month INTEGER, sold_vouchers BIGINT, issued_passports BIGINT,
    visas_processed BIGINT, child_documents_processed BIGINT, total_documents BIGINT,
    voucher_revenue NUMERIC, most_demanded_packages TEXT[], packages_without_sales TEXT[]
)
LANGUAGE sql
STABLE
AS $$
    WITH bounds AS (
        SELECT MAKE_DATE(p_year, p_month, 1) AS month_start,
               (MAKE_DATE(p_year, p_month, 1) + INTERVAL '1 month')::DATE AS next_month
    ),
    sales AS (
        SELECT s.package_id, p.package_name, s.sale_price
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
        SELECT COUNT(*) FILTER (WHERE e.document_type = 'Паспортные документы')::BIGINT AS passport_count,
               COUNT(*) FILTER (WHERE e.document_type = 'Виза')::BIGINT AS visa_count,
               COUNT(*) FILTER (WHERE e.document_type = 'Документ ребёнка')::BIGINT AS child_document_count
        FROM public."Document Events" e
        CROSS JOIN bounds b
        WHERE e.processed_date >= b.month_start AND e.processed_date < b.next_month
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
            ARRAY_AGG(d.package_name || ' — мест: ' || d.monthly_capacity ORDER BY d.package_name)
            FILTER (WHERE d.sold_count = 0), ARRAY[]::TEXT[]
        ) AS unsold_packages
        FROM package_demand d
    )
    SELECT p_year, p_month, (SELECT COUNT(*)::BIGINT FROM sales),
           documents.passport_count, documents.visa_count, documents.child_document_count,
           (documents.passport_count + documents.visa_count + documents.child_document_count)::BIGINT,
           CASE WHEN EXISTS (SELECT 1 FROM sales WHERE sale_price IS NULL) THEN NULL
                ELSE COALESCE((SELECT SUM(sale_price) FROM sales), 0)::NUMERIC END,
           demand.most_demanded, unsold.unsold_packages
    FROM documents CROSS JOIN demand CROSS JOIN unsold;
$$;

CREATE OR REPLACE FUNCTION public.coursework_monthly_business_report_complete(
    p_year INTEGER, p_month INTEGER
)
RETURNS TABLE (
    year INTEGER, month INTEGER, sold_vouchers BIGINT, issued_passports BIGINT,
    visas_processed BIGINT, child_documents_processed BIGINT, total_documents BIGINT,
    voucher_revenue NUMERIC, total_revenue NUMERIC, total_expenses NUMERIC, net_profit NUMERIC,
    most_demanded_packages TEXT[], packages_without_sales TEXT[]
)
LANGUAGE sql
STABLE
AS $$
    WITH bounds AS (
        SELECT MAKE_DATE(p_year, p_month, 1) AS month_start,
               (MAKE_DATE(p_year, p_month, 1) + INTERVAL '1 month')::DATE AS next_month
    ),
    finances AS (
        SELECT COALESCE(SUM(f.amount) FILTER (WHERE f.transaction_type = 'Доход'), 0)::NUMERIC AS total_revenue,
               COALESCE(SUM(f.amount) FILTER (WHERE f.transaction_type = 'Расход'), 0)::NUMERIC AS total_expenses
        FROM public."Finances" f
        CROSS JOIN bounds b
        WHERE f.transaction_date >= b.month_start AND f.transaction_date < b.next_month
    )
    SELECT report.year, report.month, report.sold_vouchers, report.issued_passports,
           report.visas_processed, report.child_documents_processed, report.total_documents,
           report.voucher_revenue, finances.total_revenue, finances.total_expenses,
           finances.total_revenue - finances.total_expenses,
           report.most_demanded_packages, report.packages_without_sales
    FROM public.coursework_monthly_business_report(p_year, p_month) report
    CROSS JOIN finances;
$$;

COMMIT;
