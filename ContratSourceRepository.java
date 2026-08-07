package com.example.contrat.service.impl;

import java.util.List;

/**
 * Contrat commun implémenté par BancassRepository, GroupeRepository et
 * IndividualRepository, pour permettre un traitement uniforme dans
 * {@link ContratServiceJImpl#fetchFrom}. À faire étendre par les 3
 * repositories Spring Data existants (en plus de JpaRepository).
 */
public interface ContratSourceRepository {

    List<ContratMobile> findAllByCinIgnoreCase(String cin);

    List<ContratMobile> findAllByCinIgnoreCaseAndTypeProduitIn(String cin, List<String> typeProduits);
}
