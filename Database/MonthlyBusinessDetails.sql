-- Apply after TourPackageSales.sql. This procedure only reads existing data.
BEGIN;

CREATE OR REPLACE PROCEDURE public.coursework_monthly_business_details(
    IN p_year INTEGER, IN p_month INTEGER, INOUT p_result JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    month_start DATE;
    next_month DATE;
BEGIN
    IF p_year IS NULL OR p_month IS NULL OR p_year NOT BETWEEN 2000 AND 2100 OR p_month NOT BETWEEN 1 AND 12 THEN
        RAISE EXCEPTION 'Invalid reporting month' USING ERRCODE = '22023';
    END IF;
    month_start := MAKE_DATE(p_year, p_month, 1);
    next_month := (month_start + INTERVAL '1 month')::DATE;

    SELECT JSONB_BUILD_OBJECT(
        'summary', TO_JSONB(report),
        'sales', (
            SELECT COALESCE(JSONB_AGG(JSONB_BUILD_OBJECT(
                'sale_id', s.sale_id, 'sold_date', s.sold_date,
                'package_name', p.package_name, 'package_code', p.package_code,
                'tourist_name', CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic),
                'flight_number', f.flight_number, 'flight_date', f.flight_date,
                'sale_price', s.sale_price
            ) ORDER BY s.sold_date, s.sale_id), '[]'::JSONB)
            FROM public."Tour Package Sales" s
            JOIN public."Tour Packages" p ON p.package_id = s.package_id
            JOIN public."Tourist Information" t ON t.tourist_id = s.tourist_id
            JOIN public."Flights" f ON f.flight_id = s.flight_id
            WHERE s.sold_date >= month_start AND s.sold_date < next_month
        ),
        'documents', (
            SELECT COALESCE(JSONB_AGG(JSONB_BUILD_OBJECT(
                'document_event_id', e.document_event_id, 'processed_date', e.processed_date,
                'document_type', e.document_type,
                'tourist_name', CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic),
                'child_name', CASE WHEN c.child_id IS NOT NULL
                    THEN CONCAT_WS(' ', c.last_name, c.first_name, c.patronymic) ELSE NULL END
            ) ORDER BY e.processed_date, e.document_event_id), '[]'::JSONB)
            FROM public."Document Events" e
            JOIN public."Tourist Information" t ON t.tourist_id = e.tourist_id
            LEFT JOIN public."Tourist Children" c ON c.child_id = e.child_id AND c.tourist_id = e.tourist_id
            WHERE e.processed_date >= month_start AND e.processed_date < next_month
        )
    )
    INTO p_result
    FROM public.coursework_monthly_business_report_complete(p_year, p_month) report;
END;
$$;

COMMIT;
