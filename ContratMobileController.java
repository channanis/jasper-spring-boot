package com.example.contrat.controller;

import com.example.contrat.dto.ContratMobileDTO;
import com.example.contrat.enums.Canal;
import com.example.contrat.exception.InvalidCanalException;
import com.example.contrat.service.ContratService;
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

    private final ContratService contratService;

    @Operation(
            summary = "Search contracts by CIN",
            description = "Retrieve contracts by CIN. Optionally filter by typeProduit. "
                    + "The X-Canal header identifies the calling BFF and drives channel-specific business rules."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Contracts found"),
            @ApiResponse(responseCode = "400", description = "Missing or invalid X-Canal header"),
            @ApiResponse(responseCode = "404", description = "No contracts found")
    })
    @GetMapping("/search")
    public List<ContratMobileDTO> searchContracts(
            @Parameter(description = "Customer CIN", required = true)
            @RequestParam String cin,
            @Parameter(description = "Optional contract type")
            @RequestParam(required = false) String typeProduit,
            @Parameter(hidden = true)
            @RequestHeader(Canal.HEADER_NAME) String canalHeader) {

        Canal canal = resolveCanal(canalHeader);

        log.info("Start resource searchContracts: cin={}, type={}, canal={}", cin, typeProduit, canal);
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
}
