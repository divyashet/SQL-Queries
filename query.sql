/***********************************************************************************************************************************
Report Name : Hajoca Employee Demographic Details Report
Data Model Name: Hajoca Employee Demographic Details Data Model

Data Model Change History
-------------------------
Update Date  Updated By                      Version            Description
-----------  ------------------------------  ---------          ----------------------------------
13-Oct-2016  Rakshita Bhandari                  1               Initial draft
*************************************************************************************************************************************/
SELECT
    papf.person_number employee_id,
    ppnfv.last_name employee_last_name,
    ppnfv.first_name employee_first_name,
    ppnfv.middle_names employee_middle_name,
    past.user_status employee_status,
    (
        SELECT DISTINCT
            TO_DATE(TO_CHAR(date_start,'MM/DD/YYYY'),'MM/DD/YYYY')
        FROM
            per_periods_of_service
        WHERE
            person_id (+) = pasm.person_id
        AND
            period_of_service_id (+) = pasm.period_of_service_id
    ) legal_emp_hiredate--Legal Employer Hire Date
    ,
    (
        SELECT DISTINCT
            TO_DATE(TO_CHAR(original_date_of_hire,'MM/DD/YYYY'),'MM/DD/YYYY')
        FROM
            per_periods_of_service
        WHERE
            person_id = papf.person_id
        AND
            period_of_service_id (+) = pasm.period_of_service_id
    ) enterprise_hiredate--Enterprise Hire Date
    ,
    pjft.name job_title,
    pasm.manager_flag is_manager,
    manager_name.full_name first_level_manager_name,
    second_manager.full_name second_level_manager_name,
    haou.name department,
    hao1.name business_unit,
    hla.location_name location,
    pni.national_identifier_number ssn,
    DECODE(pplf.sex,'M','Male','F','Female') gender,
    TO_DATE(TO_CHAR(pp.date_of_birth,'MM/DD/YYYY'),'MM/DD/YYYY') date_of_birth,
    floor(round( ( (TO_DATE(TO_CHAR(SYSDATE,'MM/DD/YYYY'),'MM/DD/YYYY') ) - (TO_DATE(TO_CHAR(pp.date_of_birth,'MM/DD/YYYY'),'MM/DD/YYYY') )
 ) / 365.25) ) age,
    paf.address_line_1,
    paf.address_line_2,
    paf.town_or_city city,
    paf.region_2 state,
    paf.postal_code zip,
    pe.ethnicity,
    floor(round( ( (TO_DATE(TO_CHAR(SYSDATE,'MM/DD/YYYY'),'MM/DD/YYYY') ) - (TO_DATE(
        TO_CHAR(
            (
                SELECT DISTINCT
                    TO_DATE(TO_CHAR(date_start,'MM/DD/YYYY'),'MM/DD/YYYY')
                FROM
                    per_periods_of_service
                WHERE
                        person_id(+)
                    =
                        pasm.person_id
                AND
                        period_of_service_id(+)
                    =
                        pasm.period_of_service_id
            ),
            'MM/DD/YYYY'
        ),
        'MM/DD/YYYY'
    ) ) ) / 365.25) ) length_of_service,
    (
        SELECT
            email_address
        FROM
            per_email_addresses pea
        WHERE
            person_id = papf.person_id
        AND
            email_type = 'W1'
        AND
            object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    per_email_addresses
                WHERE
                    person_id = papf.person_id
                AND
                    TO_DATE(TO_CHAR(:eff_end_dt,'MM/DD/YYYY'),'MM/DD/YYYY') BETWEEN TO_DATE(TO_CHAR(pea.date_from,'MM/DD/YYYY'),'MM/DD/YYYY') AND TO_DATE
(TO_CHAR(nvl(pea.date_to,:eff_end_dt),'MM/DD/YYYY'),'MM/DD/YYYY')
            )
    ) office_email,
    pasm.primary_flag primary_or_secondary_assignmnt
