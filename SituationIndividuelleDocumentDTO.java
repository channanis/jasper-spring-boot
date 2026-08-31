import java.util.HashMap;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class SituationIndividuelleDocumentDTO {
    private String nom;
    private String adresse1;
    private String adresse2;
    private String ville;
    private String categorie;
    private String police;
    private String derniereEcheance;
    private Double montantNet;
    private Double montantIR;
    private Double montantAvanceNonRemboursee;
    private Double cotisationTotale;

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("nom", nom);
        map.put("adresse1", adresse1);
        map.put("adresse2", adresse2);
        map.put("ville", ville);
        map.put("categorie", categorie);
        map.put("police", police);
        map.put("derniereEcheance", derniereEcheance);
        map.put("montantNet", montantNet);
        map.put("montantIR", montantIR);
        map.put("montantAvanceNonRemboursee", montantAvanceNonRemboursee);
        map.put("cotisationTotale", cotisationTotale);
        return map;
    }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getAdresse1() { return adresse1; }
    public void setAdresse1(String adresse1) { this.adresse1 = adresse1; }
    public String getAdresse2() { return adresse2; }
    public void setAdresse2(String adresse2) { this.adresse2 = adresse2; }
    public String getVille() { return ville; }
    public void setVille(String ville) { this.ville = ville; }
    public String getCategorie() { return categorie; }
    public void setCategorie(String categorie) { this.categorie = categorie; }
    public String getPolice() { return police; }
    public void setPolice(String police) { this.police = police; }
    public String getDerniereEcheance() { return derniereEcheance; }
    public void setDerniereEcheance(String derniereEcheance) { this.derniereEcheance = derniereEcheance; }
    public Double getMontantNet() { return montantNet; }
    public void setMontantNet(Double montantNet) { this.montantNet = montantNet; }
    public Double getMontantIR() { return montantIR; }
    public void setMontantIR(Double montantIR) { this.montantIR = montantIR; }
    public Double getMontantAvanceNonRemboursee() { return montantAvanceNonRemboursee; }
    public void setMontantAvanceNonRemboursee(Double montantAvanceNonRemboursee) { this.montantAvanceNonRemboursee = montantAvanceNonRemboursee; }
    public Double getCotisationTotale() { return cotisationTotale; }
    public void setCotisationTotale(Double cotisationTotale) { this.cotisationTotale = cotisationTotale; }
}
