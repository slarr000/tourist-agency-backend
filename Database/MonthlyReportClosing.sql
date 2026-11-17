-- Apply after TourPackageSales.sql and MonthlyBusinessDetails.sql.
BEGIN;

CREATE TABLE IF NOT EXISTS public."Monthly Report Versions" (
    report_year INTEGER NOT NULL CHECK (report_year BETWEEN 2000 AND 2100),
    report_month INTEGER NOT NULL CHECK (report_month BETWEEN 1 AND 12),
    version INTEGER NOT NULL CHECK (version > 0),
    closed_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    closed_by TEXT NOT NULL CHECK (length(btrim(closed_by)) > 0),
    reason TEXT,
    catalog JSONB NOT NULL CHECK (jsonb_typeof(catalog) = 'array'),
    report JSONB NOT NULL CHECK (jsonb_typeof(report) = 'object'),
    PRIMARY KEY (report_year, report_month, version),
    CHECK (version = 1 OR (reason IS NOT NULL AND length(btrim(reason)) > 0))
);

CREATE OR REPLACE PROCEDURE public.coursework_monthly_report_get(
    IN p_year INTEGER, IN p_month INTEGER, IN p_version INTEGER, INOUT p_result JSONB
)
LANGUAGE plpgsql AS $$
DECLARE
    v_report JSONB;
    v_versions JSONB;
BEGIN
    IF p_year NOT BETWEEN 2000 AND 2100 OR p_month NOT BETWEEN 1 AND 12
       OR p_year IS NULL OR p_month IS NULL OR (p_version IS NOT NULL AND p_version < 1) THEN
        RAISE EXCEPTION 'Некорректный месяц или версия.' USING ERRCODE = '22023';
    END IF;
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'version', version, 'closed_at', closed_at, 'closed_by', closed_by, 'reason', reason
    ) ORDER BY version DESC), '[]'::jsonb)
    INTO v_versions FROM public."Monthly Report Versions"
    WHERE report_year = p_year AND report_month = p_month;

    SELECT report || jsonb_build_object('catalog', catalog, 'version', version,
               'closed_at', closed_at, 'closed_by', closed_by, 'reason', reason)
    INTO v_report FROM public."Monthly Report Versions"
    WHERE report_year = p_year AND report_month = p_month
      AND (p_version IS NULL OR version = p_version)
    ORDER BY version DESC LIMIT 1;
    IF v_report IS NULL THEN
        IF p_version IS NOT NULL THEN
            RAISE EXCEPTION 'Версия отчёта не найдена.' USING ERRCODE = '22023';
        END IF;
        CALL public.coursework_monthly_business_details(p_year, p_month, v_report);
        v_report := jsonb_set(v_report, '{summary,most_demanded_packages}', 'null'::jsonb);
        v_report := jsonb_set(v_report, '{summary,packages_without_sales}', 'null'::jsonb);
        v_report := v_report || jsonb_build_object('version', NULL, 'catalog', NULL);
    END IF;
    p_result := v_report || jsonb_build_object('versions', v_versions);
END;
$$;

CREATE OR REPLACE PROCEDURE public.coursework_monthly_report_close(
    IN p_year INTEGER, IN p_month INTEGER, IN p_expected_version INTEGER,
    IN p_catalog JSONB, IN p_reason TEXT, IN p_actor TEXT, INOUT p_result JSONB
)
LANGUAGE plpgsql AS $$
DECLARE
    v_month DATE;
    v_next DATE;
    v_current INTEGER;
    v_report JSONB;
    v_catalog JSONB;
    v_demand JSONB;
    v_unsold JSONB;
