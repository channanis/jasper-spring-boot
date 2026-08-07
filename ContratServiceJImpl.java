package com.example.contrat.service.impl;

import com.example.contrat.enums.Source;
import com.example.contrat.service.AbstractContratService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Source J : agrège bancass + groupe + individual repositories.
 * NB: suppose que les 3 repositories exposent les mêmes signatures que
 * ContratRepository (findAllByCinIgnoreCase / findAllByCinIgnoreCaseAndTypeProduitIn).
 * Adapter les noms de méthode si ce n'est pas le cas.
 */
@Service
@Slf4j
public class ContratServiceJImpl extends AbstractContratService {

    private final BancassRepository bancassRepository;
    private final GroupeRepository groupeRepository;
    private final IndividualRepository individualRepository;

    public ContratServiceJImpl(AdherentStaffRepository adherentStaffRepository,
                                AdherentStaffMapper adherentStaffMapper,
                                ContratMobileMapper contratMobileMapper,
                                BancassRepository bancassRepository,
                                GroupeRepository groupeRepository,
                                IndividualRepository individualRepository) {
        super(adherentStaffRepository, adherentStaffMapper, contratMobileMapper);
        this.bancassRepository = bancassRepository;
        this.groupeRepository = groupeRepository;
        this.individualRepository = individualRepository;
    }

    @Override
    public Source getSource() {
        return Source.J;
    }

    @Override
    protected List<ContratMobile> fetchContractsByType(String cin, String typeProduit) {
        log.info("Fetching J contracts for CIN={} from bancass + groupe + individual", cin);

        List<ContratMobile> contracts = new ArrayList<>();
        contracts.addAll(fetchFrom(bancassRepository, cin, typeProduit));
        contracts.addAll(fetchFrom(groupeRepository, cin, typeProduit));
        contracts.addAll(fetchFrom(individualRepository, cin, typeProduit));

        log.info("J contracts found: bancass+groupe+individual total={}", contracts.size());
        return contracts;
    }

    private List<ContratMobile> fetchFrom(ContratSourceRepository repository, String cin, String typeProduit) {
        if (typeProduit == null || typeProduit.isBlank()) {
            return repository.findAllByCinIgnoreCase(cin);
        }
        return repository.findAllByCinIgnoreCaseAndTypeProduitIn(cin, List.of(typeProduit));
    }
}
