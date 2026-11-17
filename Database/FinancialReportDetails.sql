-- Financial reports: explicit allocations and unallocated amounts.
BEGIN;

CREATE OR REPLACE PROCEDURE public.coursework_financial_report_details(
    IN p_start_date DATE, IN p_end_date DATE, IN p_flight_id INTEGER,
    IN p_category TEXT, INOUT p_result JSONB
)
LANGUAGE plpgsql AS $$
DECLARE
    v_category TEXT := NULLIF(BTRIM(p_category), '');
BEGIN
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_start_date > p_end_date
       OR p_flight_id < 1 OR (v_category IS NOT NULL AND v_category NOT IN ('Отдых', 'Шоп-тур')) THEN
        RAISE EXCEPTION 'Invalid financial report parameters' USING ERRCODE = '22023';
    END IF;

    WITH group_members AS (
        SELECT flight_id, tourist_id FROM public."Tourist Information" WHERE flight_id IS NOT NULL
        UNION
        SELECT flight_id, tourist_id FROM public."Tourist Visits" WHERE flight_id IS NOT NULL
    ), group_counts AS (
        SELECT m.flight_id, COUNT(*)::NUMERIC AS total,
               COUNT(*) FILTER (WHERE t.category = v_category)::NUMERIC AS matching,
               COUNT(*) FILTER (WHERE t.category IS NULL OR t.category NOT IN ('Отдых', 'Шоп-тур'))::NUMERIC AS unknown
        FROM group_members m
        JOIN public."Tourist Information" t ON t.tourist_id = m.tourist_id
        GROUP BY m.flight_id
    ), scoped AS (
        SELECT f.transaction_id, f.transaction_type::TEXT, f.category::TEXT, f.amount::NUMERIC,
               f.flight_id, f.tourist_id, t.category::TEXT AS tourist_category,
               g.total, g.matching, g.unknown
        FROM public."Finances" f
        LEFT JOIN public."Tourist Information" t ON t.tourist_id = f.tourist_id
        LEFT JOIN group_counts g ON g.flight_id = f.flight_id
        WHERE f.transaction_date BETWEEN p_start_date AND p_end_date
          AND (p_flight_id IS NULL OR f.flight_id = p_flight_id)
    ), allocated AS (
        SELECT s.*,
               CASE WHEN v_category IS NULL THEN s.amount
                    WHEN s.tourist_id IS NOT NULL THEN
                        CASE WHEN s.tourist_category = v_category THEN s.amount ELSE 0 END
                    WHEN s.total > 0 THEN s.amount * s.matching / s.total
                    ELSE 0 END AS allocated_amount,
               CASE WHEN v_category IS NULL THEN 0
                    WHEN s.tourist_id IS NOT NULL THEN
                        CASE WHEN s.tourist_category IS NULL OR s.tourist_category NOT IN ('Отдых', 'Шоп-тур')
                             THEN s.amount ELSE 0 END
                    WHEN s.total > 0 THEN s.amount * s.unknown / s.total
                    ELSE s.amount END AS unallocated_amount,
               CASE WHEN v_category IS NULL THEN TRUE
                    WHEN s.tourist_id IS NOT NULL THEN COALESCE(s.tourist_category = v_category, FALSE)
                    ELSE COALESCE(s.matching > 0, FALSE) END AS included
        FROM scoped s
    ), items AS (
        SELECT transaction_type, category, COUNT(*)::BIGINT AS transaction_count,
               ROUND(SUM(allocated_amount), 2)::NUMERIC AS amount
        FROM allocated WHERE included
        GROUP BY transaction_type, category
    ), totals AS (
        SELECT COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'Доход'), 0) AS income,
               COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'Расход'), 0) AS expense
        FROM items
    ), unallocated AS (
        SELECT ROUND(COALESCE(SUM(unallocated_amount) FILTER (WHERE transaction_type = 'Доход'), 0), 2) AS income,
               ROUND(COALESCE(SUM(unallocated_amount) FILTER (WHERE transaction_type = 'Расход'), 0), 2) AS expense,
               COUNT(*) FILTER (WHERE unallocated_amount <> 0)::BIGINT AS operation_count
        FROM allocated
    )
    SELECT JSONB_BUILD_OBJECT(
        'summary', JSONB_BUILD_OBJECT(
            'total_income', totals.income, 'total_expense', totals.expense,
            'net_profit', totals.income - totals.expense,
            'profitability_percent', CASE WHEN totals.expense = 0 THEN NULL
                ELSE ROUND((totals.income - totals.expense) * 100.0 / totals.expense, 2) END,
            'unallocated_income', unallocated.income, 'unallocated_expense', unallocated.expense,
            'unallocated_operation_count', unallocated.operation_count
        ),
        'items', COALESCE((SELECT JSONB_AGG(TO_JSONB(i) ORDER BY i.transaction_type, i.category) FROM items i), '[]'::JSONB)
    )
    INTO p_result FROM totals CROSS JOIN unallocated;
END;
$$;

CREATE OR REPLACE FUNCTION public.coursework_financial_items(
    p_start_date DATE, p_end_date DATE, p_flight_id INTEGER DEFAULT NULL, p_category TEXT DEFAULT NULL
)
RETURNS TABLE (transaction_type TEXT, category TEXT, transaction_count BIGINT, amount NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
    CALL public.coursework_financial_report_details(p_start_date, p_end_date, p_flight_id, p_category, v_result);
    RETURN QUERY SELECT i.transaction_type, i.category, i.transaction_count, i.amount
        FROM JSONB_TO_RECORDSET(v_result -> 'items')
            AS i(transaction_type TEXT, category TEXT, transaction_count BIGINT, amount NUMERIC);
END;
$$;

CREATE OR REPLACE FUNCTION public.coursework_financial_summary(
    p_start_date DATE, p_end_date DATE, p_flight_id INTEGER DEFAULT NULL, p_category TEXT DEFAULT NULL
)
RETURNS TABLE (total_income NUMERIC, total_expense NUMERIC, net_profit NUMERIC, profitability_percent NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
    CALL public.coursework_financial_report_details(p_start_date, p_end_date, p_flight_id, p_category, v_result);
    RETURN QUERY SELECT s.total_income, s.total_expense, s.net_profit, s.profitability_percent
        FROM JSONB_TO_RECORD(v_result -> 'summary')
            AS s(total_income NUMERIC, total_expense NUMERIC, net_profit NUMERIC, profitability_percent NUMERIC);
END;
$$;

COMMIT;
