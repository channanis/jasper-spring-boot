package com.example.contrat.enums;

/**
 * Identifies which BFF is calling the contract search API.
 * Sent by each BFF via the {@link #HEADER_NAME} header, never by the end client directly.
 */
public enum Canal {

    BFF_SAH,
    BFF_DEFAULT;

    public static final String HEADER_NAME = "X-Canal";
}
