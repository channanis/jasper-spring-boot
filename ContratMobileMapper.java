package com.votreapp.mapper;

import com.votreapp.dto.ContratMobileDTO;
import com.votreapp.entity.Adherent;
import com.votreapp.entity.Base;
import com.votreapp.entity.Contrat;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

import java.util.Set;

/**
 * Reproduit en J la même logique de dérivation que TRAITEMENT_CRM.pkb utilise
 * pour alimenter TABLECRM en J-1, filière par filière.
 */
@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface ContratMobileMapper {

    // ---------------------------------------------------------------
    // Bancassurance — miroir de proc_tabcrm_bq
    // ---------------------------------------------------------------
    @Mapping(target = "numCat", source = "categorie")
    @Mapping(target = "libNumCat", source = "category.libelle")
    @Mapping(target = "agce", expression = "java(padAgence(contrat.getAgence() != null ? contrat.getAgence().getCodAgce() : null))")
    @Mapping(target = "libAgce", source = "agence.nomAgce")
    @Mapping(target = "numCpt", source = "rib")
    @Mapping(target = "nadh", expression = "java(String.valueOf(contrat.getNumContrat()))")
    @Mapping(target = "dateSous", source = "dateEffet")
    @Mapping(target = "statCtr", expression = "java(statutCode(contrat.getDateAnnulation(), contrat.getEtat()))")
    @Mapping(target = "libStatCtr", expression = "java(statutLibelle(contrat.getDateAnnulation(), contrat.getEtat()))")
    @Mapping(target = "dateAnnul", source = "dateAnnulation")
    @Mapping(target = "mtCot", source = "montantCotisation")
    @Mapping(target = "freq", source = "frequance")
    @Mapping(target = "garOpt", source = "opt")
    @Mapping(target = "capital", source = "capital")
    @Mapping(target = "cin", expression = "java(normalizeCin(contrat.getClient().getCin()))")
    @Mapping(target = "typeProduit", expression = "java(typeProduit(contrat.getCategorie()))")
    @Mapping(target = "matricule", expression = "java(contrat.getMatricule() != null ? Long.valueOf(contrat.getMatricule()) : null)")
    ContratMobileDTO fromBancassurance(Contrat contrat);

    // ---------------------------------------------------------------
    // Groupe — miroir de proc_tabcrm_sync_groupe
    // ---------------------------------------------------------------
    @Mapping(target = "numCat", source = "numCat")
    @Mapping(target = "libNumCat", constant = "DYNAMIC ENTREPRISE")
    @Mapping(target = "agce", expression = "java(padAgence(adherent.getSociete().getCodAgce()))")
    @Mapping(target = "numCpt", source = "numCompte")
    @Mapping(target = "nadh", expression = "java(String.valueOf(adherent.getPolice()))")
    @Mapping(target = "statCtr", constant = "1")
    @Mapping(target = "libStatCtr", constant = "En vigueur")
    @Mapping(target = "dateAnnul", source = "dateDepart")
    @Mapping(target = "nomPsous", source = "nom")
    @Mapping(target = "dnSous", source = "dnaisAss")
    @Mapping(target = "mtCot", source = "cotisatini")
    @Mapping(target = "mtRachp", source = "mtFreAct")
    @Mapping(target = "npAss1", source = "beneficiare")
    @Mapping(target = "primeAss1", source = "primeDeces")
    @Mapping(target = "dateExpiration", source = "societe.echeance")
    @Mapping(target = "contractante", source = "societe.nomCtr")
    @Mapping(target = "matricule", source = "matricule")
    @Mapping(target = "typeProduit", constant = "RETRAITE")
    @Mapping(target = "cin", expression = "java(normalizeCin(adherent.getCin()))")
    ContratMobileDTO fromGroupe(Adherent adherent);

    // ---------------------------------------------------------------
    // Individuel — miroir de proc_tabcrm_ind
    // ---------------------------------------------------------------
    @Mapping(target = "numCat", source = "category.numCat")
    @Mapping(target = "libNumCat", source = "category.libelle")
    @Mapping(target = "numCpt", source = "assure.numTelMobil")
    @Mapping(target = "nadh", expression = "java(String.valueOf(base.getNumBas()))")
    @Mapping(target = "dateSous", source = "deffBas")
    @Mapping(target = "statCtr", expression = "java(base.getDaSuspen() == null ? 1 : 2)")
    @Mapping(target = "libStatCtr", expression = "java(base.getDaSuspen() == null ? \"VIGUEUR\" : \"Suspendu\")")
    @Mapping(target = "dateAnnul", source = "datAnnul")
    @Mapping(target = "nomPsous", expression = "java(nomPrenom(base.getAssure()))")
    @Mapping(target = "dnSous", source = "assure.dnaisAss")
    @Mapping(target = "mtCot", source = "primeBas")
    @Mapping(target = "freq", source = "modPBas")
    @Mapping(target = "capital", source = "capBas")
    @Mapping(target = "cin", expression = "java(normalizeCin(base.getAssure().getCin()))")
    @Mapping(target = "perEmail", source = "assure.perEmailMobil")
    @Mapping(target = "numTel", source = "assure.numTelMobil")
    @Mapping(target = "typeProduit", expression = "java(typeProduit(base.getCategory().getNumCat()))")
    ContratMobileDTO fromIndividuel(Base base);

    // ---------------------------------------------------------------
    // Helpers — logique reprise telle quelle du package PL/SQL
    // ---------------------------------------------------------------

    default String normalizeCin(String cin) {
        return cin == null ? null : cin.toUpperCase().replace(" ", "").replace(".", "");
    }

    default String padAgence(String codAgce) {
        if (codAgce == null) return null;
        return String.format("%3s", codAgce).replace(' ', '0');
    }

    default Integer statutCode(java.time.LocalDate dateAnnul, String etat) {
        if (dateAnnul != null) return 0;
        return "Suspendu".equalsIgnoreCase(etat) ? 2 : 1;
    }

    default String statutLibelle(java.time.LocalDate dateAnnul, String etat) {
        if (dateAnnul != null) return "ANNULE";
        return etat;
    }

    default String nomPrenom(com.votreapp.entity.Assure assure) {
        if (assure == null) return null;
        return String.join(" ",
                safe(assure.getCivilite()), safe(assure.getNom()), safe(assure.getPrenom())).trim();
    }

    private String safe(String s) {
        return s == null ? "" : s.trim();
    }

    // Reprend FUNCTION typeproduit(p_numcat) du package
    Set<Integer> SANTE = Set.of(3, 10, 23, 24, 26, 35, 36, 37, 38, 39, 42, 50, 51, 54, 55, 56, 61, 76,
            300, 301, 302, 303, 304, 305, 306);
    Set<Integer> PREVOYANCE = Set.of(2, 5, 6, 9, 18, 19, 33, 34, 40, 47, 48, 49, 53, 58, 60, 68, 74, 75, 83, 95, 15, 16, 82);
    Set<Integer> EPARGNE = Set.of(32, 63, 71, 72, 73, 78, 85, 86, 92, 200, 205, 1, 20, 206);
    Set<Integer> RETRAITE = Set.of(1, 11, 20, 21, 22, 27, 65, 87, 201, 64);

    default String typeProduit(Integer numCat) {
        if (numCat == null) return null;
        if (SANTE.contains(numCat)) return "SANTE";
        if (PREVOYANCE.contains(numCat)) return "PREVOYANCE";
        if (EPARGNE.contains(numCat)) return "EPARGNE";
        if (RETRAITE.contains(numCat)) return "RETRAITE";
        return String.valueOf(numCat);
    }
}