FROM
    per_all_people_f papf,
    per_person_names_f_v ppnfv,
    per_periods_of_service ppos,
    per_jobs_f_tl pjft,
    hr_all_organization_units_f_vl haou,
    hr_all_organization_units_f_vl hao1,
    hr_locations_all_f_vl hla,
    per_national_identifiers pni,
    per_all_assignments_m pasm,
    per_people_legislative_f pplf,
    per_persons pp,
    per_addresses_f paf,
    per_ethnicities pe,
    per_assignment_status_types_tl past,
    (
        SELECT DISTINCT
            date_start datestart,
            person_id,
            period_of_service_id
        FROM
            per_periods_of_service
    ) date_start   /*Have taken date_sart as a inline table*/,
    (
        SELECT
            pa.person_id person_id,
            pa.assignment_id assignment_id,
            ppn.full_name full_name,
            pa.effective_start_date effective_start_date,
            pa.effective_end_date effective_end_date,
            pa.action_occurrence_id action_occurrence_id
        FROM
            per_assignment_supervisors_f pa,
            per_person_names_f_v ppn,
            per_all_assignments_m pasm1
        WHERE
            pa.manager_id = ppn.person_id
        AND
            :eff_end_dt BETWEEN ppn.effective_start_date AND ppn.effective_end_date
        AND
            :eff_end_dt BETWEEN pasm1.effective_start_date AND pasm1.effective_end_date
        AND
            pasm1.action_occurrence_id = (
                SELECT
                    MAX(action_occurrence_id)
                FROM
                    per_all_assignments_m
                WHERE
                    pa.assignment_id = assignment_id
                AND
                    primary_flag = pasm1.primary_flag
                AND
                    :eff_end_dt BETWEEN effective_start_date AND effective_end_date
            )
        AND
            pa.action_occurrence_id = (
                SELECT
                    MAX(action_occurrence_id)
                FROM
                    per_assignment_supervisors_f
                WHERE
                    assignment_id (+) = pasm1.assignment_id
                AND
                    nvl(pa.effective_start_date,pasm1.effective_start_date) <= (:eff_end_dt )
                AND
                    nvl(pa.effective_end_date,pasm1.effective_end_date) >= nvl(:eff_start_dt,nvl(pa.effective_end_date,pasm1.effective_end_date) )
            )
    ) manager_name,
    (
        SELECT
            pasf1.person_id person_id,
            pasf1.assignment_id assignment_id,
            pp2.full_name full_name
        FROM
            per_assignment_supervisors_f pasf1,
            per_assignment_supervisors_f pasf2,
            per_all_assignments_m pasm2,
            per_all_assignments_m pasm3,
            per_person_names_f_v pp2
        WHERE
            pasf1.manager_id = pasf2.person_id
        AND
            pasm2.action_occurrence_id = (
                SELECT
                    MAX(action_occurrence_id)
                FROM
                    per_all_assignments_m
                WHERE
                    person_id = pasf2.person_id
                AND
                    primary_flag = pasm2.primary_flag
                AND
                    :eff_end_dt BETWEEN effective_start_date AND effective_end_date
            )
        AND
            pasf2.action_occurrence_id = (
                SELECT
                    MAX(action_occurrence_id)
                FROM
                    per_assignment_supervisors_f
                WHERE
                    assignment_id = pasm2.assignment_id
                AND
                    pasf1.effective_start_date <= nvl(:eff_end_dt,pasf1.effective_start_date)
                AND
                    nvl(pasf1.effective_end_date,pasm3.effective_end_date) >= nvl(:eff_start_dt,nvl(pasf1.effective_end_date,pasm3.effective_end_date) )

            )
        AND
            pasm3.action_occurrence_id = (
                SELECT
                    MAX(action_occurrence_id)
                FROM
                    per_all_assignments_m
                WHERE
                    person_id = pasf1.person_id
                AND
                    primary_flag = pasm3.primary_flag
                AND
                    :eff_end_dt BETWEEN effective_start_date AND effective_end_date
            )
        AND
            pasf1.action_occurrence_id = (
                SELECT
                    MAX(action_occurrence_id)
                FROM
                    per_assignment_supervisors_f
                WHERE
                    assignment_id = pasm3.assignment_id
                AND
                    nvl(pasf1.effective_start_date,pasm3.effective_start_date) <= (:eff_end_dt )
                AND
                    nvl(pasf1.effective_end_date,pasm3.effective_end_date) >= (:eff_start_dt )
            )
        AND
            pasf2.assignment_id = pasm2.assignment_id (+)
        AND
            pasf1.assignment_id = pasm3.assignment_id (+)
        AND
            :eff_end_dt BETWEEN pasm2.effective_start_date AND pasm2.effective_end_date
        AND
            :eff_end_dt BETWEEN pasm3.effective_start_date AND pasm3.effective_end_date
        AND
            pasm2.primary_flag = 'Y'
        AND
            pasf2.manager_id = pp2.person_id
        AND
            pp2.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    per_person_names_f_v
                WHERE
                    person_id = pp2.person_id
            )
    ) second_manager
WHERE
    papf.person_id = ppnfv.person_id
AND
    :eff_end_dt BETWEEN papf.effective_start_date AND papf.effective_end_date
AND
    :eff_end_dt BETWEEN ppnfv.effective_start_date AND ppnfv.effective_end_date
AND
    date_start.person_id (+) = pasm.person_id
AND
    date_start.period_of_service_id (+) = pasm.period_of_service_id
AND
    papf.person_id = pasm.person_id
AND
    pasm.assignment_sequence = (
        SELECT
            MAX(assignment_sequence)
        FROM
            per_all_assignments_m
        WHERE
            person_id = papf.person_id
        AND
            primary_flag = pasm.primary_flag
        AND
            nvl(:eff_end_dt,effective_end_date) BETWEEN effective_start_date AND effective_end_date
    )
