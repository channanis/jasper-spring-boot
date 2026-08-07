package com.example.contrat.service;

import com.example.contrat.enums.Source;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class ContratServiceFactory {

    private final Map<Source, ContratService> strategies;

    public ContratServiceFactory(List<ContratService> services) {
        this.strategies = services.stream()
                .collect(Collectors.toMap(ContratService::getSource, Function.identity()));
    }

    public ContratService resolve(Source source) {
        ContratService service = strategies.get(source);
        if (service == null) {
            throw new IllegalStateException("Aucune implémentation ContratService pour la source: " + source);
        }
        return service;
    }
}
