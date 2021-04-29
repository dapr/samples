/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */

package io.dapr.apps.twitter.processor;

import java.util.Map;
import java.util.Optional;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.dapr.client.DaprClient;
import io.dapr.client.DaprClientBuilder;
import io.dapr.client.domain.GetSecretRequestBuilder;

@Configuration
public class DaprConfig {

  private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(DaprConfig.class);

  private static final String SECRET_STORE =
    Optional.ofNullable(System.getenv("SECRET_STORE")).orElse("secretstore");

  private static final String ENDPOINT_SECRET_KEY =
    Optional.ofNullable(System.getenv("ENDPOINT_SECRET_KEY")).orElse("Azure:CognitiveServices:Endpoint");

  private static final String SUBSCRIPTION_KEY_SECRET_KEY =
    Optional.ofNullable(System.getenv("SUBSCRIPTION_KEY_SECRET_KEY")).orElse("Azure:CognitiveServices:SubscriptionKey");

  private static final String SECRET_STORE_NAMESPACE = System.getenv("SECRET_STORE_NAMESPACE");

  private static final DaprClientBuilder BUILDER = new DaprClientBuilder();

  @Bean(name = "endpoint")
  public String fetchEndpoint() {
    return fetchSecret(ENDPOINT_SECRET_KEY);
  }

  @Bean(name = "subscriptionKey")
  public String fetchSubscriptionKey() {
    return fetchSecret(SUBSCRIPTION_KEY_SECRET_KEY);
  }

  private static String fetchSecret(String secret) {
    GetSecretRequestBuilder builder = new GetSecretRequestBuilder(SECRET_STORE, secret);
    if (SECRET_STORE_NAMESPACE != null) {
      builder.withMetadata(Map.of("namespace", SECRET_STORE_NAMESPACE));
    }

    return buildDaprClient().getSecret(builder.build()).block().getObject().values().iterator().next();
  }

  private static DaprClient buildDaprClient() {
    log.info("Creating a new Dapr Client");
    return BUILDER.build();
  }

}
