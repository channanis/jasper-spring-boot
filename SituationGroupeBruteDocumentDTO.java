import java.util.HashMap;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class SituationGroupeBruteDocumentDTO {
    private String nom;
    private String adresse1;
    private String adresse2;
    private String ville;
    private String nomContractant;
    private String categorie;
    private String police;
    private String matricule;
    private String derniereEcheanceCapitalisee;
    private Double montantNet;
    private Double sommeCotisationPeriode;
    private Double sommeCotisationPatronale;
    private Double sommeCotisationSalariale;
    private Double montantAvanceNonRemboursee;
    private Double montant;

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("nom", nom);
        map.put("adresse1", adresse1);
        map.put("adresse2", adresse2);
        map.put("ville", ville);
        map.put("nomContractant", nomContractant);
        map.put("categorie", categorie);
        map.put("police", police);
        map.put("matricule", matricule);
        map.put("derniereEcheanceCapitalisee", derniereEcheanceCapitalisee);
        map.put("montantNet", montantNet);
        map.put("sommeCotisationPeriode", sommeCotisationPeriode);
        map.put("sommeCotisationPatronale", sommeCotisationPatronale);
        map.put("sommeCotisationSalariale", sommeCotisationSalariale);
        map.put("montantAvanceNonRemboursee", montantAvanceNonRemboursee);
        map.put("montant", montant);
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
    public String getNomContractant() { return nomContractant; }
    public void setNomContractant(String nomContractant) { this.nomContractant = nomContractant; }
    public String getCategorie() { return categorie; }
    public void setCategorie(String categorie) { this.categorie = categorie; }
    public String getPolice() { return police; }
    public void setPolice(String police) { this.police = police; }
    public String getMatricule() { return matricule; }
    public void setMatricule(String matricule) { this.matricule = matricule; }
    public String getDerniereEcheanceCapitalisee() { return derniereEcheanceCapitalisee; }
    public void setDerniereEcheanceCapitalisee(String derniereEcheanceCapitalisee) { this.derniereEcheanceCapitalisee = derniereEcheanceCapitalisee; }
    public Double getMontantNet() { return montantNet; }
    public void setMontantNet(Double montantNet) { this.montantNet = montantNet; }
    public Double getSommeCotisationPeriode() { return sommeCotisationPeriode; }
    public void setSommeCotisationPeriode(Double sommeCotisationPeriode) { this.sommeCotisationPeriode = sommeCotisationPeriode; }
    public Double getSommeCotisationPatronale() { return sommeCotisationPatronale; }
    public void setSommeCotisationPatronale(Double sommeCotisationPatronale) { this.sommeCotisationPatronale = sommeCotisationPatronale; }
    public Double getSommeCotisationSalariale() { return sommeCotisationSalariale; }
    public void setSommeCotisationSalariale(Double sommeCotisationSalariale) { this.sommeCotisationSalariale = sommeCotisationSalariale; }
    public Double getMontantAvanceNonRemboursee() { return montantAvanceNonRemboursee; }
    public void setMontantAvanceNonRemboursee(Double montantAvanceNonRemboursee) { this.montantAvanceNonRemboursee = montantAvanceNonRemboursee; }
    public Double getMontant() { return montant; }
    public void setMontant(Double montant) { this.montant = montant; }
}