AND
    trunc(papf.effective_end_date) >=:eff_end_dt
AND
    TO_DATE(TO_CHAR(:eff_end_dt,'MM/DD/YYYY'),'MM/DD/YYYY') BETWEEN TO_DATE(TO_CHAR(pasm.effective_start_date,'MM/DD/YYYY'),'MM/DD/YYYY'
) AND TO_DATE(TO_CHAR(pasm.effective_end_date,'MM/DD/YYYY'),'MM/DD/YYYY')
AND
    pasm.assignment_type NOT IN (
        'ET','CT','NT'
    )
AND
    pasm.job_id = pjft.job_id (+)
AND
    :eff_end_dt BETWEEN pjft.effective_start_date (+) AND pjft.effective_end_date (+)
AND
    haou.organization_id (+) = pasm.organization_id
AND
    :eff_end_dt BETWEEN haou.effective_start_date (+) AND haou.effective_end_date (+)
AND
    hao1.organization_id (+) = pasm.business_unit_id
AND
    :eff_end_dt BETWEEN hao1.effective_start_date (+) AND hao1.effective_end_date (+)
AND
    hla.location_id (+) = pasm.location_id
AND
    papf.person_id = pni.person_id (+)
AND
    papf.person_id = pplf.person_id (+)
AND
    TO_DATE(TO_CHAR(:eff_end_dt,'MM/DD/YYYY'),'MM/DD/YYYY') BETWEEN TO_DATE(TO_CHAR(pplf.effective_start_date,'MM/DD/YYYY'),'MM/DD/YYYY'
) AND TO_DATE(TO_CHAR(pplf.effective_end_date,'MM/DD/YYYY'),'MM/DD/YYYY')
AND
    papf.person_id = pp.person_id
AND
    pp.object_version_number = (
        SELECT
            MAX(object_version_number)
        FROM
            per_persons
        WHERE
            papf.person_id = person_id
    )
AND
    paf.address_id (+) = papf.mailing_address_id
AND
    :eff_end_dt BETWEEN paf.effective_start_date (+) AND paf.effective_end_date (+)
AND
    papf.person_id = pe.person_id (+)
AND
    pasm.assignment_status_type_id = past.assignment_status_type_id
AND
    pasm.person_id = manager_name.person_id (+)
AND
    pasm.assignment_id = manager_name.assignment_id (+)
AND
    pasm.person_id = second_manager.person_id (+)
AND
    pasm.assignment_id = second_manager.assignment_id (+)
AND
    papf.person_id = ppos.person_id
AND
    pasm.period_of_service_id = ppos.period_of_service_id
AND
    pasm.action_occurrence_id = (
        SELECT
            MAX(action_occurrence_id)
        FROM
            per_all_assignments_m
        WHERE
            person_id = papf.person_id
        AND
            primary_flag = pasm.primary_flag
        AND
            :eff_end_dt BETWEEN effective_start_date AND effective_end_date
    )
AND
    ppos.original_date_of_hire <= nvl(:eff_end_dt,ppos.original_date_of_hire)
AND
    nvl(ppos.actual_termination_date,papf.effective_end_date) >= nvl(:eff_start_dt,nvl(ppos.actual_termination_date,papf.effective_end_date
) )
   -- /*Have used coalesce instead of NVL in the report parameters,since NVL fails at times in the report*/
AND (
    (
        coalesce(NULL,:manager) IS NULL
    ) OR (
        manager_name.full_name IN (
            :manager
        )
    )
) AND (
    (
        coalesce(NULL,:second_mgr) IS NULL
    ) OR (
        second_manager.full_name IN (
            :second_mgr
        )
    )
) AND (
    (
        coalesce(NULL,:business_unit) IS NULL
    ) OR (
        hao1.name IN (
            :business_unit
        )
    )
) AND (
    (
        coalesce(NULL,:dept_name) IS NULL
    ) OR (
        haou.name IN (
            :dept_name
        )
    )
) AND (
    (
        coalesce(NULL,:loc_name) IS NULL
    ) OR (
        hla.location_name IN (
            :loc_name
        )
    )
) AND (
    (
        coalesce(NULL,:job_name) IS NULL
    ) OR (
        pjft.name IN (
            :job_name
        )
    )
) AND (
    (
        coalesce(NULL,:ethnicity_name) IS NULL
    ) OR (
        pe.ethnicity IN (
            :ethnicity_name
        )
    )
) AND (
    (
        coalesce(NULL,:person_type) IS NULL
    ) OR (
        DECODE(pasm.system_person_type,'NONW','Nonworker','CWK','Contingent Worker','EMP','Employee') IN (
            :person_type
        )
    )
) AND (
    (
        coalesce(NULL,:assignment) IS NULL
    ) OR (
        DECODE(pasm.primary_flag,'Y','Primary','N','Secondary') IN (
            :assignment
        )
    )
) ORDER BY
    ppnfv.last_name,
    ppnfv.first_name