package com.example.contrat.service;

import com.example.contrat.dto.ContratMobileDTO;
import com.example.contrat.enums.Canal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * Template method : factorise tout ce qui est commun aux deux sources (J / J-1) —
 * inclusion des contrats staff selon le canal, filtrage, mapping.
 * Seule la récupération des contrats ({@link #fetchContractsByType}) varie
 * et est déléguée à chaque sous-classe.
 */
@Slf4j
@RequiredArgsConstructor
public abstract class AbstractContratService implements ContratService {

    private final AdherentStaffRepository adherentStaffRepository;
    private final AdherentStaffMapper adherentStaffMapper;
    private final ContratMobileMapper contratMobileMapper;

    @Override
    @Transactional(readOnly = true)
    public List<ContratMobileDTO> searchContracts(String cin, String typeProduit, Canal canal) {
        log.info("Start service searchContracts: cin={}, type={}, canal={}, source={}",
                cin, typeProduit, canal, getSource());

        List<ContratMobile> contracts = fetchContractsByType(cin, typeProduit);

        if (shouldIncludeStaffContracts(canal)) {
            contracts.addAll(fetchStaffContracts(cin, contracts));
        }

        List<ContratMobileDTO> output = contratMobileMapper.toContractMobileList(filterAllowed(contracts));
        log.info("End service searchContracts: source={}, total={}", getSource(), output.size());
        return output;
    }

    /**
     * Récupération des contrats — spécifique à chaque source (repositories différents).
     */
    protected abstract List<ContratMobile> fetchContractsByType(String cin, String typeProduit);

    /**
     * BFF_SAH exclut les contrats staff (DYNAMIQUE_ENTREPRISE), quelle que soit la source.
     */
    private boolean shouldIncludeStaffContracts(Canal canal) {
        return canal != Canal.BFF_SAH;
    }

    private List<ContratMobile> fetchStaffContracts(String cin, List<ContratMobile> existingContracts) {
        List<AdherentStaff> staffEntities =
                adherentStaffRepository.findByCinAndNumcatIgnoreCaseTrim(cin, ProduitConstants.DYNAMIQUE_ENTREPRISE);
        List<ContratMobile> staffContracts = adherentStaffMapper.toContratsMobileList(staffEntities);

        Long maxId = getMaxId(existingContracts);
        setIdsForContractsWithNullIds(maxId, staffContracts);

        return staffContracts;
    }

    private List<ContratMobile> filterAllowed(List<ContratMobile> contracts) {
        return contracts.stream()
                .filter(c -> ProductTypeEnum.isAllowed(c.getTypeProduit()))
                .collect(Collectors.toCollection(ArrayList::new));
    }

    private Long getMaxId(List<ContratMobile> contracts) {
        return contracts.stream()
                .map(ContratMobile::getId)
                .filter(Objects::nonNull)
                .max(Long::compareTo)
                .orElse(0L);
    }

    private void setIdsForContractsWithNullIds(Long startId, List<ContratMobile> contracts) {
        long id = startId + 1;
        for (ContratMobile c : contracts) {
            if (c.getId() == null) {
                c.setId(id++);
            }
        }
    }
}