BEGIN
    IF p_year IS NULL OR p_year NOT BETWEEN 2000 AND 2100 OR p_month IS NULL OR p_month NOT BETWEEN 1 AND 12
       OR p_expected_version IS NULL OR p_expected_version < 0 OR p_actor IS NULL OR btrim(p_actor) = '' THEN
        RAISE EXCEPTION 'Некорректные параметры закрытия.' USING ERRCODE = '22023';
    END IF;
    v_month := make_date(p_year, p_month, 1);
    v_next := (v_month + interval '1 month')::date;
    IF v_next > current_date THEN
        RAISE EXCEPTION 'Закрыть можно только завершившийся месяц.' USING ERRCODE = '22023';
    END IF;
    IF p_catalog IS NULL OR jsonb_typeof(p_catalog) <> 'array' THEN
        RAISE EXCEPTION 'Необходимо подтвердить список путёвок.' USING ERRCODE = '22023';
    END IF;
    IF EXISTS (
        SELECT 1 FROM jsonb_array_elements(p_catalog) e
        WHERE jsonb_typeof(e) <> 'object' OR COALESCE(e->>'package_id', '') !~ '^[1-9][0-9]{0,8}$'
           OR COALESCE(e->>'monthly_capacity', '') !~ '^(0|[1-9][0-9]{0,8})$'
    ) THEN
        RAISE EXCEPTION 'Проверьте путёвки и количество мест.' USING ERRCODE = '22023';
    END IF;
    PERFORM pg_advisory_xact_lock(829104, p_year * 100 + p_month);
    SELECT COALESCE(MAX(version), 0) INTO v_current FROM public."Monthly Report Versions"
    WHERE report_year = p_year AND report_month = p_month;
    IF v_current <> p_expected_version THEN
        RAISE EXCEPTION 'Отчёт уже изменён. Обновите страницу и повторите закрытие.' USING ERRCODE = '22023';
    END IF;
    IF v_current > 0 AND (p_reason IS NULL OR btrim(p_reason) = '') THEN
        RAISE EXCEPTION 'Укажите причину повторного закрытия.' USING ERRCODE = '22023';
    END IF;
    LOCK TABLE public."Tour Packages", public."Tour Package Sales", public."Document Events",
        public."Finances", public."Tourist Information", public."Tourist Children", public."Flights"
        IN SHARE MODE;
    IF (SELECT count(*) FROM jsonb_array_elements(p_catalog)) <>
       (SELECT count(DISTINCT (e->>'package_id')::integer) FROM jsonb_array_elements(p_catalog) e)
       OR EXISTS (
          SELECT 1 FROM jsonb_array_elements(p_catalog) e
          LEFT JOIN public."Tour Packages" p ON p.package_id = (e->>'package_id')::integer
          WHERE p.package_id IS NULL
       ) THEN
        RAISE EXCEPTION 'Список содержит повторяющуюся или удалённую путёвку.' USING ERRCODE = '22023';
    END IF;

    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'package_id', p.package_id, 'package_code', p.package_code, 'package_name', p.package_name,
        'monthly_capacity', (e->>'monthly_capacity')::integer
    ) ORDER BY p.package_name, p.package_id), '[]'::jsonb)
    INTO v_catalog FROM jsonb_array_elements(p_catalog) e
    JOIN public."Tour Packages" p ON p.package_id = (e->>'package_id')::integer;

    IF EXISTS (
        SELECT 1 FROM public."Tour Package Sales" s
        WHERE s.sold_date >= v_month AND s.sold_date < v_next
          AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(v_catalog) e
                          WHERE (e->>'package_id')::integer = s.package_id)
    ) THEN
        RAISE EXCEPTION 'Включите в список все путёвки, проданные за этот месяц.' USING ERRCODE = '22023';
    END IF;

    WITH demand AS (
        SELECT p.package_id, p.package_name, count(*) AS sold_count
        FROM public."Tour Package Sales" s JOIN public."Tour Packages" p ON p.package_id = s.package_id
        WHERE s.sold_date >= v_month AND s.sold_date < v_next
        GROUP BY p.package_id, p.package_name
    )
    SELECT COALESCE(jsonb_agg(package_name || ' — ' || sold_count ORDER BY package_name, package_id)
        FILTER (WHERE sold_count = (SELECT max(sold_count) FROM demand)), '[]'::jsonb)
    INTO v_demand FROM demand;
    SELECT COALESCE(jsonb_agg((e->>'package_name') || ' — мест: ' || (e->>'monthly_capacity')
                             ORDER BY e->>'package_name', (e->>'package_id')::integer), '[]'::jsonb)
    INTO v_unsold FROM jsonb_array_elements(v_catalog) e
    WHERE NOT EXISTS (SELECT 1 FROM public."Tour Package Sales" s
        WHERE s.package_id = (e->>'package_id')::integer AND s.sold_date >= v_month AND s.sold_date < v_next);

    CALL public.coursework_monthly_business_details(p_year, p_month, v_report);
    v_report := jsonb_set(v_report, '{summary,most_demanded_packages}', v_demand);
    v_report := jsonb_set(v_report, '{summary,packages_without_sales}', v_unsold);
    INSERT INTO public."Monthly Report Versions" (report_year, report_month, version, closed_by, reason, catalog, report)
    VALUES (p_year, p_month, v_current + 1, btrim(p_actor), NULLIF(btrim(p_reason), ''), v_catalog, v_report);
    CALL public.coursework_monthly_report_get(p_year, p_month, v_current + 1, p_result);
END;
$$;

COMMIT;
