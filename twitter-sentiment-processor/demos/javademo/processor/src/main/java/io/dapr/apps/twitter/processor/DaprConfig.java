/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */

package io.dapr.apps.twitter.processor;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.dapr.client.DaprClient;
import io.dapr.client.DaprClientBuilder;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Configuration
public class DaprConfig {

  private static final DaprClientBuilder BUILDER = new DaprClientBuilder();

  @Bean(name = "endpoint")
  public String fetchEndpoint() {
    return fetchSecret("Azure:CognitiveServices:Endpoint");
  }

  @Bean(name = "subscriptionKey")
  public String fetchSubscriptionKey() {
    return fetchSecret("Azure:CognitiveServices:SubscriptionKey");
  }

  private static String fetchSecret(String secret) {
    return buildDaprClient().getSecret("secretstore", secret).block().values().iterator().next();
  }

  private static DaprClient buildDaprClient() {
    log.info("Creating a new Dapr Client");
    return BUILDER.build();
  }
}
