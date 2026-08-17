CREATE OR REPLACE PACKAGE BODY ADM_PROD.traitement_crm
IS
    --------------------------------------------------------------------------------
    ----------- CRM Main -----------------------------------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE main
    IS
    BEGIN
        adm_prod.modif_mobil;
        iia.modif_mobil;
        sehha.modif_mobil;

        DELETE FROM pmprcl_mobil;

        DELETE FROM bprovis_mobil;


        calculpm;

        DELETE FROM tablecrm;

        DELETE FROM crm_sinistre;

        DELETE FROM crm_versement;

        DELETE FROM crm_pm_uc_support;



        COMMIT;

        proc_tabcrm_bq;
        proc_tabcrm_sis;
        proc_tabcrm_ind;
        proc_tabcrm_his;
        proc_tabcrm_sync_groupe;
        proc_adherent_epalmv_to_customer;
        proc_tabcrm_205_pass;

        UPDATE tablecrm
        SET id = ROWNUM;

        UPDATE crm_sinistre
        SET id = ROWNUM;

        UPDATE crm_versement
        SET id = ROWNUM;

        UPDATE crm_pm_uc_support
        SET id = ROWNUM;



        COMMIT;

        transfer_file;
    END;

    PROCEDURE MAIN_SIS IS
    BEGIN
        iia.modif_mobil;

        DELETE FROM tablecrm WHERE numcat IN (200,201,202,203,204,206);
        DELETE FROM crm_pm_uc_support WHERE numcat IN (200,201,202,203,204,206);

        COMMIT;

        proc_tabcrm_sis;

        UPDATE tablecrm SET id = ROWNUM WHERE numcat IN (200,201,202,203,204,206);
        UPDATE crm_pm_uc_support SET id = ROWNUM WHERE numcat IN (200,201,202,203,204,206);

        DELETE FROM lmvmobp.tablecrm WHERE numcat IN (200,201,202,203,204,206);
        DELETE FROM lmvmobp.crm_pm_uc_support WHERE numcat IN (200,201,202,203,204,206);


        INSERT INTO lmvmobp.tablecrm SELECT * FROM adm_prod.tablecrm WHERE numcat IN (200,201,202,203,204,206);
        INSERT INTO lmvmobp.crm_pm_uc_support SELECT * FROM adm_prod.crm_pm_uc_support WHERE numcat IN (200,201,202,203,204,206) ;

        COMMIT;

        Create_Customers;
        Update_Code_Clt_Sgma_sis;

        COMMIT;

    END;


    PROCEDURE MAIN_HORS_SIS IS
    BEGIN
        adm_prod.modif_mobil;
        sehha.modif_mobil;

        DELETE FROM pmprcl_mobil;
        DELETE FROM bprovis_mobil;
        calculpm;

        DELETE FROM tablecrm WHERE numcat NOT IN (200,201,202,203,204,206);
        DELETE FROM crm_sinistre WHERE numcatbase NOT IN (200,201,202,203,204,206);
        DELETE FROM crm_versement WHERE numcat NOT IN (200,201,202,203,204,206);
        DELETE FROM crm_pm_uc_support WHERE numcat NOT IN (200,201,202,203,204,206);

        COMMIT;

        proc_tabcrm_bq;
        proc_tabcrm_ind;
        proc_tabcrm_his;
        proc_tabcrm_sync_groupe;
        proc_adherent_epalmv_to_customer;
        proc_tabcrm_205_pass;

        UPDATE tablecrm SET id = ROWNUM WHERE numcat NOT IN (200,201,202,203,204,206);
        UPDATE crm_sinistre SET id = ROWNUM WHERE numcatbase NOT IN (200,201,202,203,204,206);
        UPDATE crm_versement SET id = ROWNUM WHERE numcat NOT IN (200,201,202,203,204,206);
        UPDATE crm_pm_uc_support SET id = ROWNUM WHERE numcat NOT IN (200,201,202,203,204,206);

        DELETE FROM lmvmobp.tablecrm WHERE numcat NOT IN (200,201,202,203,204,206);
        DELETE FROM lmvmobp.crm_sinistre WHERE numcatbase NOT IN (200,201,202,203,204,206);
        DELETE FROM lmvmobp.crm_versement WHERE numcat NOT IN (200,201,202,203,204,206);
        DELETE FROM lmvmobp.crm_pm_uc_support WHERE numcat NOT IN (200,201,202,203,204,206);


        INSERT INTO lmvmobp.tablecrm SELECT * FROM adm_prod.tablecrm WHERE numcat NOT IN (200,201,202,203,204,206);
        INSERT INTO lmvmobp.crm_sinistre SELECT * FROM adm_prod.crm_sinistre WHERE numcatbase NOT IN (200,201,202,203,204,206);
        INSERT INTO lmvmobp.crm_versement SELECT * FROM adm_prod.crm_versement WHERE numcat NOT IN (200,201,202,203,204,206);
        INSERT INTO lmvmobp.crm_pm_uc_support SELECT * FROM adm_prod.crm_pm_uc_support WHERE numcat NOT IN (200,201,202,203,204,206);


        COMMIT;

        Create_Customers;
        Update_Code_Clt_Sgma_hors_sis;
        extraction_tables_crm;

        COMMIT;

    END;



    PROCEDURE proc_tabcrm_205_pass
        IS
    BEGIN
        --------------------------------------------------------------------
        -- Synchronisation TABLECRM_PASS -> TABLECRM
        --------------------------------------------------------------------
        BEGIN
            INSERT INTO tablecrm
            SELECT *
            FROM tablecrm_pass
            WHERE numcat = 205
              AND TRIM(LIBSTATCTR) NOT IN ('Contrat clôturé');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.put_line('Erreur TABLECRM_PASS -> TABLECRM : ' || SQLERRM);
        END;

        --------------------------------------------------------------------
        -- Synchronisation CRM_PM_UC_SUPPORT_PASS -> CRM_PM_UC_SUPPORT
        --------------------------------------------------------------------
        FOR rec IN (
            SELECT ID,
                   rang,
                   PM_SAVING_EFFEC_DTE,
                   SUPPORT,
                   REF_SUPPORT_ID,
                   numcat,
                   NADH,
                   PM_VAL
            FROM crm_pm_uc_support_pass
            WHERE numcat = 205
            ) LOOP
                BEGIN
                    INSERT INTO crm_pm_uc_support (
                        ID,
                   rang,
                   PM_SAVING_EFFEC_DTE,
                   SUPPORT,
                   REF_SUPPORT_ID,
                   numcat,
                   NADH,
                   PM_VAL
                    )
                    VALUES (
                              rec.ID,
                    rec.rang,
                    rec.PM_SAVING_EFFEC_DTE,
                    rec.SUPPORT,
                    rec.REF_SUPPORT_ID,
                    rec.numcat,
                    rec.NADH,
                    rec.PM_VAL
                           );
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.put_line('Erreur CRM_PM_UC_SUPPORT_PASS -> CRM_PM_UC_SUPPORT : ' || SQLERRM);
                        DBMS_OUTPUT.put_line('NADH en erreur : ' || rec.NADH);
                END;
            END LOOP;
        --------------------------------------------------------------------
        -- Validation des insertions
        --------------------------------------------------------------------
        COMMIT;
    END;



    --------------------------------------------------------------------------------
    ----------- PROC_ADHERENT_EPALMV_TO_CUSTOMER -----------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE PROC_ADHERENT_EPALMV_TO_CUSTOMER
        IS
        v_id NUMBER;
    BEGIN
        -- Récupérer le prochain ID disponible
        SELECT MAX(customerid) + 1
        INTO v_id
        FROM lmvmobp.customer;

        -- Boucle sur les adhérents éligibles
        FOR i IN (
            SELECT DISTINCT REPLACE(REPLACE(UPPER(TRIM(a.cin)), ' ', ''), '.', '') AS cin,
                            a.per_email_mobil,
                            TRIM(a.nomass)                                         AS nomass,
                            TRIM(a.prenom)                                         AS prenom,
                            a.gsm,
                            a.dnaisass
            FROM epalmv.adherent a
            WHERE a.numcat = 64
              AND a.detdepart IS NULL
              AND a.dnaisass IS NOT NULL
              AND REPLACE(REPLACE(UPPER(TRIM(a.cin)), ' ', ''), '.', '') NOT IN
                  (SELECT REPLACE(REPLACE(UPPER(TRIM(b.cin)), ' ', ''), '.', '')
                   FROM lmvmobp.customer b)
            )
            LOOP
                -- Insertion dans CUSTOMER
                INSERT INTO lmvmobp.customer (customerid,
                                              cin,
                                              email,
                                              login,
                                              nom,
                                              password,
                                              tel,
                                              date_naissance,
                                              nbr_connexion,
                                              address,
                                              nbrconnexion,
                                              prenom,
                                              telfix,
                                              push_token,
                                              os,
                                              version,
                                              push_type,
                                              default_password_changed,
                                              code_clt_sgma)
                VALUES (v_id,
                        i.cin,
                        trim(i.per_email_mobil),
                        NULL,
                        TRIM(i.nomass) || ' ' || TRIM(i.prenom),
                        NULL,
                        i.gsm,
                        i.dnaisass,
                        0,
                        0,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        'ANDROID',
                        1,
                        NULL,
                        0,
                        NULL
                       );

                -- Logging console
                DBMS_OUTPUT.put_line(
                        'Inserted CUSTOMERID=' || v_id || ' CIN=' || i.cin
                );

                -- Incrémenter l’ID
                v_id := v_id + 1;
            END LOOP;
    END;


    --------------------------------------------------------------------------------
    ----------- PROC_TABCRM_SYNC_GROUPE --------------------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE PROC_TABCRM_SYNC_GROUPE
        IS
        -- Cursor for syncing SOCIETE + ADHERENT into TABLECRM
        CURSOR c_sync IS
            SELECT s.POLICE,
                   s.NUMCAT,
                   s.MODP,
                   s.CODAGCE,
                   s.NOMCTR,
                   s.ECHEANCE AS DATEEXPIRATION,
                   a.MATRICULE,
                   a.NUMCOMPTE,
                   a.CIN,
                   a.GSM,
                   a.PER_EMAIL_MOBIL,
                   a.DATENTREE,
                   a.DATE_DEPART_CTR,
                   a.NOMASS,
                   a.DNAISASS,
                   a.COTISATINI,
                   a.CAPITAL,
                   a.DATE1TERME,
                   a.MTFREACT,
                   a.BENEFICIARE,
                   a.PRIMEDECES,
                   a.POLTRANS
            FROM SOCIETE s
                     JOIN ADHERENT a ON s.POLICE = a.POLICE
            WHERE s.NUMCAT = 64
              AND a.NUMCAT = 64
              AND a.DETDEPART is null;

        -- Cursor for syncing COTISATI into CRM_VERSEMENT
        CURSOR c_versement IS
            SELECT c.POLICE,
                   c.NUMCAT,
                   c.MATRICULE,
                   c.ECHEANCE,
                   c.DATECAP,
                   c.COTTOTALE,
                   c.COTPATR,
                   c.COTSALR
            FROM COTISATI c
            WHERE c.NUMCAT = 64 and c.DATANNUL is null;

        r_tablecrm  TABLECRM%ROWTYPE;
        r_versement CRM_VERSEMENT%ROWTYPE;
    BEGIN
        -- Sync SOCIETE + ADHERENT into TABLECRM
        FOR rec IN c_sync
            LOOP
                r_tablecrm.freq := CASE UPPER(TRIM(rec.MODP))
                                       WHEN 'MENSUEL' THEN 'M'
                                       WHEN 'ANNUEL' THEN 'A'
                                       WHEN 'TRIMESTRIEL' THEN 'T'
                                       WHEN 'SEMESTRIEL' THEN 'S'
                                       ELSE NULL
                    END;

                r_tablecrm.numcat := rec.NUMCAT;
                r_tablecrm.agce := LPAD(rec.CODAGCE, 3, '0');
                r_tablecrm.libagce := NULL; -- à enrichir via BAGENCE
                r_tablecrm.numcpt := rec.NUMCOMPTE;
                r_tablecrm.cin := REPLACE(REPLACE(UPPER(rec.CIN), ' ', ''), '.', '');
                r_tablecrm.num_tel := TRIM(rec.GSM);
                r_tablecrm.per_email := TRIM(rec.PER_EMAIL_MOBIL);
                r_tablecrm.nadh := TO_CHAR(rec.POLICE);
                r_tablecrm.date_annul := rec.DATE_DEPART_CTR;
                r_tablecrm.nompsous := rec.NOMASS;
                r_tablecrm.dnsous := rec.DNAISASS;
                r_tablecrm.mtcot := rec.COTISATINI;
                r_tablecrm.mtrachp := rec.MTFREACT;
                r_tablecrm.npass1 := rec.BENEFICIARE;
                r_tablecrm.primeass1 := rec.PRIMEDECES;
                r_tablecrm.dateexpiration := rec.DATEEXPIRATION;
                r_tablecrm.contractante := rec.NOMCTR;
                r_tablecrm.MATRICULE := rec.MATRICULE;
                r_tablecrm.TYPEPRODUIT := 'RETRAITE';
                r_tablecrm.LIBNUMCAT := 'DYNAMIC ENTREPRISE';
                r_tablecrm.LIBSTATCTR := 'En vigueur';

                BEGIN
                    SELECT DATECAP, COTTOTALE
                    INTO r_tablecrm.datesous, r_tablecrm.MNTPREMIERVERSEMENT
                    FROM (
                             SELECT DATECAP, COTTOTALE
                             FROM COTISATI c
                             WHERE c.POLICE    = rec.POLICE
                               AND c.MATRICULE = rec.MATRICULE
                               AND c.NUMCAT    = rec.NUMCAT
                             ORDER BY c.DATECAP ASC
                         )
                    WHERE ROWNUM = 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        r_tablecrm.datesous := NULL;
                        r_tablecrm.MNTPREMIERVERSEMENT := NULL;
                END;

                BEGIN
                    SELECT MAX (datcalc)
                    INTO r_tablecrm.datencou
                    FROM pmprcl_mobil p
                    WHERE p.police = rec.POLICE
                      AND p.MATRICULE = rec.MATRICULE
                      AND p.CAT = rec.NUMCAT;
                EXCEPTION
                    WHEN OTHERS
                        THEN
                            r_tablecrm.datencou := NULL;
                END;

                BEGIN
                    SELECT SUM (NVL (p.vprimps, 0) + NVL (p.vprimpp, 0)),
                           SUM(p.mtavance_ttc),
                           SUM(NVL(p.vprimps, 0)),
                           SUM(NVL(p.vprimpp, 0))
                    INTO r_tablecrm.mtencour,
                        r_tablecrm.mtavce,
                        r_tablecrm.MNTPARTSALARIE,
                        r_tablecrm.MNTPARTPATRON
                    FROM pmprcl_mobil p
                    WHERE p.police = rec.POLICE
                      AND P.MATRICULE = rec.MATRICULE
                      AND p.CAT = rec.NUMCAT
                      AND p.datcalc = r_tablecrm.datencou;
                EXCEPTION
                    WHEN OTHERS
                        THEN
                            r_tablecrm.mtencour := 0;
                            r_tablecrm.mtavce := 0;
                            r_tablecrm.MNTPARTSALARIE := 0;
                            r_tablecrm.MNTPARTPATRON := 0;
                END;

                INSERT INTO TABLECRM VALUES r_tablecrm;
            END LOOP;

        -- Sync COTISATI into CRM_VERSEMENT
        FOR rec IN c_versement
            LOOP
                r_versement.numbas := TO_CHAR(rec.POLICE);
                r_versement.MATRICULE := rec.MATRICULE;
                r_versement.numcat := rec.NUMCAT;
                r_versement.echeance := rec.ECHEANCE;
                r_versement.date_encais := rec.DATECAP;
                r_versement.etat := CASE
                                        WHEN rec.DATECAP IS NULL THEN 'IMPAYE'
                                        ELSE 'PAYE'
                    END;
                r_versement.mtvers := rec.COTTOTALE;
                r_versement.modpayement := 'PRELEVEMENT'; -- à confirmer métier
                r_versement.part_patron := rec.COTPATR;
                r_versement.part_salarie := rec.COTSALR;

                INSERT INTO CRM_VERSEMENT VALUES r_versement;
            END LOOP;

        COMMIT;
    END;


    --------------------------------------------------------------------------------
    ----------- PROC_TABCRM_BQ ----------------------------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE proc_tabcrm_bq
    IS
        r_tablecrm             tablecrm%ROWTYPE;
        r_tablecrm_null        tablecrm%ROWTYPE;

        r_crm_versement        crm_versement%ROWTYPE;
        r_crm_versement_null   crm_versement%ROWTYPE;

        wmtbase                NUMBER;
        wmtcompl               NUMBER;
        wmtij                  NUMBER;
        wii                    NUMBER;
    BEGIN
        FOR i
            IN (SELECT a.*,
                       b.libelle_client libelle,
                       c.nomagce,
                          TRIM (d.tnom)
                       || ' '
                       || TRIM (d.nom)
                       || ' '
                       || TRIM (d.prenom) nom_prenom,
                       datnaiss,
                       d.cin,
                       d.per_email_mobil,
                       d.num_tel_mobil,
                       DECODE (UPPER (TRIM (ntsmt)), 'O', 1, 0) ntsmtb,
                       minverslibre,
                       minversprogm,
                       minversprogt,
                       minversproga
                FROM bcontrat a,
                     categori b,
                     bagence c,
                     bclient d,
                     categ_vers_mobil cvm
                WHERE     a.numcat = b.numcat
                      AND b.numcat = cvm.numcat(+)
                      AND a.codagce = c.codagce
                      AND a.codclt = d.codclt
                      --and a.NUMCAT in (71,72,73,78,86,87,85,74,75,83,82,76,92/*70,77,93*/)
                      AND a.numcat IN (71,
                                       72,
                                       73,
                                       74,
                                       75,
                                       76,
                                       78,
                                       82,
                                       83,
                                       85,
                                       86,
                                       87,
                                       92)
                      AND a.dannulat IS NULL
                      AND a.dateff IS NOT NULL
                      AND NVL (a.etat, 'X') <> 'I')
        LOOP
            r_tablecrm.numcat := i.numcat;
            r_tablecrm.libnumcat := i.libelle;
            r_tablecrm.agce := LPAD (i.codagce, 3, '0');
            r_tablecrm.libagce := i.nomagce;
            r_tablecrm.numcpt := i.rib;
            r_tablecrm.nadh := i.nadhes;
            r_tablecrm.datesous := i.dateff;
            r_tablecrm.ntsmt := i.ntsmtb;

            r_tablecrm.dateexpiration := i.dexpcont;
            r_tablecrm.minverslibre := i.minverslibre;
            r_tablecrm.minversprogm := i.minversprogm;
            r_tablecrm.minversprogt := i.minversprogt;
            r_tablecrm.minversproga := i.minversproga;


            IF i.dannulat IS NOT NULL
            THEN
                r_tablecrm.statctr := 0;
                r_tablecrm.libstatctr := 'ANNULE';
            ELSIF i.pgmverst = 'Suspendu'
            THEN
                r_tablecrm.statctr := 2;
                r_tablecrm.libstatctr := i.pgmverst;
            ELSE
                r_tablecrm.statctr := 1;
                r_tablecrm.libstatctr := i.pgmverst;
            END IF;

            r_tablecrm.date_annul := i.dannulat;
            r_tablecrm.nompsous := i.nom_prenom;
            r_tablecrm.dnsous := i.datnaiss;
            r_tablecrm.mtcot := i.mtcot;
            r_tablecrm.freq := i.freq;
            r_tablecrm.cin :=
                REPLACE (REPLACE (UPPER (i.cin), ' ', ''), '.', '');
            r_tablecrm.typeproduit := typeproduit (i.numcat);
            r_tablecrm.num_tel := TRIM (i.num_tel_mobil);
            r_tablecrm.per_email := TRIM (i.per_email_mobil);
            r_tablecrm.code_clt_sgma := i.code_clt_sgma;


            IF i.numcat IN (71,
                            72,
                            73,
                            78,
                            85,
                            86,
                            87,
                            92)
            THEN
                -- R_TABLECRM.TYPEPRODUIT:='Epargne';
                r_tablecrm.garopt := i.opt;

                FOR j
                    IN (SELECT *
                        FROM bversem
                        WHERE     numcat = i.numcat
                              AND nadhes = i.nadhes
                              AND NVL (typ, 'X') = 'L'
                              AND datencais IS NOT NULL
                              AND datannul IS NULL)
                LOOP
                    IF    j.echeance > r_tablecrm.datedvl
                       OR r_tablecrm.datedvl IS NULL
                    THEN
                        r_tablecrm.mtdervl := j.mtvers;
                        r_tablecrm.datedvl := j.echeance;
                    END IF;
                END LOOP;

                SELECT SUM (mtvers)
                INTO r_tablecrm.cumvp
                FROM bversem v2
                WHERE     v2.numcat = i.numcat
                      AND v2.nadhes = i.nadhes
                      AND v2.datencais IS NOT NULL
                      AND v2.datannul IS NULL
                      AND NVL (v2.typ, 'X') <> 'L';


                BEGIN
                    SELECT MAX (p.datepm)
                    INTO r_tablecrm.datencou
                    FROM bprovis_mobil p
                    WHERE p.numcat = i.numcat AND p.nadhes = i.nadhes;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        r_tablecrm.datencou := NULL;
                END;

                BEGIN
                    SELECT SUM (p.vprim), SUM (mtavance_ttc)
                    INTO r_tablecrm.mtencour, r_tablecrm.mtavce
                    FROM bprovis_mobil p
                    WHERE     p.numcat = i.numcat
                          AND p.nadhes = i.nadhes
                          AND p.datepm = r_tablecrm.datencou;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        r_tablecrm.mtencour := 0;
                        r_tablecrm.mtavce := 0;
                END;

                -------------------------------------------------------------------------------------
                SELECT SUM (r.mtrach), COUNT (1)
                INTO r_tablecrm.mtrachp, r_tablecrm.nbrachat
                FROM brachat r
                WHERE     r.numcat = i.numcat
                      AND r.nadhes = i.nadhes
                      AND r.typ = 'RP';

                -------------------------------------------------------------------------------------
                /* select sum(a.MTAVANCE) into R_TABLECRM.MTAVCE   from bavances a
                 where a.numcat = I.numcat and a.nadhes = I.nadhes and a.TYP = 'A';*/
                -------------------------------------------------------------------------------------
                BEGIN
                    SELECT r.clbenef1, r.clbenef2, r.clbenef3
                    INTO r_tablecrm.clbenef1,
                         r_tablecrm.clbenef2,
                         r_tablecrm.clbenef3
                    FROM bbenefic r
                    WHERE     r.numcat = i.numcat
                          AND r.nadhes = i.nadhes
                          AND ROWNUM = 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        r_tablecrm.clbenef1 := 0;
                        r_tablecrm.clbenef2 := 0;
                        r_tablecrm.clbenef3 := 0;
                END;
            END IF;

            IF i.numcat IN (76, 82)
            THEN
                --R_TABLECRM.TYPEPRODUIT:='Pr�voyance_Famille';

                BEGIN
                    SELECT f.primhosp, f.primcpl, f.primij
                    INTO wmtbase, wmtcompl, wmtij
                    FROM bfamille f
                    WHERE     f.numcat = i.numcat
                          AND f.nadhes = i.nadhes
                          AND UPPER (f.lienfam) = 'A'
                          AND f.ddepfam IS NULL;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        wmtbase := 0;
                        wmtcompl := 0;
                        wmtij := 0;
                END;

                IF wmtbase <> 0
                THEN
                    IF i.numcat = 76
                    THEN
                        r_tablecrm.garchoix := 'Garantie de base';
                    ELSE
                        r_tablecrm.garchoix := 'Garantie DA';
                    END IF;
                END IF;

                IF wmtcompl <> 0
                THEN
                    r_tablecrm.garcompl := 'O';
                END IF;

                IF wmtij <> 0
                THEN
                    r_tablecrm.ij := 'O';
                    r_tablecrm.mtij := wmtij;
                END IF;

                ------------------------------------------------------------------
                wii := 0;

                FOR j
                    IN (SELECT *
                        FROM bfamille a
                        WHERE     a.numcat = i.numcat
                              AND nadhes = i.nadhes
                              AND wii < 8
                              AND ddepfam IS NULL
                        ORDER BY numcat, nadhes, numfam)
                LOOP
                    wii := wii + 1;

                    IF wii = 1
                    THEN
                        r_tablecrm.npass1 :=
                               TRIM (j.tnom)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prenfam);
                        r_tablecrm.dnass1 := j.dnaisfam;
                        r_tablecrm.lnass1 := j.lienfam;
                        r_tablecrm.primeass1 :=
                              NVL (j.primhosp, 0)
                            + NVL (j.primcpl, 0)
                            + NVL (j.primij, 0);
                    ELSIF wii = 2
                    THEN
                        r_tablecrm.npass2 :=
                               TRIM (j.tnom)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prenfam);
                        r_tablecrm.dnass2 := j.dnaisfam;
                        r_tablecrm.lnass2 := j.lienfam;
                        r_tablecrm.primeass2 :=
                              NVL (j.primhosp, 0)
                            + NVL (j.primcpl, 0)
                            + NVL (j.primij, 0);
                    ELSIF wii = 3
                    THEN
                        r_tablecrm.npass3 :=
                               TRIM (j.tnom)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prenfam);
                        r_tablecrm.dnass3 := j.dnaisfam;
                        r_tablecrm.lnass3 := j.lienfam;
                        r_tablecrm.primeass3 :=
                              NVL (j.primhosp, 0)
                            + NVL (j.primcpl, 0)
                            + NVL (j.primij, 0);
                    ELSIF wii = 4
                    THEN
                        r_tablecrm.npass4 :=
                               TRIM (j.tnom)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prenfam);
                        r_tablecrm.dnass4 := j.dnaisfam;
                        r_tablecrm.lnass4 := j.lienfam;
                        r_tablecrm.primeass4 :=
                              NVL (j.primhosp, 0)
                            + NVL (j.primcpl, 0)
                            + NVL (j.primij, 0);
                    ELSIF wii = 5
                    THEN
                        r_tablecrm.npass5 :=
                               TRIM (j.tnom)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prenfam);
                        r_tablecrm.dnass5 := j.dnaisfam;
                        r_tablecrm.lnass5 := j.lienfam;
                        r_tablecrm.primeass5 :=
                              NVL (j.primhosp, 0)
                            + NVL (j.primcpl, 0)
                            + NVL (j.primij, 0);
                    ELSIF wii = 6
                    THEN
                        r_tablecrm.npass6 :=
                               TRIM (j.tnom)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prenfam);
                        r_tablecrm.dnass6 := j.dnaisfam;
                        r_tablecrm.lnass6 := j.lienfam;
                        r_tablecrm.primeass6 :=
                              NVL (j.primhosp, 0)
                            + NVL (j.primcpl, 0)
                            + NVL (j.primij, 0);
                    ELSIF wii = 7
                    THEN
                        r_tablecrm.npass7 :=
                               TRIM (j.tnom)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prenfam);
                        r_tablecrm.dnass7 := j.dnaisfam;
                        r_tablecrm.lnass7 := j.lienfam;
                        r_tablecrm.primeass7 :=
                              NVL (j.primhosp, 0)
                            + NVL (j.primcpl, 0)
                            + NVL (j.primij, 0);
                    ELSIF wii = 8
                    THEN
                        r_tablecrm.npass8 :=
                               TRIM (j.tnom)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prenfam);
                        r_tablecrm.dnass8 := j.dnaisfam;
                        r_tablecrm.lnass8 := j.lienfam;
                        r_tablecrm.primeass8 :=
                              NVL (j.primhosp, 0)
                            + NVL (j.primcpl, 0)
                            + NVL (j.primij, 0);
                    ELSE
                        EXIT;
                    END IF;
                ------------------------------------------------------------------
                END LOOP;
            END IF;

            IF i.numcat IN (                                        /*70,77,*/
                            74, 75, 83                              /*,89,93*/
                                      )
            THEN
                -- R_TABLECRM.TYPEPRODUIT:='Pr�voyance';
                r_tablecrm.capital := i.capital;
                r_tablecrm.ppippo := i.ppippo;
            END IF;

            -------------------------------------Versement--------------------------------------------------
            FOR j
                IN (SELECT *
                    FROM (SELECT DECODE (datencais, NULL, 'IMPAYE', 'PAYE')
                                     etat,
                                 a.*
                          FROM bversem a
                          WHERE     numcat = i.numcat
                                AND nadhes = i.nadhes
                                AND datannul IS NULL
                          ORDER BY echeance DESC)
                    WHERE ROWNUM < 13)
            LOOP
                r_crm_versement.numcat := i.numcat;
                r_crm_versement.numbas := i.nadhes;
                r_crm_versement.echeance := j.echeance;
                r_crm_versement.date_encais := j.datencais;
                r_crm_versement.etat := j.etat;
                r_crm_versement.mtvers := j.mtvers;
                r_crm_versement.modpayement := 'prelevement';

                INSERT INTO crm_versement
                VALUES r_crm_versement;

                r_crm_versement := r_crm_versement_null;
            END LOOP;

            ----------------------------------------------------------------------------------------------

            INSERT INTO tablecrm
            VALUES r_tablecrm;

            r_tablecrm := r_tablecrm_null;

            COMMIT;
        -------------------------------------------------------------------------------------
        END LOOP;
    -----------------------------------------
    END;

    --------------------------------------------------------------------------------
    ----------  CRM_SIS ------------------------------------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE proc_tabcrm_sis
    IS
        r_tablecrm        tablecrm%ROWTYPE;
        r_tablecrm_null   tablecrm%ROWTYPE;
    BEGIN
        FOR i
            IN (SELECT gr.*,
                       b.libelle_client libelle,               /* c.NOMAGCE,*/
                       DECODE (status_cod,  'INF', 1,  'SUS', 2,  0) statctr,
                       a.pm,
                       pm_saving_effec_dte,
                       avance_ttc,
                       minverslibre,
                       minversprogm,
                       minversprogt,
                       minversproga,
                       DECODE (ntsmt, 'O', 1, 0) ntsmtb
                FROM iia.v_pm_dh_support a,
                     iia.v_grc_globale_personne_mobile gr,
                     categori b                                /*, bagence c*/
                               ,
                     categ_vers_mobil cvm
                WHERE     a.cat(+) = gr.code_produit
                      AND a.nadhes(+) = gr.n__adhesion_n_contrat
                      AND gr.code_produit = b.numcat
                      AND UPPER(TRIM(gr.STATUS_COD)) NOT IN ('DBO', 'CLO')
                      AND gr.code_produit <> 205
                      AND gr.code_produit = cvm.numcat(+) --and   decode(gr.Code_agence,'SGMB',0,gr.Code_agence) = c.codagce
                                                         --and   gr.libelle_garantie=decode(gr.Code_produit,206,'D�c�s','Plancher')
                                                         )
        LOOP
            --R_TABLECRM.TYPEPRODUIT:='VMS';
            r_tablecrm.typeproduit := typeproduit (i.code_produit);
            r_tablecrm.numcat := i.code_produit;
            r_tablecrm.libnumcat := i.libelle;
            r_tablecrm.agce := LPAD (i.code_agence, 3, '0');
            r_tablecrm.libagce := i.libelle_agence                 /*NOMAGCE*/
                                                  ;
            r_tablecrm.numcpt := i.n_compte_bancaire_pp;
            r_tablecrm.nadh := i.n__adhesion_n_contrat;
            r_tablecrm.datesous := i.date_effet_du_contrat;
            r_tablecrm.statctr := i.statctr;
            r_tablecrm.cin :=
                REPLACE (REPLACE (UPPER (i.n_cin), ' ', ''), '.', '');
            r_tablecrm.num_tel := TRIM (i.num_tel_mobil);
            r_tablecrm.per_email := TRIM (i.per_email_mobil);


            r_tablecrm.libstatctr := i.status_cod;



            r_tablecrm.nompsous :=
                   NVL (TRIM (i.nom_de_adherent), ' ')
                || ' '
                || NVL (TRIM (i.prenom_de_adherent), ' ');
            r_tablecrm.dnsous := i.date_naissance;

            r_tablecrm.mtencour := i.pm;
            r_tablecrm.datencou := i.pm_saving_effec_dte;
            r_tablecrm.ntsmt := i.ntsmtb;

            IF i.code_produit IN (200,
                                  201,
                                  205,
                                  206)
            THEN
                r_tablecrm.code_clt_sgma := i.code_clt_sgma;
            END IF;

            r_tablecrm.dateexpiration := NULL;
            r_tablecrm.minverslibre := i.minverslibre;
            r_tablecrm.minversprogm := i.minversprogm;
            r_tablecrm.minversprogt := i.minversprogt;
            r_tablecrm.minversproga := i.minversproga;


            -----------------------
            ---  Total des primes
            -----------------------
            SELECT SUM (fnd_inv_div_com_mnt)
            INTO r_tablecrm.cumvp
            FROM v_grc_tot_prime
            WHERE     contract_num = i.n__adhesion_n_contrat
                  AND ref_product_id = i.code_produit;

            -----------------------
            ---  Total des Rachats
            -----------------------
            SELECT SUM (fnd_inv_div_net_mnt), MAX (effec_dte), COUNT (1)
            INTO r_tablecrm.mtrachp, r_tablecrm.daterach, r_tablecrm.nbrachat
            FROM v_grc_tot_rt
            WHERE     contract_num = i.n__adhesion_n_contrat
                  AND ref_product_id = i.code_produit;

            IF NVL (r_tablecrm.mtrachp, 0) = 0
            THEN
                r_tablecrm.daterach := NULL;
            END IF;

            r_tablecrm.mtavce := i.avance_ttc;

            IF NVL (i.avance_ttc, 0) > 0
            THEN
                SELECT MAX (dateoctr)
                INTO r_tablecrm.dateavce
                FROM v_grc_tot_av
                WHERE     adherent = i.n__adhesion_n_contrat
                      AND categorie = i.code_produit;
            ELSE
                r_tablecrm.dateavce := NULL;
            END IF;


            INSERT INTO crm_pm_uc_support (rang,
                                           pm_saving_effec_dte,
                                           numcat,
                                           nadh,
                                           ref_support_id,
                                           support,
                                           pm_val)
                SELECT ROWNUM,
                       pm_saving_effec_dte,
                       cat,
                       nadhes,
                       id_support,
                       support,
                       pm_val
                FROM v_pm_uc_support
                WHERE     cat = i.code_produit
                      AND nadhes = i.n__adhesion_n_contrat;

            INSERT INTO tablecrm
            VALUES r_tablecrm;

            r_tablecrm := r_tablecrm_null;

            COMMIT;
        END LOOP;
    END;


    --------------------------------------------------------------------------------
    ----------  CRM_IND ------------------------------------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE proc_tabcrm_ind
    IS
        r_tablecrm             tablecrm%ROWTYPE;
        r_tablecrm_null        tablecrm%ROWTYPE;

        r_crm_sinistre         crm_sinistre%ROWTYPE;
        r_crm_sinistre_null    crm_sinistre%ROWTYPE;

        r_crm_versement        crm_versement%ROWTYPE;
        r_crm_versement_null   crm_versement%ROWTYPE;


        wii                    NUMBER;
    BEGIN
        FOR i
            IN (SELECT a.*,
                       DECODE (modpbas, 'U', '', modpbas)
                           wfreqpp,
                       DECODE (modpbas, 'U', 0, ppi)
                           wmtpp,
                       c.libelle_client
                           libelle,
                       DECODE (a.numcat,  95, a.capbas,  68, a.capbas,  0)
                           capitalwiqaya,
                       DECODE (dasuspen, NULL, 1, 2)
                           wstatctr,
                       DECODE (dasuspen, NULL, 'VIGUEUR', 'Suspendu')
                           libelwstatctr,
                       b.tnomass,
                       b.nomass,
                       b.preass,
                       b.dnaisass,
                       DECODE (a.numcat,
                               65, NVL (a.ppi, 0) + NVL (a.pui, 0),
                               63, NVL (a.ppi, 0) + NVL (a.pui, 0),
                               primebas)
                           primecontrat,
                          TRIM (b.tnomass)
                       || ' '
                       || TRIM (b.nomass)
                       || ' '
                       || TRIM (b.preass)
                           nom_prenom,
                       b.cin --,nvl(trim(b.ind1ass),' ')||nvl(trim(b.tel1ass),' ') tel
                            ,
                       b.per_email_mobil,
                       b.num_tel_mobil,
                       DECODE (UPPER (TRIM (nantissement)), 'O', 1, 0)
                           ntsmt
                FROM base a, assure b, categori c
                WHERE     a.numass = b.numass
                      AND a.numcat = c.numcat
                      --and  a.numcat in (95,65,63,68)
                      AND a.numcat IN (1,
                                       2,
                                       6,
                                       11,
                                       15,
                                       16,
                                       18,
                                       19,
                                       20,
                                       21,
                                       22,
                                       23,
                                       26,
                                       27,
                                       32,
                                       33,
                                       34,
                                       40,
                                       47,
                                       48,
                                       53,
                                       58,
                                       60,
                                       63,
                                       65,
                                       68,
                                       95)
                      AND deffbas IS NOT NULL
                      AND datannul IS NULL)
        LOOP
            r_tablecrm.numcat := i.numcat;
            r_tablecrm.libnumcat := i.libelle;
            r_tablecrm.agce := LPAD (SUBSTR (i.nucptban, 9, 3), 3, '0');
            r_tablecrm.libagce := '';
            r_tablecrm.numcpt := TRIM (i.nucptban);                  --I.rip ;
            r_tablecrm.nadh := i.numbas;
            r_tablecrm.datesous := i.deffbas;
            r_tablecrm.statctr := i.wstatctr;
            r_tablecrm.libstatctr := i.libelwstatctr;


            r_tablecrm.date_annul := i.datannul;
            r_tablecrm.nompsous := i.nom_prenom;
            r_tablecrm.dnsous := i.dnaisass;
            r_tablecrm.mtcot := i.primecontrat;
            r_tablecrm.freq := i.modpbas;
            r_tablecrm.cin :=
                REPLACE (REPLACE (UPPER (i.cin), ' ', ''), '.', '');
            --R_TABLECRM.num_tel:=trim(I.tel);
            r_tablecrm.num_tel := TRIM (i.num_tel_mobil);
            r_tablecrm.per_email := TRIM (i.per_email_mobil);

            r_tablecrm.typeproduit := typeproduit (i.numcat);

            r_tablecrm.capital := i.capitalwiqaya;
            r_tablecrm.ntsmt := i.ntsmt;

            IF i.numcat = 95
            THEN
                r_tablecrm.code_clt_sgma := i.code_clt_sgma;
            END IF;

            IF i.numcat IN (63,
                            65,
                            1,
                            11,
                            27)
            THEN
                --R_TABLECRM.TYPEPRODUIT:='Epargne';
                FOR j
                    IN (SELECT *
                        FROM ppipui a
                        WHERE     a.numbas = i.numbas
                              AND dacapital IS NOT NULL
                              AND datann IS NULL
                              AND NVL (code, 'X') = 'U')
                LOOP
                    IF    j.echeance > r_tablecrm.datedvl
                       OR r_tablecrm.datedvl IS NULL
                    THEN
                        r_tablecrm.datedvl := j.echeance;        --WDATEDVLEnc
                        r_tablecrm.mtdervl := j.montant;            --WMTVLEnc
                    END IF;
                END LOOP;

                BEGIN
                    SELECT MAX (datcalc)
                    INTO r_tablecrm.datencou                         --WDATEPM
                    FROM pmprcl_mobil
                    WHERE police = i.numbas
                        AND cat = i.numcat;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        r_tablecrm.datencou := NULL;
                END;

                BEGIN
                    SELECT SUM (NVL (p.vprimps, 0) + NVL (p.vprimpp, 0)),
                           SUM (mtavance_ttc)
                    INTO r_tablecrm.mtencour, r_tablecrm.mtavce       --WVPRIM
                    FROM pmprcl_mobil p
                    WHERE     p.police = i.numbas
                          AND p.datcalc = r_tablecrm.datencou
                          AND p.cat = i.numcat;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        r_tablecrm.mtencour := 0;
                        r_tablecrm.mtavce := 0;
                END;

                SELECT SUM (montant)
                INTO r_tablecrm.cumvp                                 --WCUMVP
                FROM ppipui a
                WHERE     a.numbas = i.numbas
                      AND dacapital IS NOT NULL
                      AND datann IS NULL         /*and  nvl(code,'X') <> 'U'*/
                                        ;

                SELECT SUM (mtrach), COUNT (1)
                INTO r_tablecrm.mtrachp, r_tablecrm.nbrachat            --MTRP
                FROM rachatpc a
                WHERE a.police = i.numbas AND TRIM (typ) = 'RP';
            /*select sum(mtbravce) into R_TABLECRM.MTAVCE --MTAVCE
            from avancepc a where a.police=I.numbas and typ='A';*/

            END IF;

            IF i.numcat IN (68,
                            95,
                            1,
                            2,
                            6,
                            11,
                            18,
                            19,
                            20,
                            23,
                            26,
                            40,
                            47,
                            48,
                            53,
                            58,
                            60)
            THEN
                --R_TABLECRM.TYPEPRODUIT:='Pr�voyance';
                wii := 0;

                FOR j
                    IN (SELECT a.*, primettc
                        FROM famille a, assudans b
                        WHERE     a.numass = b.numass
                              AND a.numfam = b.numfam
                              AND a.numass = i.numass
                              AND wii < 8)
                LOOP
                    wii := wii + 1;

                    IF wii = 1
                    THEN
                        r_tablecrm.npass1 :=
                               TRIM (j.tnomfam)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prefam);
                        r_tablecrm.dnass1 := j.dnaisfam;
                        r_tablecrm.lnass1 := j.lienfam;
                        r_tablecrm.primeass1 := j.primettc;
                    ELSIF wii = 2
                    THEN
                        r_tablecrm.npass2 :=
                               TRIM (j.tnomfam)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prefam);
                        r_tablecrm.dnass2 := j.dnaisfam;
                        r_tablecrm.lnass2 := j.lienfam;
                        r_tablecrm.primeass2 := j.primettc;
                    ELSIF wii = 3
                    THEN
                        r_tablecrm.npass3 :=
                               TRIM (j.tnomfam)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prefam);
                        r_tablecrm.dnass3 := j.dnaisfam;
                        r_tablecrm.lnass3 := j.lienfam;
                        r_tablecrm.primeass3 := j.primettc;
                    ELSIF wii = 4
                    THEN
                        r_tablecrm.npass4 :=
                               TRIM (j.tnomfam)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prefam);
                        r_tablecrm.dnass4 := j.dnaisfam;
                        r_tablecrm.lnass4 := j.lienfam;
                        r_tablecrm.primeass4 := j.primettc;
                    ELSIF wii = 5
                    THEN
                        r_tablecrm.npass5 :=
                               TRIM (j.tnomfam)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prefam);
                        r_tablecrm.dnass5 := j.dnaisfam;
                        r_tablecrm.lnass5 := j.lienfam;
                        r_tablecrm.primeass5 := j.primettc;
                    ELSIF wii = 6
                    THEN
                        r_tablecrm.npass6 :=
                               TRIM (j.tnomfam)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prefam);
                        r_tablecrm.dnass6 := j.dnaisfam;
                        r_tablecrm.lnass6 := j.lienfam;
                        r_tablecrm.primeass6 := j.primettc;
                    ELSIF wii = 7
                    THEN
                        r_tablecrm.npass7 :=
                               TRIM (j.tnomfam)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prefam);
                        r_tablecrm.dnass7 := j.dnaisfam;
                        r_tablecrm.lnass7 := j.lienfam;
                        r_tablecrm.primeass7 := j.primettc;
                    ELSIF wii = 8
                    THEN
                        r_tablecrm.npass8 :=
                               TRIM (j.tnomfam)
                            || ' '
                            || TRIM (j.nomfam)
                            || ' '
                            || TRIM (j.prefam);
                        r_tablecrm.dnass8 := j.dnaisfam;
                        r_tablecrm.lnass8 := j.lienfam;
                        r_tablecrm.primeass8 := j.primettc;
                    ELSE
                        EXIT;
                    END IF;
                END LOOP;

                ------------------------------------------------------------------
                FOR k
                    IN (SELECT *
                        FROM v_crm_sinistre a
                        WHERE     a.numbas = i.numbas
                              AND a.numass = i.numass
                              AND a.numcat = i.numcat)
                LOOP
                    r_crm_sinistre.numbas := k.numbas;
                    r_crm_sinistre.numcatbase := i.numcat;
                    r_crm_sinistre.libcatbase := TRIM (i.libelle);
                    r_crm_sinistre.numcatadt := k.numcat;
                    r_crm_sinistre.libcatadt := TRIM (k.libelle);
                    r_crm_sinistre.typeprod := 'I';
                    r_crm_sinistre.numass := k.numass;
                    r_crm_sinistre.nomass := TRIM (k.nomass);
                    r_crm_sinistre.etatdossier := k.etatdossier;
                    r_crm_sinistre.nomfam := TRIM (k.nomfam);
                    r_crm_sinistre.lien := k.lien;
                    r_crm_sinistre.datesin := k.datsin;
                    r_crm_sinistre.numdoss := k.numdos;
                    r_crm_sinistre.datedecl := k.datdcl;
                    r_crm_sinistre.motif := TRIM (k.libel);
                    r_crm_sinistre.mtsinistre := k.mtsinistre;
                    r_crm_sinistre.dateoper := k.dateoper;

                    r_crm_sinistre.frais_engage := k.frais_engage;
                    r_crm_sinistre.medecin_trait := TRIM (k.medecin_trait);
                    r_crm_sinistre.observation := TRIM (k.observation);
                    r_crm_sinistre.nature_soins := TRIM (k.nature_soins);

                    INSERT INTO crm_sinistre
                    VALUES r_crm_sinistre;

                    r_crm_sinistre := r_crm_sinistre_null;
                END LOOP;
            END IF;


            -------------------------------------Versement--------------------------------------------------
            FOR j
                IN (SELECT *
                    FROM (SELECT DECODE (dencaiss, NULL, 'IMPAYE', 'PAYE')
                                     etat,
                                 a.*
                          FROM quitance a
                          WHERE     a.numbas = i.numbas
                                AND a.numcat = i.numcat
                                AND dateann IS NULL
                          ORDER BY ddebut DESC)
                    WHERE ROWNUM < 13)
            LOOP
                r_crm_versement.numcat := i.numcat;
                r_crm_versement.numbas := i.numbas;
                r_crm_versement.echeance := j.ddebut;
                r_crm_versement.date_encais := j.dencaiss;
                r_crm_versement.etat := j.etat;
                r_crm_versement.mtvers := j.pritot;

                IF     NVL (i.vir, 'X') = 'P'
                   AND NVL (j.codenv, ' ') NOT IN ('E', 'P')
                THEN
                    r_crm_versement.modpayement := 'prelevement';
                ELSE
                    r_crm_versement.modpayement := 'cheque';
                END IF;

                INSERT INTO crm_versement
                VALUES r_crm_versement;

                r_crm_versement := r_crm_versement_null;
            END LOOP;

            ----------------------------------------------------------------------------------------------


            INSERT INTO tablecrm
            VALUES r_tablecrm;

            r_tablecrm := r_tablecrm_null;

            COMMIT;
        END LOOP;
    END;

    -------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------
    PROCEDURE proc_tabcrm_his
    IS
        r_tablecrm             tablecrm%ROWTYPE;
        r_tablecrm_null        tablecrm%ROWTYPE;

        r_crm_sinistre         crm_sinistre%ROWTYPE;
        r_crm_sinistre_null    crm_sinistre%ROWTYPE;

        r_crm_versement        crm_versement%ROWTYPE;
        r_crm_versement_null   crm_versement%ROWTYPE;

        wii                    NUMBER;
    BEGIN
        FOR i IN (SELECT * FROM sehha.v_tablgrc_his)
        LOOP
            --R_TABLECRM.TYPEPRODUIT:='SEHHA';
            r_tablecrm.typeproduit := typeproduit (i.prd_code);
            r_tablecrm.numcat := i.prd_code;
            r_tablecrm.libnumcat := i.prd_libelle;
            r_tablecrm.agce := i.code_agence;
            r_tablecrm.libagce := i.libelle_agence;
            r_tablecrm.numcpt := i.ctr_num_compte;
            r_tablecrm.nadh := i.ctr_num_contrat;
            r_tablecrm.datesous := i.ctr_date_effet;
            r_tablecrm.statctr := i.ctr_statut;
            r_tablecrm.libstatctr := i.statut_contrat;


            r_tablecrm.date_annul := i.ctr_dt_annulation;
            r_tablecrm.nompsous := i.nom_prenom;
            r_tablecrm.dnsous := i.date_naissance;
            r_tablecrm.mtcot := i.qui_prime_ttc;
            r_tablecrm.freq := i.mp;
            r_tablecrm.cin :=
                REPLACE (REPLACE (UPPER (i.cin), ' ', ''), '.', '');
            r_tablecrm.num_tel := TRIM (i.num_tel);
            r_tablecrm.per_email := TRIM (i.per_email);

            IF i.prd_code IN (300,
                              301,
                              302,
                              303,
                              305,
                              306)
            THEN
                r_tablecrm.code_clt_sgma := i.code_clt_sgma;
            END IF;

            ---------------------------------------------------------------------------------------------------------
            wii := 0;

            FOR j IN (SELECT a.*
                      FROM sehha.v_tablgrc_his_famille a
                      WHERE i.ctr_id = a.ctr_id AND wii < 8)
            LOOP
                wii := wii + 1;

                IF wii = 1
                THEN
                    r_tablecrm.npass1 := j.npass;
                    r_tablecrm.dnass1 := j.dnass1;
                    r_tablecrm.lnass1 := j.lnass;
                    r_tablecrm.primeass1 := j.pri_prime_ttc;
                ELSIF wii = 2
                THEN
                    r_tablecrm.npass2 := j.npass;
                    r_tablecrm.dnass2 := j.dnass1;
                    r_tablecrm.lnass2 := j.lnass;
                    r_tablecrm.primeass2 := j.pri_prime_ttc;
                ELSIF wii = 3
                THEN
                    r_tablecrm.npass3 := j.npass;
                    r_tablecrm.dnass3 := j.dnass1;
                    r_tablecrm.lnass3 := j.lnass;
                    r_tablecrm.primeass3 := j.pri_prime_ttc;
                ELSIF wii = 4
                THEN
                    r_tablecrm.npass4 := j.npass;
                    r_tablecrm.dnass4 := j.dnass1;
                    r_tablecrm.lnass4 := j.lnass;
                    r_tablecrm.primeass4 := j.pri_prime_ttc;
                ELSIF wii = 5
                THEN
                    r_tablecrm.npass5 := j.npass;
                    r_tablecrm.dnass5 := j.dnass1;
                    r_tablecrm.lnass5 := j.lnass;
                    r_tablecrm.primeass5 := j.pri_prime_ttc;
                ELSIF wii = 6
                THEN
                    r_tablecrm.npass6 := j.npass;
                    r_tablecrm.dnass6 := j.dnass1;
                    r_tablecrm.lnass6 := j.lnass;
                    r_tablecrm.primeass6 := j.pri_prime_ttc;
                ELSIF wii = 7
                THEN
                    r_tablecrm.npass7 := j.npass;
                    r_tablecrm.dnass7 := j.dnass1;
                    r_tablecrm.lnass7 := j.lnass;
                    r_tablecrm.primeass7 := j.pri_prime_ttc;
                ELSIF wii = 8
                THEN
                    r_tablecrm.npass8 := j.npass;
                    r_tablecrm.dnass8 := j.dnass1;
                    r_tablecrm.lnass8 := j.lnass;
                    r_tablecrm.primeass8 := j.pri_prime_ttc;
                ELSE
                    EXIT;
                END IF;
            ------------------------------------------------------------------
            END LOOP;

            ------------------------------------------------------------------------------------
            ------------------------------------------------------------------
            FOR k IN (SELECT *
                      FROM sehha.v_crm_sinistre_his a
                      WHERE a.num_contrat = i.ctr_num_contrat)
            LOOP
                r_crm_sinistre.numbas := k.num_contrat;
                r_crm_sinistre.numcatbase := i.prd_code;
                r_crm_sinistre.libcatbase := TRIM (i.prd_libelle);
                r_crm_sinistre.numcatadt := k.prd_code;
                r_crm_sinistre.libcatadt := TRIM (k.prd_libelle);
                r_crm_sinistre.typeprod := 'H';
                r_crm_sinistre.numass := k.id_pres;
                r_crm_sinistre.nomass := TRIM (k.nom_assure);
                r_crm_sinistre.etatdossier := k.libelle;
                r_crm_sinistre.nomfam := TRIM (k.nom_beneficiaire);
                r_crm_sinistre.lien := k.ben_type_beneficiaire;
                r_crm_sinistre.datesin := k.date_ouverture;
                r_crm_sinistre.numdoss := k.num_dossier;
                r_crm_sinistre.datedecl := k.date_information;
                r_crm_sinistre.motif :=
                    TRIM (complement_info_his (k.id_pres)); --trim(k.libelle);
                r_crm_sinistre.mtsinistre := k.montant;
                r_crm_sinistre.dateoper := k.dateoper;

                r_crm_sinistre.frais_engage := k.frais_engage;
                r_crm_sinistre.medecin_trait := k.medecin_trait;
                r_crm_sinistre.observation := k.observation;
                r_crm_sinistre.nature_soins := k.nature_soins;

                INSERT INTO crm_sinistre
                VALUES r_crm_sinistre;

                r_crm_sinistre := r_crm_sinistre_null;
            END LOOP;

            -------------------------------------Versement--------------------------------------------------
            FOR j
                IN (SELECT *
                    FROM (SELECT DECODE (qui_date_reglement,
                                         NULL, 'IMPAYE',
                                         'PAYE') etat,
                                 DECODE (i.ctr_mode_paiement,
                                         0, 'cheque',
                                         1, 'Esp�ce',
                                         2, 'prelevement',
                                         i.ctr_mode_paiement) mp,
                                 a.*
                          FROM sehha.v_his_quitance a
                          WHERE a.ctr_num_contrat = i.ctr_num_contrat
                          ORDER BY qui_deb_periode DESC)
                    WHERE ROWNUM < 13)
            LOOP
                r_crm_versement.numcat := i.prd_code;
                r_crm_versement.numbas := i.ctr_num_contrat;
                r_crm_versement.echeance := j.qui_deb_periode;
                r_crm_versement.date_encais := j.qui_date_reglement;
                r_crm_versement.etat := j.etat;
                r_crm_versement.mtvers := j.qui_prime_ttc;
                r_crm_versement.modpayement := j.mp;

                INSERT INTO crm_versement
                VALUES r_crm_versement;

                r_crm_versement := r_crm_versement_null;
            END LOOP;

            ----------------------------------------------------------------------------------------------

            INSERT INTO tablecrm
            VALUES r_tablecrm;

            r_tablecrm := r_tablecrm_null;
            COMMIT;
        END LOOP;
    END;

    -------------------------------------------------------------------------------------------------------------

    FUNCTION typeproduit (p_numcat NUMBER)
        RETURN VARCHAR2
    IS
        p_typproduit   VARCHAR2 (20);
    BEGIN
        p_typproduit := p_numcat;

        IF p_numcat IN (3,
                        10,
                        23,
                        24,
                        26,
                        35,
                        36,
                        37,
                        38,
                        39,
                        42,
                        50,
                        51,
                        54,
                        55,
                        56,
                        61,
                        76,
                        300,
                        301,
                        302,
                        303,
                        304,
                        305,
                        306)
        THEN
            p_typproduit := 'SANTE';
        END IF;

        IF p_numcat IN (2,
                        5,
                        6,
                        9,
                        18,
                        19,
                        33,
                        34,
                        40,
                        47,
                        48,
                        49,
                        53,
                        58,
                        60,
                        68,
                        74,
                        75,
                        83,
                        95,
                        15,
                        16,
                        82)
        THEN
            p_typproduit := 'PREVOYANCE';
        END IF;

        IF p_numcat IN (32,
                        63,
                        71,
                        72,
                        73,
                        78,
                        85,
                        86,
                        92,
                        200,
                        205,
                        73,
                        78,
                        86,
                        1,
                        20,
                        206)
        THEN
            p_typproduit := 'EPARGNE';
        END IF;

        IF p_numcat IN (1,
                        11,
                        20,
                        21,
                        22,
                        27,
                        65,
                        87,
                        201,
                        21,
                        22,
                        27,
                        87,
                        11,
                        64)
        THEN
            p_typproduit := 'RETRAITE';
        END IF;

        --if p_numcat in (21,22,27,87,11) then p_typproduit:='RETRAITE COMPLEMT'; end if;
        RETURN p_typproduit;
    END;

    FUNCTION complement_info_his (p_id_pres NUMBER)
        RETURN VARCHAR2
    IS
        v_complement_info   VARCHAR2 (2000) := ' ';
    BEGIN
        FOR i IN (SELECT *
                  FROM sehha.v_complement_sinistre_his
                  WHERE id = p_id_pres)
        LOOP
            v_complement_info :=
                v_complement_info || ' ' || TRIM (i.pju_libelle);
        END LOOP;

        RETURN REPLACE (REPLACE (v_complement_info, CHR (10), ' '),
                        CHR (13),
                        ' ');
    END;


    ------------------------------------------------------------------------------------------------------------------------------

    PROCEDURE transfer_file
    IS
        seprt                VARCHAR (1) := '|';
        rep_de_travail_var   VARCHAR2 (100) := 'UTL_DIR_PROD';
        rep_envoi_var        VARCHAR2 (100)
                                 := '/Prod/ProdSauvFS/UTL_DIR_PROD/ENVOI';
        rep_envoi_win_var    VARCHAR2 (100)
                                 := '/Prod/ProdSauvFS/UTL_DIR_PROD/NDC_ENVOI';
        nom_fichier          VARCHAR2 (60);
        my_file_handle       UTL_FILE.file_type;
        ligne                VARCHAR2 (32767) := '';
        datesys              DATE := SYSDATE;
        ---------------------------------
        --- AJouter le 1805/2021 � 16h08
        -----------------------------------
        v_id                 NUMBER := 0;
        my_file_handle_log   UTL_FILE.file_type;
        nom_fichier_log      VARCHAR2 (60)
            :=    'File_Integration_Mobile_'
               || TO_CHAR (SYSDATE, 'DDMMYY')
               || '.log';
        crlf        CONSTANT VARCHAR2 (2) := CHR (13) || CHR (10);
        corps_var            VARCHAR2 (10000);
    -------------------------------------
    BEGIN
        ---------------------------------
        --- AJouter le 1805/2021 � 16h08
        -----------------------------------
        BEGIN
            DELETE FROM lmvmobp.tablecrm;

            DELETE FROM lmvmobp.crm_sinistre;

            DELETE FROM lmvmobp.crm_versement;

            DELETE FROM lmvmobp.crm_pm_uc_support;


            INSERT INTO lmvmobp.tablecrm
                SELECT * FROM adm_prod.tablecrm;

            INSERT INTO lmvmobp.crm_sinistre
                SELECT * FROM adm_prod.crm_sinistre;

            INSERT INTO lmvmobp.crm_versement
                SELECT * FROM adm_prod.crm_versement;

            INSERT INTO lmvmobp.crm_pm_uc_support
                SELECT * FROM adm_prod.crm_pm_uc_support;


            SELECT MAX (customerid) + 1 INTO v_id FROM lmvmobp.customer;

            FOR i
                IN (SELECT DISTINCT UPPER (TRIM (a.cin)) cin
                    FROM lmvmobp.tablecrm a
                    WHERE UPPER (TRIM (a.cin)) NOT IN
                              (SELECT UPPER (TRIM (b.cin))
                               FROM lmvmobp.customer b))
            LOOP
                INSERT INTO lmvmobp.customer (customerid,
                                              cin,
                                              email,
                                              login,
                                              nom,
                                              password,
                                              tel,
                                              date_naissance,
                                              nbr_connexion,
                                              address,
                                              nbrconnexion,
                                              prenom,
                                              telfix,
                                              push_token,
                                              os,
                                              version,
                                              push_type,
                                              default_password_changed,
                                              code_clt_sgma)
                    SELECT v_id,
                           cin,
                           per_email,
                           NULL,
                           nompsous,
                           NULL,
                           num_tel,
                           dnsous,
                           0,
                           0,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           'ANDROID',
                           1,
                           NULL,
                           0,
                           code_clt_sgma
                    FROM lmvmobp.tablecrm a
                    WHERE UPPER (TRIM (cin)) = i.cin AND ROWNUM = 1;

                v_id := v_id + 1;
            END LOOP;

            /*            FOR i IN (SELECT c.code_clt_sgma, b.login, b.customerid
                                  FROM tablecrm a, lmvmobp.customer b, bcontrat c
                                  WHERE     a.numcat = c.numcat
                                        AND a.nadh = c.nadhes
                                        AND a.cin = b.cin
                                        AND NVL (b.code_clt_sgma, 0) = 0
                                        AND a.numcat IN (71,
                                                         74,
                                                         72,
                                                         73,
                                                         83,
                                                         92,
                                                         78,
                                                         86,
                                                         82,
                                                         76,
                                                         85,
                                                         87,
                                                         75,
                                                         95,
                                                         200,
                                                         201,
                                                         205,
                                                         206,
                                                         300,
                                                         301,
                                                         302,
                                                         303,
                                                         305,
                                                         306)
                                        AND NVL (c.code_clt_sgma, 0) <> 0)
                        LOOP
                            UPDATE lmvmobp.customer
                            SET code_clt_sgma = i.code_clt_sgma
                            WHERE     NVL (code_clt_sgma, 0) = 0
                                  AND customerid = i.customerid
                                  AND login = i.login;
                        END LOOP;*/

            FOR i IN (SELECT a.code_clt_sgma, b.login, b.customerid
                      FROM tablecrm a, lmvmobp.customer b        --,bcontrat c
                      WHERE           --a.numcat=c.numcat  and a.nadh=c.nadhes
                                /*and*/
                                a.cin = b.cin
                            AND NVL (b.code_clt_sgma, 0) = 0
                            AND a.numcat IN (71,
                                             74,
                                             72,
                                             73,
                                             83,
                                             92,
                                             78,
                                             86,
                                             82,
                                             76,
                                             85,
                                             87,
                                             75,
                                             95,
                                             200,
                                             201,
                                             205,
                                             206,
                                             300,
                                             301,
                                             302,
                                             303,
                                             305,
                                             306)
                            AND NVL (a.code_clt_sgma, 0) <> 0)
            LOOP
                UPDATE lmvmobp.customer
                SET code_clt_sgma = i.code_clt_sgma
                WHERE     NVL (code_clt_sgma, 0) = 0
                      AND customerid = i.customerid
                      AND login = i.login;
            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                my_file_handle_log :=
                    UTL_FILE.fopen (rep_de_travail_var, nom_fichier_log, 'w');
                corps_var :=
                    'Code Erreur  ' || TO_CHAR (SQLCODE) || crlf || crlf;
                corps_var :=
                       corps_var
                    || 'Libelle Erreur  '
                    || SQLERRM
                    || crlf
                    || crlf;
                UTL_FILE.put_line (my_file_handle_log, corps_var);
                UTL_FILE.fflush (my_file_handle_log);
                UTL_FILE.fclose (my_file_handle_log);
                DBMS_OUTPUT.put_line (
                    'Code Erreur  ' || TO_CHAR (SQLCODE) || crlf || crlf);
                DBMS_OUTPUT.put_line (
                    'Libelle Erreur  ' || SQLERRM || crlf || crlf);
        END;

        ----------------------------------------------------------------------------
        ----------------------------------------------------------------------------
        --
        -------------CRM_CONTRAT------------------------
        nom_fichier := 'CRM_CONTRAT.csv';
        my_file_handle :=
            UTL_FILE.fopen (rep_de_travail_var, nom_fichier, 'w');

        FOR i IN (SELECT * FROM tablecrm)
        LOOP
            ligne :=
                   TO_CHAR (i.id)
                || seprt
                || TO_CHAR (i.typeproduit)
                || seprt
                || TO_CHAR (i.numcat)
                || seprt
                || TO_CHAR (i.libnumcat)
                || seprt
                || TO_CHAR (i.agce)
                || seprt
                || TO_CHAR (i.libagce)
                || seprt
                || TO_CHAR (i.numcpt)
                || seprt
                || TO_CHAR (i.nadh)
                || seprt
                || TO_CHAR (i.datesous)
                || seprt
                || TO_CHAR (i.statctr)
                || seprt
                || TO_CHAR (i.libstatctr)
                || seprt
                || TO_CHAR (i.date_annul)
                || seprt
                || TO_CHAR (i.nompsous)
                || seprt
                || TO_CHAR (i.dnsous)
                || seprt
                || TO_CHAR (i.freq)
                || seprt
                || TO_CHAR (i.garopt)
                || seprt
                || TO_CHAR (i.mtdervl)
                || seprt
                || TO_CHAR (i.datedvl)
                || seprt
                || TO_CHAR (i.mtcot)
                || seprt
                || TO_CHAR (i.cumvp)
                || seprt
                || TO_CHAR (i.mtencour)
                || seprt
                || TO_CHAR (i.datencou)
                || seprt
                || TO_CHAR (i.mtrachp)
                || seprt
                || TO_CHAR (i.mtavce)
                || seprt
                || TO_CHAR (i.garcompl)
                || seprt
                || TO_CHAR (i.garchoix)
                || seprt
                || TO_CHAR (i.ij)
                || seprt
                || TO_CHAR (i.mtij)
                || seprt
                || TO_CHAR (i.npass1)
                || seprt
                || TO_CHAR (i.dnass1)
                || seprt
                || TO_CHAR (i.lnass1)
                || seprt
                || TO_CHAR (i.primeass1)
                || seprt
                || TO_CHAR (i.npass2)
                || seprt
                || TO_CHAR (i.dnass2)
                || seprt
                || TO_CHAR (i.lnass2)
                || seprt
                || TO_CHAR (i.primeass2)
                || seprt
                || TO_CHAR (i.npass3)
                || seprt
                || TO_CHAR (i.dnass3)
                || seprt
                || TO_CHAR (i.lnass3)
                || seprt
                || TO_CHAR (i.primeass3)
                || seprt
                || TO_CHAR (i.npass4)
                || seprt
                || TO_CHAR (i.dnass4)
                || seprt
                || TO_CHAR (i.lnass4)
                || seprt
                || TO_CHAR (i.primeass4)
                || seprt
                || TO_CHAR (i.npass5)
                || seprt
                || TO_CHAR (i.dnass5)
                || seprt
                || TO_CHAR (i.lnass5)
                || seprt
                || TO_CHAR (i.primeass5)
                || seprt
                || TO_CHAR (i.npass6)
                || seprt
                || TO_CHAR (i.dnass6)
                || seprt
                || TO_CHAR (i.lnass6)
                || seprt
                || TO_CHAR (i.primeass6)
                || seprt
                || TO_CHAR (i.npass7)
                || seprt
                || TO_CHAR (i.dnass7)
                || seprt
                || TO_CHAR (i.lnass7)
                || seprt
                || TO_CHAR (i.primeass7)
                || seprt
                || TO_CHAR (i.npass8)
                || seprt
                || TO_CHAR (i.dnass8)
                || seprt
                || TO_CHAR (i.lnass8)
                || seprt
                || TO_CHAR (i.primeass8)
                || seprt
                || TO_CHAR (i.capital)
                || seprt
                || TO_CHAR (i.ppippo)
                || seprt
                || TO_CHAR (i.daterach)
                || seprt
                || TO_CHAR (i.dateavce)
                || seprt
                || TO_CHAR (i.id_login)
                || seprt
                || TO_CHAR (i.cin)
                || seprt
                || TO_CHAR (i.num_tel)
                || seprt
                || TO_CHAR (i.clbenef1)
                || seprt
                || TO_CHAR (i.clbenef2)
                || seprt
                || TO_CHAR (i.clbenef3)
                || seprt
                || TO_CHAR (i.per_email)
                || seprt
                || TO_CHAR (i.ntsmt)
                || seprt
                || TO_CHAR (i.nbrachat)
                || seprt
                || TO_CHAR (i.dateexpiration)
                || seprt
                || TO_CHAR (i.minverslibre)
                || seprt
                || TO_CHAR (i.minversprogm)
                || seprt
                || TO_CHAR (i.minversprogt)
                || seprt
                || TO_CHAR (i.minversproga);
            UTL_FILE.put_line (my_file_handle, ligne);
        END LOOP;

        --FERMETURE DES FICHIERS--------------------------------------------------------------------------------------------
        UTL_FILE.fflush (my_file_handle);
        UTL_FILE.fclose (my_file_handle);
        -------------------------------------------------------------------------------------------------------------------
        --TRANSFERT DES FICHIERS VERS LE REPERTOIRE INTERMEDIAIRE ENVOI et NDC_ENVOI -------------------------------------
        host_command (
               '/bin/cp /Prod/ProdSauvFS/UTL_DIR_PROD/'
            || nom_fichier
            || ' '
            || rep_envoi_win_var
            || '/'
            || nom_fichier);
        host_command (
               '/bin/mv /Prod/ProdSauvFS/UTL_DIR_PROD/'
            || nom_fichier
            || ' '
            || rep_envoi_var
            || '/'
            || nom_fichier);
        -------------------------------------------------------------------------------------------------------------------

        --------------------------------------------------

        -------------CRM_SINISTRE------------------------
        nom_fichier := 'CRM_SINISTRE.csv';
        my_file_handle :=
            UTL_FILE.fopen (rep_de_travail_var, nom_fichier, 'w');

        FOR i IN (SELECT * FROM crm_sinistre)
        LOOP
            ligne :=
                   TO_CHAR (i.id)
                || seprt
                || TO_CHAR (i.numbas)
                || seprt
                || TO_CHAR (i.numcatbase)
                || seprt
                || TO_CHAR (i.libcatbase)
                || seprt
                || TO_CHAR (i.numcatadt)
                || seprt
                || TO_CHAR (i.libcatadt)
                || seprt
                || TO_CHAR (i.typeprod)
                || seprt
                || TO_CHAR (i.numass)
                || seprt
                || TO_CHAR (i.nomass)
                || seprt
                || TO_CHAR (i.etatdossier)
                || seprt
                || TO_CHAR (i.nomfam)
                || seprt
                || TO_CHAR (i.lien)
                || seprt
                || TO_CHAR (i.datesin)
                || seprt
                || TO_CHAR (i.numdoss)
                || seprt
                || TO_CHAR (i.datedecl)
                || seprt
                || TO_CHAR (i.motif)
                || seprt
                || TO_CHAR (i.mtsinistre)
                || seprt
                || TO_CHAR (i.dateoper)
                || seprt
                || TO_CHAR (i.frais_engage)
                || seprt
                || TO_CHAR (i.medecin_trait)
                || seprt
                || TO_CHAR (i.observation)
                || seprt
                || TO_CHAR (i.nature_soins)
                || seprt;
            UTL_FILE.put_line (my_file_handle, ligne);
        END LOOP;

        --FERMETURE DES FICHIERS--------------------------------------------------------------------------------------------
        UTL_FILE.fflush (my_file_handle);
        UTL_FILE.fclose (my_file_handle);
        -------------------------------------------------------------------------------------------------------------------
        --TRANSFERT DES FICHIERS VERS LE REPERTOIRE INTERMEDIAIRE ENVOI et NDC_ENVOI -------------------------------------
        host_command (
               '/bin/cp /Prod/ProdSauvFS/UTL_DIR_PROD/'
            || nom_fichier
            || ' '
            || rep_envoi_win_var
            || '/'
            || nom_fichier);
        host_command (
               '/bin/mv /Prod/ProdSauvFS/UTL_DIR_PROD/'
            || nom_fichier
            || ' '
            || rep_envoi_var
            || '/'
            || nom_fichier);
        -------------------------------------------------------------------------------------------------------------------

        -------------CRM_VERSEMENT------------------------
        nom_fichier := 'CRM_VERSEMENT.csv';
        my_file_handle :=
            UTL_FILE.fopen (rep_de_travail_var, nom_fichier, 'w');

        FOR i IN (SELECT * FROM crm_versement)
        LOOP
            ligne :=
                   TO_CHAR (i.id)
                || seprt
                || TO_CHAR (i.numbas)
                || seprt
                || TO_CHAR (i.numcat)
                || seprt
                || TO_CHAR (i.echeance)
                || seprt
                || TO_CHAR (i.date_encais)
                || seprt
                || TO_CHAR (i.etat)
                || seprt
                || TO_CHAR (i.mtvers)
                || seprt
                || TO_CHAR (i.modpayement)
                || seprt;
            UTL_FILE.put_line (my_file_handle, ligne);
        END LOOP;

        --FERMETURE DES FICHIERS--------------------------------------------------------------------------------------------
        UTL_FILE.fflush (my_file_handle);
        UTL_FILE.fclose (my_file_handle);
        -------------------------------------------------------------------------------------------------------------------
        --TRANSFERT DES FICHIERS VERS LE REPERTOIRE INTERMEDIAIRE ENVOI et NDC_ENVOI -------------------------------------
        host_command (
               '/bin/cp /Prod/ProdSauvFS/UTL_DIR_PROD/'
            || nom_fichier
            || ' '
            || rep_envoi_win_var
            || '/'
            || nom_fichier);
        host_command (
               '/bin/mv /Prod/ProdSauvFS/UTL_DIR_PROD/'
            || nom_fichier
            || ' '
            || rep_envoi_var
            || '/'
            || nom_fichier);
        -------------------------------------------------------------------------------------------------------------------


        -------------------------------------------------------------------------------------------------------------------

        -------------CRM_pm_uc_support------------------------
        nom_fichier := 'CRM_pm_uc_support.csv';
        my_file_handle :=
            UTL_FILE.fopen (rep_de_travail_var, nom_fichier, 'w');

        FOR i IN (SELECT * FROM crm_pm_uc_support)
        LOOP
            ligne :=
                   TO_CHAR (i.id)
                || seprt
                || TO_CHAR (i.rang)
                || seprt
                || TO_CHAR (i.pm_saving_effec_dte)
                || seprt
                || TO_CHAR (i.numcat)
                || seprt
                || TO_CHAR (i.nadh)
                || seprt
                || TO_CHAR (i.ref_support_id)
                || seprt
                || TO_CHAR (i.support)
                || seprt
                || TO_CHAR (i.pm_val)
                || seprt;
            UTL_FILE.put_line (my_file_handle, ligne);
        END LOOP;

        --FERMETURE DES FICHIERS--------------------------------------------------------------------------------------------
        UTL_FILE.fflush (my_file_handle);
        UTL_FILE.fclose (my_file_handle);
        -------------------------------------------------------------------------------------------------------------------
        --TRANSFERT DES FICHIERS VERS LE REPERTOIRE INTERMEDIAIRE ENVOI et NDC_ENVOI -------------------------------------
        host_command (
               '/bin/cp /Prod/ProdSauvFS/UTL_DIR_PROD/'
            || nom_fichier
            || ' '
            || rep_envoi_win_var
            || '/'
            || nom_fichier);
        host_command (
               '/bin/mv /Prod/ProdSauvFS/UTL_DIR_PROD/'
            || nom_fichier
            || ' '
            || rep_envoi_var
            || '/'
            || nom_fichier);
    -------------------------------------------------------------------------------------------------------------------


    --
    END;

    PROCEDURE Create_Customers
        IS
        v_id NUMBER := 0;
        my_file_handle_log UTL_FILE.file_type;
        nom_fichier_log VARCHAR2(60) := 'File_Integration_Mobile_' || TO_CHAR(SYSDATE, 'DDMMYY') || '.log';
        crlf CONSTANT VARCHAR2(2) := CHR(13) || CHR(10);
        corps_var VARCHAR2(10000);
        rep_de_travail_var   VARCHAR2 (100) := 'UTL_DIR_PROD';
    BEGIN
        SELECT MAX (customerid) + 1 INTO v_id FROM lmvmobp.customer;

        FOR i
            IN (SELECT DISTINCT UPPER (TRIM (a.cin)) cin
                FROM lmvmobp.tablecrm a
                WHERE UPPER (TRIM (a.cin)) NOT IN
                      (SELECT UPPER (TRIM (b.cin))
                       FROM lmvmobp.customer b))
            LOOP
                INSERT INTO lmvmobp.customer (customerid,
                    cin,email,login,nom,password,tel,date_naissance,nbr_connexion,address,nbrconnexion,
                    prenom,telfix,push_token,os,version,push_type,default_password_changed,code_clt_sgma)

                SELECT v_id,cin,per_email,NULL,nompsous,NULL,num_tel,dnsous,
                       0,0,NULL,NULL,NULL,NULL,'ANDROID',1,NULL,0,code_clt_sgma
                FROM lmvmobp.tablecrm a
                WHERE UPPER (TRIM (cin)) = i.cin AND ROWNUM = 1;

                v_id := v_id + 1;
            END LOOP;

        COMMIT;

    EXCEPTION
        WHEN OTHERS
            THEN
                my_file_handle_log := UTL_FILE.fopen (rep_de_travail_var, nom_fichier_log, 'w');
                corps_var := 'Code Erreur  ' || TO_CHAR (SQLCODE) || crlf || crlf;
                corps_var := corps_var || 'Libelle Erreur  ' || SQLERRM || crlf || crlf;
                UTL_FILE.put_line (my_file_handle_log, corps_var);
                UTL_FILE.fflush (my_file_handle_log);
                UTL_FILE.fclose (my_file_handle_log);
                DBMS_OUTPUT.put_line ('Code Erreur  ' || TO_CHAR (SQLCODE) || crlf || crlf);
                DBMS_OUTPUT.put_line ('Libelle Erreur  ' || SQLERRM || crlf || crlf);
    END;

    PROCEDURE Update_Code_Clt_Sgma_hors_sis
        IS
        my_file_handle_log UTL_FILE.file_type;
        nom_fichier_log VARCHAR2(60) := 'File_Integration_Mobile_' || TO_CHAR(SYSDATE, 'DDMMYY') || '.log';
        crlf CONSTANT VARCHAR2(2) := CHR(13) || CHR(10);
        corps_var VARCHAR2(10000);
        rep_de_travail_var   VARCHAR2 (100) := 'UTL_DIR_PROD';
    BEGIN
        FOR i IN (SELECT a.code_clt_sgma, b.login, b.customerid
                  FROM tablecrm a, lmvmobp.customer b
                  WHERE
                      a.cin = b.cin
                    AND NVL (b.code_clt_sgma, 0) = 0
                    AND a.numcat IN (71,74,72,73,83,92,78,86,82,76,85,87,75,95,205,300,
                                     301,302,303,305,306)
                    AND NVL (a.code_clt_sgma, 0) <> 0)
            LOOP
                UPDATE lmvmobp.customer
                SET code_clt_sgma = i.code_clt_sgma
                WHERE     NVL (code_clt_sgma, 0) = 0
                  AND customerid = i.customerid
                  AND login = i.login;
            END LOOP;

        COMMIT;

    EXCEPTION
        WHEN OTHERS
            THEN
                my_file_handle_log := UTL_FILE.fopen (rep_de_travail_var, nom_fichier_log, 'w');
                corps_var := 'Code Erreur  ' || TO_CHAR (SQLCODE) || crlf || crlf;
                corps_var := corps_var || 'Libelle Erreur  ' || SQLERRM || crlf || crlf;
                UTL_FILE.put_line (my_file_handle_log, corps_var);
                UTL_FILE.fflush (my_file_handle_log);
                UTL_FILE.fclose (my_file_handle_log);
                DBMS_OUTPUT.put_line ('Code Erreur  ' || TO_CHAR (SQLCODE) || crlf || crlf);
                DBMS_OUTPUT.put_line ('Libelle Erreur  ' || SQLERRM || crlf || crlf);
    END;

    PROCEDURE Update_Code_Clt_Sgma_sis
        IS
        my_file_handle_log UTL_FILE.file_type;
        nom_fichier_log VARCHAR2(60) := 'File_Integration_Mobile_' || TO_CHAR(SYSDATE, 'DDMMYY') || '.log';
        crlf CONSTANT VARCHAR2(2) := CHR(13) || CHR(10);
        corps_var VARCHAR2(10000);
        rep_de_travail_var   VARCHAR2 (100) := 'UTL_DIR_PROD';
    BEGIN
        FOR i IN (SELECT a.code_clt_sgma, b.login, b.customerid
                  FROM tablecrm a, lmvmobp.customer b
                  WHERE
                      a.cin = b.cin
                    AND NVL (b.code_clt_sgma, 0) = 0
                    AND a.numcat IN (200,201,206)
                    AND NVL (a.code_clt_sgma, 0) <> 0)
            LOOP
                UPDATE lmvmobp.customer
                SET code_clt_sgma = i.code_clt_sgma
                WHERE     NVL (code_clt_sgma, 0) = 0
                  AND customerid = i.customerid
                  AND login = i.login;
            END LOOP;

        COMMIT;

    EXCEPTION
        WHEN OTHERS
            THEN
                my_file_handle_log := UTL_FILE.fopen (rep_de_travail_var, nom_fichier_log, 'w');
                corps_var := 'Code Erreur  ' || TO_CHAR (SQLCODE) || crlf || crlf;
                corps_var := corps_var || 'Libelle Erreur  ' || SQLERRM || crlf || crlf;
                UTL_FILE.put_line (my_file_handle_log, corps_var);
                UTL_FILE.fflush (my_file_handle_log);
                UTL_FILE.fclose (my_file_handle_log);
                DBMS_OUTPUT.put_line ('Code Erreur  ' || TO_CHAR (SQLCODE) || crlf || crlf);
                DBMS_OUTPUT.put_line ('Libelle Erreur  ' || SQLERRM || crlf || crlf);
    END;



    --------------------------------------------------------------------------------

    PROCEDURE extraction_tables_crm
        IS
        seprt                VARCHAR (1) := '|';
        rep_de_travail_var   VARCHAR2 (100) := 'UTL_DIR_PROD';
        rep_envoi_var        VARCHAR2 (100)
            := '/Prod/ProdSauvFS/UTL_DIR_PROD/ENVOI';
        rep_envoi_win_var    VARCHAR2 (100)
            := '/Prod/ProdSauvFS/UTL_DIR_PROD/NDC_ENVOI';
        nom_fichier          VARCHAR2 (60);
        my_file_handle       UTL_FILE.file_type;
        ligne                VARCHAR2 (32767) := '';
    BEGIN
        -------------CRM_CONTRAT------------------------
        nom_fichier := 'CRM_CONTRAT.csv';
        my_file_handle :=
                UTL_FILE.fopen (rep_de_travail_var, nom_fichier, 'w');

        FOR i IN (SELECT * FROM tablecrm)
            LOOP
                ligne :=
                        TO_CHAR (i.id)
                            || seprt
                            || TO_CHAR (i.typeproduit)
                            || seprt
                            || TO_CHAR (i.numcat)
                            || seprt
                            || TO_CHAR (i.libnumcat)
                            || seprt
                            || TO_CHAR (i.agce)
                            || seprt
                            || TO_CHAR (i.libagce)
                            || seprt
                            || TO_CHAR (i.numcpt)
                            || seprt
                            || TO_CHAR (i.nadh)
                            || seprt
                            || TO_CHAR (i.datesous)
                            || seprt
                            || TO_CHAR (i.statctr)
                            || seprt
                            || TO_CHAR (i.libstatctr)
                            || seprt
                            || TO_CHAR (i.date_annul)
                            || seprt
                            || TO_CHAR (i.nompsous)
                            || seprt
                            || TO_CHAR (i.dnsous)
                            || seprt
                            || TO_CHAR (i.freq)
                            || seprt
                            || TO_CHAR (i.garopt)
                            || seprt
                            || TO_CHAR (i.mtdervl)
                            || seprt
                            || TO_CHAR (i.datedvl)
                            || seprt
                            || TO_CHAR (i.mtcot)
                            || seprt
                            || TO_CHAR (i.cumvp)
                            || seprt
                            || TO_CHAR (i.mtencour)
                            || seprt
                            || TO_CHAR (i.datencou)
                            || seprt
                            || TO_CHAR (i.mtrachp)
                            || seprt
                            || TO_CHAR (i.mtavce)
                            || seprt
                            || TO_CHAR (i.garcompl)
                            || seprt
                            || TO_CHAR (i.garchoix)
                            || seprt
                            || TO_CHAR (i.ij)
                            || seprt
                            || TO_CHAR (i.mtij)
                            || seprt
                            || TO_CHAR (i.npass1)
                            || seprt
                            || TO_CHAR (i.dnass1)
                            || seprt
                            || TO_CHAR (i.lnass1)
                            || seprt
                            || TO_CHAR (i.primeass1)
                            || seprt
                            || TO_CHAR (i.npass2)
                            || seprt
                            || TO_CHAR (i.dnass2)
                            || seprt
                            || TO_CHAR (i.lnass2)
                            || seprt
                            || TO_CHAR (i.primeass2)
                            || seprt
                            || TO_CHAR (i.npass3)
                            || seprt
                            || TO_CHAR (i.dnass3)
                            || seprt
                            || TO_CHAR (i.lnass3)
                            || seprt
                            || TO_CHAR (i.primeass3)
                            || seprt
                            || TO_CHAR (i.npass4)
                            || seprt
                            || TO_CHAR (i.dnass4)
                            || seprt
                            || TO_CHAR (i.lnass4)
                            || seprt
                            || TO_CHAR (i.primeass4)
                            || seprt
                            || TO_CHAR (i.npass5)
                            || seprt
                            || TO_CHAR (i.dnass5)
                            || seprt
                            || TO_CHAR (i.lnass5)
                            || seprt
                            || TO_CHAR (i.primeass5)
                            || seprt
                            || TO_CHAR (i.npass6)
                            || seprt
                            || TO_CHAR (i.dnass6)
                            || seprt
                            || TO_CHAR (i.lnass6)
                            || seprt
                            || TO_CHAR (i.primeass6)
                            || seprt
                            || TO_CHAR (i.npass7)
                            || seprt
                            || TO_CHAR (i.dnass7)
                            || seprt
                            || TO_CHAR (i.lnass7)
                            || seprt
                            || TO_CHAR (i.primeass7)
                            || seprt
                            || TO_CHAR (i.npass8)
                            || seprt
                            || TO_CHAR (i.dnass8)
                            || seprt
                            || TO_CHAR (i.lnass8)
                            || seprt
                            || TO_CHAR (i.primeass8)
                            || seprt
                            || TO_CHAR (i.capital)
                            || seprt
                            || TO_CHAR (i.ppippo)
                            || seprt
                            || TO_CHAR (i.daterach)
                            || seprt
                            || TO_CHAR (i.dateavce)
                            || seprt
                            || TO_CHAR (i.id_login)
                            || seprt
                            || TO_CHAR (i.cin)
                            || seprt
                            || TO_CHAR (i.num_tel)
                            || seprt
                            || TO_CHAR (i.clbenef1)
                            || seprt
                            || TO_CHAR (i.clbenef2)
                            || seprt
                            || TO_CHAR (i.clbenef3)
                            || seprt
                            || TO_CHAR (i.per_email)
                            || seprt
                            || TO_CHAR (i.ntsmt)
                            || seprt
                            || TO_CHAR (i.nbrachat)
                            || seprt
                            || TO_CHAR (i.dateexpiration)
                            || seprt
                            || TO_CHAR (i.minverslibre)
                            || seprt
                            || TO_CHAR (i.minversprogm)
                            || seprt
                            || TO_CHAR (i.minversprogt)
                            || seprt
                            || TO_CHAR (i.minversproga);
                UTL_FILE.put_line (my_file_handle, ligne);
            END LOOP;

        --FERMETURE DES FICHIERS--------------------------------------------------------------------------------------------
        UTL_FILE.fflush (my_file_handle);
        UTL_FILE.fclose (my_file_handle);
        -------------------------------------------------------------------------------------------------------------------
        --TRANSFERT DES FICHIERS VERS LE REPERTOIRE INTERMEDIAIRE ENVOI et NDC_ENVOI -------------------------------------
        host_command (
                '/bin/cp /Prod/ProdSauvFS/UTL_DIR_PROD/'
                    || nom_fichier
                    || ' '
                    || rep_envoi_win_var
                    || '/'
                    || nom_fichier);
        host_command (
                '/bin/mv /Prod/ProdSauvFS/UTL_DIR_PROD/'
                    || nom_fichier
                    || ' '
                    || rep_envoi_var
                    || '/'
                    || nom_fichier);
        -------------------------------------------------------------------------------------------------------------------

        --------------------------------------------------

        -------------CRM_SINISTRE------------------------
        nom_fichier := 'CRM_SINISTRE.csv';
        my_file_handle :=
                UTL_FILE.fopen (rep_de_travail_var, nom_fichier, 'w');

        FOR i IN (SELECT * FROM crm_sinistre)
            LOOP
                ligne :=
                        TO_CHAR (i.id)
                            || seprt
                            || TO_CHAR (i.numbas)
                            || seprt
                            || TO_CHAR (i.numcatbase)
                            || seprt
                            || TO_CHAR (i.libcatbase)
                            || seprt
                            || TO_CHAR (i.numcatadt)
                            || seprt
                            || TO_CHAR (i.libcatadt)
                            || seprt
                            || TO_CHAR (i.typeprod)
                            || seprt
                            || TO_CHAR (i.numass)
                            || seprt
                            || TO_CHAR (i.nomass)
                            || seprt
                            || TO_CHAR (i.etatdossier)
                            || seprt
                            || TO_CHAR (i.nomfam)
                            || seprt
                            || TO_CHAR (i.lien)
                            || seprt
                            || TO_CHAR (i.datesin)
                            || seprt
                            || TO_CHAR (i.numdoss)
                            || seprt
                            || TO_CHAR (i.datedecl)
                            || seprt
                            || TO_CHAR (i.motif)
                            || seprt
                            || TO_CHAR (i.mtsinistre)
                            || seprt
                            || TO_CHAR (i.dateoper)
                            || seprt
                            || TO_CHAR (i.frais_engage)
                            || seprt
                            || TO_CHAR (i.medecin_trait)
                            || seprt
                            || TO_CHAR (i.observation)
                            || seprt
                            || TO_CHAR (i.nature_soins)
                            || seprt;
                UTL_FILE.put_line (my_file_handle, ligne);
            END LOOP;

        --FERMETURE DES FICHIERS--------------------------------------------------------------------------------------------
        UTL_FILE.fflush (my_file_handle);
        UTL_FILE.fclose (my_file_handle);
        -------------------------------------------------------------------------------------------------------------------
        --TRANSFERT DES FICHIERS VERS LE REPERTOIRE INTERMEDIAIRE ENVOI et NDC_ENVOI -------------------------------------
        host_command (
                '/bin/cp /Prod/ProdSauvFS/UTL_DIR_PROD/'
                    || nom_fichier
                    || ' '
                    || rep_envoi_win_var
                    || '/'
                    || nom_fichier);
        host_command (
                '/bin/mv /Prod/ProdSauvFS/UTL_DIR_PROD/'
                    || nom_fichier
                    || ' '
                    || rep_envoi_var
                    || '/'
                    || nom_fichier);
        -------------------------------------------------------------------------------------------------------------------

        -------------CRM_VERSEMENT------------------------
        nom_fichier := 'CRM_VERSEMENT.csv';
        my_file_handle :=
                UTL_FILE.fopen (rep_de_travail_var, nom_fichier, 'w');

        FOR i IN (SELECT * FROM crm_versement)
            LOOP
                ligne :=
                        TO_CHAR (i.id)
                            || seprt
                            || TO_CHAR (i.numbas)
                            || seprt
                            || TO_CHAR (i.numcat)
                            || seprt
                            || TO_CHAR (i.echeance)
                            || seprt
                            || TO_CHAR (i.date_encais)
                            || seprt
                            || TO_CHAR (i.etat)
                            || seprt
                            || TO_CHAR (i.mtvers)
                            || seprt
                            || TO_CHAR (i.modpayement)
                            || seprt;
                UTL_FILE.put_line (my_file_handle, ligne);
            END LOOP;

        --FERMETURE DES FICHIERS--------------------------------------------------------------------------------------------
        UTL_FILE.fflush (my_file_handle);
        UTL_FILE.fclose (my_file_handle);
        -------------------------------------------------------------------------------------------------------------------
        --TRANSFERT DES FICHIERS VERS LE REPERTOIRE INTERMEDIAIRE ENVOI et NDC_ENVOI -------------------------------------
        host_command (
                '/bin/cp /Prod/ProdSauvFS/UTL_DIR_PROD/'
                    || nom_fichier
                    || ' '
                    || rep_envoi_win_var
                    || '/'
                    || nom_fichier);
        host_command (
                '/bin/mv /Prod/ProdSauvFS/UTL_DIR_PROD/'
                    || nom_fichier
                    || ' '
                    || rep_envoi_var
                    || '/'
                    || nom_fichier);
        -------------------------------------------------------------------------------------------------------------------


        -------------------------------------------------------------------------------------------------------------------

        -------------CRM_pm_uc_support------------------------
        nom_fichier := 'CRM_pm_uc_support.csv';
        my_file_handle :=
                UTL_FILE.fopen (rep_de_travail_var, nom_fichier, 'w');

        FOR i IN (SELECT * FROM crm_pm_uc_support)
            LOOP
                ligne :=
                        TO_CHAR (i.id)
                            || seprt
                            || TO_CHAR (i.rang)
                            || seprt
                            || TO_CHAR (i.pm_saving_effec_dte)
                            || seprt
                            || TO_CHAR (i.numcat)
                            || seprt
                            || TO_CHAR (i.nadh)
                            || seprt
                            || TO_CHAR (i.ref_support_id)
                            || seprt
                            || TO_CHAR (i.support)
                            || seprt
                            || TO_CHAR (i.pm_val)
                            || seprt;
                UTL_FILE.put_line (my_file_handle, ligne);
            END LOOP;

        --FERMETURE DES FICHIERS--------------------------------------------------------------------------------------------
        UTL_FILE.fflush (my_file_handle);
        UTL_FILE.fclose (my_file_handle);
        -------------------------------------------------------------------------------------------------------------------
        --TRANSFERT DES FICHIERS VERS LE REPERTOIRE INTERMEDIAIRE ENVOI et NDC_ENVOI -------------------------------------
        host_command (
                '/bin/cp /Prod/ProdSauvFS/UTL_DIR_PROD/'
                    || nom_fichier
                    || ' '
                    || rep_envoi_win_var
                    || '/'
                    || nom_fichier);
        host_command (
                '/bin/mv /Prod/ProdSauvFS/UTL_DIR_PROD/'
                    || nom_fichier
                    || ' '
                    || rep_envoi_var
                    || '/'
                    || nom_fichier);
        -------------------------------------------------------------------------------------------------------------------


        --
    END;

    --------------------------------------------------------------------------------
    PROCEDURE calculpm
    IS
        v_datecalcule   DATE := TO_CHAR (SYSDATE, 'dd/mm/yyyy');
    BEGIN
        bqass_pm71.var_mobil := 1;
        bqass_pm71.calculpm (v_datecalcule, -1);

        bqass_pm72.var_mobil := 1;
        bqass_pm72.calculpm (v_datecalcule, -1);

        bqass_pm73_78_86.var_mobil := 1;
        bqass_pm73_78_86.calculpm (v_datecalcule, -1, -1);

        bqass_pm85.var_mobil := 1;
        bqass_pm85.calculpm (v_datecalcule, -1);

        bqass_pm87.var_mobil := 1;
        bqass_pm87.calculpm (v_datecalcule, -1);

        bqass_pm92.var_mobil := 1;
        bqass_pm92.calculpm (v_datecalcule, -1);

        classique_pm_01.var_mobil := 1;
        classique_pm_01.calculpm (v_datecalcule, -1);

        classique_pm_65.var_mobil := 1;
        classique_pm_65.calculpm (v_datecalcule, -1);

        classique_pm_27.var_mobil := 1;
        classique_pm_27.calculpm (v_datecalcule, -1);

        classique_pm_11.var_mobil := 1;
        classique_pm_11.calculpm (v_datecalcule, -1);

        classique_pm_63.var_mobil := 1;
        classique_pm_63.calculpm (v_datecalcule, -1);

        classique_pm_64.var_mobil := 1;
        classique_pm_64.calculpm (v_datecalcule, -1, -1);
    END;
-------------------------------------------------------------------------------------------------------------------
-----------------  Fin du Package
-------------------------------------------------------------------------------------------------------------------
END;
/
