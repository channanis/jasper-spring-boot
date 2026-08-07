package com.example.contrat.exception;

public class InvalidSourceException extends RuntimeException {

    public InvalidSourceException(String source) {
        super("Source invalide: " + source + " (valeurs attendues: J, J_1)");
    }
}
