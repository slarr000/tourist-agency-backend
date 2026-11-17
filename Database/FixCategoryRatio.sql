-- Report 14: count each tourist once, based on visit arrival dates when a period is provided.
BEGIN;

CREATE OR REPLACE FUNCTION public.gettouristscategoryratio(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    holiday_count BIGINT,
    shop_tour_count BIGINT,
    total_tourists BIGINT,
    holiday_percentage NUMERIC,
    shop_tour_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(CASE WHEN t.category = 'Отдых' THEN 1 END)::BIGINT,
        COUNT(CASE WHEN t.category = 'Шоп-тур' THEN 1 END)::BIGINT,
        COUNT(t.tourist_id)::BIGINT,
        COALESCE(ROUND(COUNT(CASE WHEN t.category = 'Отдых' THEN 1 END) * 100.0 / NULLIF(COUNT(t.tourist_id), 0), 2), 0)::NUMERIC,
        COALESCE(ROUND(COUNT(CASE WHEN t.category = 'Шоп-тур' THEN 1 END) * 100.0 / NULLIF(COUNT(t.tourist_id), 0), 2), 0)::NUMERIC
    FROM public."Tourist Information" t
    WHERE (p_start_date IS NULL AND p_end_date IS NULL)
       OR EXISTS (
           SELECT 1
           FROM public."Tourist Visits" v
           WHERE v.tourist_id = t.tourist_id
             AND (p_start_date IS NULL OR v.arrival_date >= p_start_date)
             AND (p_end_date IS NULL OR v.arrival_date <= p_end_date)
       );
END;
$$;

COMMIT;
