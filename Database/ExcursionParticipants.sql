-- Read-only list of excursion bookings for transfer to an agency.
BEGIN;

CREATE OR REPLACE PROCEDURE public.coursework_excursion_participants(
    IN p_start_date DATE, IN p_end_date DATE,
    IN p_agency_id INTEGER, IN p_excursion_id INTEGER,
    INOUT p_result JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_start_date > p_end_date
       OR p_agency_id < 1 OR p_excursion_id < 1 THEN
        RAISE EXCEPTION 'Invalid excursion report parameters' USING ERRCODE = '22023';
    END IF;

    SELECT COALESCE(JSONB_AGG(TO_JSONB(row_data)
        ORDER BY row_data.excursion_date, row_data.agency_name, row_data.excursion_name,
                 row_data.guardian_name, row_data.participant_type, row_data.participant_name, row_data.booking_id), '[]'::JSONB)
    INTO p_result
    FROM (
        SELECT e.schedule_date AS excursion_date, a.agency_name, e.excursion_name,
               b.booking_id,
               CASE WHEN b.child_id IS NULL THEN 'Взрослый' ELSE 'Ребёнок' END AS participant_type,
               CASE WHEN b.child_id IS NULL
                   THEN CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)
                   ELSE CONCAT_WS(' ', c.last_name, c.first_name, c.patronymic)
               END AS participant_name,
               CASE WHEN b.child_id IS NOT NULL
                   THEN CONCAT_WS(' ', t.tourist_surname, t.tourist_name, t.tourist_patronymic)
                   ELSE NULL
               END AS guardian_name
        FROM public."Excursion Bookings" b
        JOIN public."Excursions" e ON e.excursion_id = b.excursion_id
        JOIN public."Agencies" a ON a.agency_id = e.agency_id
        JOIN public."Tourist Information" t ON t.tourist_id = b.tourist_id
        LEFT JOIN public."Tourist Children" c ON c.child_id = b.child_id AND c.tourist_id = b.tourist_id
        WHERE e.schedule_date::DATE BETWEEN p_start_date AND p_end_date
          AND (p_agency_id IS NULL OR e.agency_id = p_agency_id)
          AND (p_excursion_id IS NULL OR e.excursion_id = p_excursion_id)
    ) row_data;
END;
$$;

COMMIT;
