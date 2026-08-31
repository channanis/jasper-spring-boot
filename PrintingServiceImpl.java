@Override
public PrintingDownloadOutputDTO downloadDocument(Long numCat, Long police, Long matricule, String codeDocument, HttpServletRequest request) {

    log.info("Start printing doc with numContrat={}, numCat={}, matricule={}, codeDocument={}",
            new Object[]{police, numCat, matricule, codeDocument});

    // Vérification d'autorisation (inchangé)
    if (authorizationUtil.isCustomerNotAuthorized(
            request,
            police,
            numCat.intValue(),
            matricule)) {
        log.warn("Authorization failed for contrat={}, categorie={}, matricule={}", new Object[]{police, numCat, matricule});
        throw new ForbiddenException("Accès interdit", "FORBIDDEN");
    }

    if (codeDocument == null || codeDocument.trim().length() == 0) {
        throw new TechnicalException("codeDocument est obligatoire");
    }

    DocumentGenerationRequest generationRequest = new DocumentGenerationRequest();
    generationRequest.setFormat("PDF");

    if (isAttestationVersement(codeDocument)) {
        // ===== ATTESTATION DE VERSEMENT : flux inchangé =====
        VersementsResponse versements = businessContratClientMS.loadVersements(numCat, police, matricule);

        switch (versements.getCategorieParente()) {
            case "BANCASS":
                BancassDocumentDTO bancass = VersementMapper.mapToBancass(versements);
                generationRequest.setCode("ATTESTATION_VERSEMENT_BANCASS");
                generationRequest.setData(bancass.toMap());
                break;

            case "GROUPE":
                GroupDocumentDTO group = VersementMapper.mapToGroup(versements);
                generationRequest.setCode("ATTESTATION_VERSEMENT_GROUPE");
                generationRequest.setData(group.toMap());
                break;

            case "INDIVIDUAL":
                IndividualDocumentDTO individual = VersementMapper.mapToIndividual(versements);
                generationRequest.setCode("ATTESTATION_VERSEMENT_INDIVIDUAL");
                generationRequest.setData(individual.toMap());
                break;

            default:
                throw new TechnicalException("Categorie non supportée");
        }

    } else {
        // ===== SITUATION (brute / nette) : une seule source de données =====
        VersementsSituation situation = businessContratClientMS.loadSituation(numCat, police, matricule);

        switch (codeDocument) {
            case "SITUATION_BRUTE_EPARGNE_BANCASS":
                SituationBancassDocumentDTO bancassSituation = SituationMapper.mapToBancass(situation);
                generationRequest.setCode("SITUATION_BRUTE_EPARGNE_BANCASS");
                generationRequest.setData(bancassSituation.toMap());
                break;

            case "SITUATION_BRUTE_GROUPE":
                SituationGroupeBruteDocumentDTO groupeBrute = SituationMapper.mapToGroupeBrute(situation);
                generationRequest.setCode("SITUATION_BRUTE_GROUPE");
                generationRequest.setData(groupeBrute.toMap());
                break;

            case "SITUATION_NETTE_GROUPE":
                SituationNetteGroupeDocumentDTO groupeNette = SituationMapper.mapToGroupeNette(situation);
                generationRequest.setCode("SITUATION_NETTE_GROUPE");
                generationRequest.setData(groupeNette.toMap());
                break;

            case "SITUATION_BRUTE_NETTE_INDIVIDUELLE":
                SituationIndividuelleDocumentDTO individuelle = SituationMapper.mapToIndividuelle(situation);
                generationRequest.setCode("SITUATION_BRUTE_NETTE_INDIVIDUELLE");
                generationRequest.setData(individuelle.toMap());
                break;

            default:
                throw new TechnicalException("codeDocument non supporté : " + codeDocument);
        }
    }

    PrintingDownloadOutputDTO generated = printingClientMS.generateDocument(generationRequest);
    log.info("End downloadContractVersement: fileName={}", generated.getFileName());
    return generated;
}

private boolean isAttestationVersement(String codeDocument) {
    return codeDocument.startsWith("ATTESTATION_VERSEMENT");
}
