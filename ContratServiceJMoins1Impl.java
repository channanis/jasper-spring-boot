package com.example.contrat.service.impl;

import com.example.contrat.enums.Source;
import com.example.contrat.service.AbstractContratService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Source J-1 : recherche via contratRepository (comportement existant, inchangé).
 */
@Service
@Slf4j
public class ContratServiceJMoins1Impl extends AbstractContratService {

    private final ContratRepository contratRepository;
    private final OfferRepository offerRepository;

    public ContratServiceJMoins1Impl(AdherentStaffRepository adherentStaffRepository,
                                      AdherentStaffMapper adherentStaffMapper,
                                      ContratMobileMapper contratMobileMapper,
                                      ContratRepository contratRepository,
                                      OfferRepository offerRepository) {
        super(adherentStaffRepository, adherentStaffMapper, contratMobileMapper);
        this.contratRepository = contratRepository;
        this.offerRepository = offerRepository;
    }

    @Override
    public Source getSource() {
        return Source.J_1;
    }

    @Override
    protected List<ContratMobile> fetchContractsByType(String cin, String typeProduit) {
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
}
