package com.example.contrat.service;

import com.example.contrat.dto.ContratMobileDTO;
import com.example.contrat.enums.Canal;

import java.util.List;

public interface ContratService {

    /**
     * Searches contracts for a CIN, optionally filtered by product type.
     * Business rules vary by calling channel (canal) — e.g. BFF_SAH excludes
     * staff (DYNAMIQUE_ENTREPRISE) contracts from the result.
     */
    List<ContratMobileDTO> searchContracts(String cin, String typeProduit, Canal canal);
}
