package com.example.contrat.exception;

/**
 * Raised when the {@code X-Canal} header is missing or does not match a known {@link com.example.contrat.enums.Canal}.
 */
public class InvalidCanalException extends RuntimeException {

    public InvalidCanalException(String canal) {
        super("Canal invalide ou manquant: " + canal);
    }
}
