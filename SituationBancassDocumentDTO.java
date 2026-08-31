import java.util.HashMap;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class SituationBancassDocumentDTO {
    private String titre;
    private String nom;
    private String prenom;
    private String adresse1;
    private String adresse2;
    private String categorie;
    private String police;
    private String dateEffet;
    private Double svk;
    private Double mtcot;
    private Double mtavance;
    private Double vprim;

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("titre", titre);
        map.put("nom", nom);
        map.put("prenom", prenom);
        map.put("adresse1", adresse1);
        map.put("adresse2", adresse2);
        map.put("categorie", categorie);
        map.put("police", police);
        map.put("dateEffet", dateEffet);
        map.put("svk", svk);
        map.put("mtcot", mtcot);
        map.put("mtavance", mtavance);
        map.put("vprim", vprim);
        return map;
    }

    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getPrenom() { return prenom; }
    public void setPrenom(String prenom) { this.prenom = prenom; }
    public String getAdresse1() { return adresse1; }
    public void setAdresse1(String adresse1) { this.adresse1 = adresse1; }
    public String getAdresse2() { return adresse2; }
    public void setAdresse2(String adresse2) { this.adresse2 = adresse2; }
    public String getCategorie() { return categorie; }
    public void setCategorie(String categorie) { this.categorie = categorie; }
    public String getPolice() { return police; }
    public void setPolice(String police) { this.police = police; }
    public String getDateEffet() { return dateEffet; }
    public void setDateEffet(String dateEffet) { this.dateEffet = dateEffet; }
    public Double getSvk() { return svk; }
    public void setSvk(Double svk) { this.svk = svk; }
    public Double getMtcot() { return mtcot; }
    public void setMtcot(Double mtcot) { this.mtcot = mtcot; }
    public Double getMtavance() { return mtavance; }
    public void setMtavance(Double mtavance) { this.mtavance = mtavance; }
    public Double getVprim() { return vprim; }
    public void setVprim(Double vprim) { this.vprim = vprim; }
}
