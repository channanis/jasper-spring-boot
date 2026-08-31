import java.util.HashMap;
import java.util.Map;

/**
 * Construit les DTO "situation" (brute / nette) à partir de VersementsSituation,
 * en respectant exactement les clés attendues par msapiprinting pour chaque codeDocument.
 *
 * IMPORTANT : "categorie", "police" et "matricule" sont convertis en String (toString())
 * de la même façon que le fait déjà VersementMapper pour "numeroAdhesion"/"numeroContrat" ;
 * si "categorie" doit en réalité être un libellé court (ex. "VR", "GRP") plutôt que l'id
 * numérique, remplacer par v.getLibCategore() ou la table de correspondance appropriée.
 */
public class SituationMapper {

    public static SituationBancassDocumentDTO mapToBancass(VersementsSituation v) {
        SituationBancassDocumentDTO dto = new SituationBancassDocumentDTO();
        dto.setTitre(v.getCivilite());
        dto.setNom(v.getNom());
        dto.setPrenom(v.getPrenom());
        dto.setAdresse1(v.getAdresse1());
        dto.setAdresse2(v.getAdresse2());
        dto.setCategorie(toStringOrNull(v.getCategorie()));
        dto.setPolice(toStringOrNull(v.getPolice()));
        dto.setDateEffet(v.getDateEffet() != null ? v.getDateEffet().toString() : null);
        // Pas de champ "svk" côté VersementsSituation : 0 force le repli sur "mtcot" côté template
        dto.setSvk(Double.valueOf(0d));
        dto.setMtcot(v.getTotalVersements());
        dto.setMtavance(v.getAvanceNonRemboursees());
        dto.setVprim(v.getSituationBrute());
        return dto;
    }

    public static SituationGroupeBruteDocumentDTO mapToGroupeBrute(VersementsSituation v) {
        SituationGroupeBruteDocumentDTO dto = new SituationGroupeBruteDocumentDTO();
        dto.setNom(v.getNom());
        dto.setAdresse1(v.getAdresse1());
        dto.setAdresse2(v.getAdresse2());
        dto.setVille(v.getVille());
        dto.setNomContractant(v.getContractant());
        dto.setCategorie(toStringOrNull(v.getCategorie()));
        dto.setPolice(toStringOrNull(v.getPolice()));
        dto.setMatricule(toStringOrNull(v.getMatricule()));
        dto.setDerniereEcheanceCapitalisee(v.getDerniereEcheancePayee() != null ? v.getDerniereEcheancePayee().toString() : null);
        dto.setMontantNet(v.getSituationBrute());
        dto.setSommeCotisationPeriode(v.getTotalVersements());
        dto.setSommeCotisationPatronale(v.getCotisationPatronale());
        dto.setSommeCotisationSalariale(v.getCotisationSalariale());
        dto.setMontantAvanceNonRemboursee(v.getAvanceNonRemboursees());
        dto.setMontant(v.getSituationBrute());
        return dto;
    }

    public static SituationNetteGroupeDocumentDTO mapToGroupeNette(VersementsSituation v) {
        SituationNetteGroupeDocumentDTO dto = new SituationNetteGroupeDocumentDTO();
        dto.setNom(v.getNom());
        dto.setAdresse1(v.getAdresse1());
        dto.setAdresse2(v.getAdresse2());
        dto.setVille(v.getVille());
        dto.setCategorie(toStringOrNull(v.getCategorie()));
        dto.setPolice(toStringOrNull(v.getPolice()));
        dto.setMatricule(toStringOrNull(v.getMatricule()));
        dto.setDerniereEcheance(v.getDerniereEcheancePayee() != null ? v.getDerniereEcheancePayee().toString() : null);
        dto.setMontantNet(v.getSituationNette());
        dto.setMontantIR(v.getMontantIR());
        dto.setMontantAvanceNonRembourseeCapitalisee(v.getAvanceNonRemboursees());
        dto.setCotisationTotale(v.getCotisationSalariale());
        return dto;
    }

    public static SituationIndividuelleDocumentDTO mapToIndividuelle(VersementsSituation v) {
        SituationIndividuelleDocumentDTO dto = new SituationIndividuelleDocumentDTO();
        dto.setNom(buildFullName(v));
        dto.setAdresse1(v.getAdresse1());
        dto.setAdresse2(v.getAdresse2());
        dto.setVille(v.getVille());
        dto.setCategorie(toStringOrNull(v.getCategorie()));
        dto.setPolice(toStringOrNull(v.getPolice()));
        dto.setDerniereEcheance(v.getDerniereEcheancePayee() != null ? v.getDerniereEcheancePayee().toString() : null);
        dto.setMontantNet(v.getSituationNette());
        dto.setMontantIR(v.getMontantIR());
        dto.setMontantAvanceNonRemboursee(v.getAvanceNonRemboursees());
        dto.setCotisationTotale(v.getCotisationSalariale());
        return dto;
    }

    private static String buildFullName(VersementsSituation v) {
        StringBuilder sb = new StringBuilder();
        if (v.getCivilite() != null && v.getCivilite().trim().length() > 0) {
            sb.append(v.getCivilite().trim()).append(" ");
        }
        if (v.getNom() != null) {
            sb.append(v.getNom().trim()).append(" ");
        }
        if (v.getPrenom() != null && v.getPrenom().trim().length() > 0) {
            sb.append(v.getPrenom().trim());
        }
        return sb.toString().trim();
    }

    private static String toStringOrNull(Long value) {
        return value != null ? value.toString() : null;
    }
}
