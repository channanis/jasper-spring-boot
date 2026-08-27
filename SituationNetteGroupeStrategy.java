package ma.lamarocainevie.msapiprinting.strategy;

import lombok.extern.slf4j.Slf4j;
import ma.lamarocainevie.msapiprinting.model.DocumentFormat;
import ma.lamarocainevie.msapiprinting.model.GeneratedDocument;
import ma.lamarocainevie.msapiprinting.service.JasperRenderingService;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Génère l'attestation "Situation nette" pour les contrats Groupe (contrat Dynamic Entreprise).
 * Document mono-page, sans liste répétée : on passe une Collection à 1 élément
 * au moteur de rendu afin que la bande "detail" du template s'imprime exactement une fois.
 *
 * Adapter le package et les imports (DocumentFormat / GeneratedDocument / JasperRenderingService)
 * à l'arborescence réelle du projet si nécessaire.
 */
@Component
@Slf4j
public class SituationNetteGroupeStrategy implements DocumentGeneratorStrategy {

    public static final String CODE = "SITUATION_NETTE_GROUPE";
    private static final String TEMPLATE = "templates/situation_nette_groupe.jrxml";
    private static final DateTimeFormatter FR_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private final JasperRenderingService renderingService;

    public SituationNetteGroupeStrategy(JasperRenderingService renderingService) {
        this.renderingService = renderingService;
    }

    @Override
    public String getDocumentCode() {
        return CODE;
    }

    @Override
    public GeneratedDocument generate(Map<String, Object> data, DocumentFormat format) {
        // 1) mapping des paramètres (aucun accès BDD ici)
        Map<String, Object> reportParams = buildReportParameters(data);

        // 2) rendu pur : un seul "enregistrement" factice pour déclencher l'impression
        //    de la bande "detail" (le template n'utilise aucun $F{...} de la donnée collection)
        byte[] content = renderingService.render(TEMPLATE, reportParams, List.of(new Object()), format);

        String police = requireString(data, "police");
        String fileName = "situation_nette_groupe_%s.%s".formatted(police, format.extension());
        return new GeneratedDocument(content, fileName, format);
    }

    private Map<String, Object> buildReportParameters(Map<String, Object> data) {
        Map<String, Object> p = new HashMap<>();
        p.put("nomAssure", requireString(data, "nomAssure"));
        p.put("adresse1Assure", optionalString(data, "adresse1Assure", ""));
        p.put("adresse2Assure", optionalString(data, "adresse2Assure", ""));
        p.put("villeAssure", optionalString(data, "villeAssure", ""));
        p.put("numeroCategorie", requireString(data, "numeroCategorie"));
        p.put("police", requireString(data, "police"));
        p.put("matricule", optionalString(data, "matricule", ""));
        p.put("dateSysteme", LocalDate.now().format(FR_DATE));
        p.put("derniereEcheance", requireDate(data, "derniereEcheance").format(FR_DATE));
        p.put("montantNet", requireDecimal(data, "montantNet"));
        p.put("montantIR", requireDecimal(data, "montantIR"));
        p.put("montantAvanceNonRembourseeCapitalisee", requireDecimal(data, "montantAvanceNonRembourseeCapitalisee"));
        p.put("montantCotisationSalariale", requireDecimal(data, "montantCotisationSalariale"));
        return p;
    }

    // ===================== Helpers (à remplacer par les utilitaires partagés du projet si déjà présents) =====================

    private String requireString(Map<String, Object> data, String key) {
        Object value = data.get(key);
        if (value == null || value.toString().isBlank()) {
            throw new IllegalArgumentException("Le champ '%s' est obligatoire".formatted(key));
        }
        return value.toString();
    }

    private String optionalString(Map<String, Object> data, String key, String defaultValue) {
        Object value = data.get(key);
        return value == null ? defaultValue : value.toString();
    }

    private LocalDate requireDate(Map<String, Object> data, String key) {
        String raw = requireString(data, key);
        return LocalDate.parse(raw);
    }

    private BigDecimal requireDecimal(Map<String, Object> data, String key) {
        Object value = data.get(key);
        if (value == null) {
            throw new IllegalArgumentException("Le champ '%s' est obligatoire".formatted(key));
        }
        return new BigDecimal(value.toString());
    }
}
