package com.example.contrat.service;

import com.example.contrat.dto.ContratMobileDTO;
import com.example.contrat.enums.Canal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ContratServiceImpl implements ContratService {

    private final ContratRepository contratRepository;
    private final OfferRepository offerRepository;
    private final AdherentStaffRepository adherentStaffRepository;
    private final AdherentStaffMapper adherentStaffMapper;
    private final ContratMobileMapper contratMobileMapper;

    @Override
    @Transactional(readOnly = true)
    public List<ContratMobileDTO> searchContracts(String cin, String typeProduit, Canal canal) {
        log.info("Start service searchContracts: cin={}, type={}, canal={}", cin, typeProduit, canal);

        List<ContratMobile> contracts = fetchContractsByType(cin, typeProduit);

        if (shouldIncludeStaffContracts(canal)) {
            contracts.addAll(fetchStaffContracts(cin, contracts));
        }

        List<ContratMobileDTO> output = contratMobileMapper.toContractMobileList(filterAllowed(contracts));
        log.info("End service searchContracts: total={}", output.size());
        return output;
    }

    private List<ContratMobile> fetchContractsByType(String cin, String typeProduit) {
        if (typeProduit == null || typeProduit.isBlank()) {
            return new ArrayList<>(contratRepository.findAllByCinIgnoreCase(cin));
        }
        if (!ProductTypeEnum.EPARGNE.getLabel().equalsIgnoreCase(typeProduit)) {
            return new ArrayList<>(contratRepository.findAllByCinIgnoreCaseAndTypeProduitIn(cin, List.of(typeProduit)));
        }
        return fetchEpargneContracts(cin);
    }

    private List<ContratMobile> fetchEpargneContracts(String cin) {
        log.info("Fetching EPARGNE contracts for CIN={} using offer configuration", cin);
        List<Offer> offersEpargnes = offerRepository.findByEpargne();
        log.info("Offers with EPARGNE flag found: {}", offersEpargnes.size());

        List<ContratMobile> result = new ArrayList<>();
        for (Offer offer : offersEpargnes) {
            result.addAll(contratRepository.findAllByCinIgnoreCaseAndNumCat(cin, offer.getNumCat()));
        }
        return result;
    }

    /**
     * BFF_SAH excludes staff contracts (DYNAMIQUE_ENTREPRISE) from the search result.
     * Centralizing the rule here keeps it a single, easily testable decision point
     * instead of scattering canal checks across the flow.
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
