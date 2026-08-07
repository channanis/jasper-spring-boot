package com.example.contrat.feign;

import com.example.contrat.enums.Canal;
import feign.RequestInterceptor;
import feign.RequestTemplate;

/**
 * Injects the X-Canal header on every outgoing call to the contract search API.
 * Registered ONLY in BFF-SAH's @FeignClient(configuration = ...), so it never
 * leaks into the other BFF's client — consistent with the per-client config
 * isolation already used for the proxy setup.
 */
public class CanalHeaderInterceptor implements RequestInterceptor {

    @Override
    public void apply(RequestTemplate template) {
        template.header(Canal.HEADER_NAME, Canal.BFF_SAH.name());
    }
}
