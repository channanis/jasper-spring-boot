package com.example.contrat.service;

import com.example.contrat.dto.ContratMobileDTO;
import com.example.contrat.enums.Canal;
import com.example.contrat.enums.Source;

import java.util.List;

public interface ContratService {

    List<ContratMobileDTO> searchContracts(String cin, String typeProduit, Canal canal);

    /**
     * Source gérée par cette implémentation — utilisée par {@link ContratServiceFactory}
     * pour sélectionner la bonne stratégie.
     */
    Source getSource();
}
