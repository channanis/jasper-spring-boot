package com.example.contrat.controller;

import com.example.contrat.dto.ContratMobileDTO;
import com.example.contrat.enums.Canal;
import com.example.contrat.enums.Source;
import com.example.contrat.exception.InvalidCanalException;
import com.example.contrat.exception.InvalidSourceException;
import com.example.contrat.service.ContratService;
import com.example.contrat.service.ContratServiceFactory;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/contrats")
@RequiredArgsConstructor
@Slf4j
public class ContratMobileController {

    private final ContratServiceFactory contratServiceFactory;

    @Operation(
            summary = "Search contracts by CIN",
            description = "Retrieve contracts by CIN. Optionally filter by typeProduit. "
                    + "The X-Canal header identifies the calling BFF. "
                    + "The 'source' param selects J (real-time, bancass+groupe+individual) or J-1 (contratRepository)."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Contracts found"),
            @ApiResponse(responseCode = "400", description = "Missing/invalid X-Canal header or source param"),
            @ApiResponse(responseCode = "404", description = "No contracts found")
    })
    @GetMapping("/search")
    public List<ContratMobileDTO> searchContracts(
            @Parameter(description = "Customer CIN", required = true)
            @RequestParam String cin,
            @Parameter(description = "Optional contract type")
            @RequestParam(required = false) String typeProduit,
            @Parameter(description = "Data source: J or J_1", required = true)
            @RequestParam String source,
            @Parameter(hidden = true)
            @RequestHeader(Canal.HEADER_NAME) String canalHeader) {

        Canal canal = resolveCanal(canalHeader);
        Source resolvedSource = resolveSource(source);

        log.info("Start resource searchContracts: cin={}, type={}, canal={}, source={}",
                cin, typeProduit, canal, resolvedSource);

        ContratService contratService = contratServiceFactory.resolve(resolvedSource);
        List<ContratMobileDTO> contracts = contratService.searchContracts(cin, typeProduit, canal);

        log.info("End resource searchContracts: cin={}, type={}, total={}", cin, typeProduit, contracts.size());
        return contracts;
    }

    private Canal resolveCanal(String canalHeader) {
        try {
            return Canal.valueOf(canalHeader.trim().toUpperCase());
        } catch (IllegalArgumentException | NullPointerException e) {
            throw new InvalidCanalException(canalHeader);
        }
    }

    private Source resolveSource(String source) {
        try {
            return Source.valueOf(source.trim().toUpperCase().replace("-", "_"));
        } catch (IllegalArgumentException | NullPointerException e) {
            throw new InvalidSourceException(source);
        }
    }
}
