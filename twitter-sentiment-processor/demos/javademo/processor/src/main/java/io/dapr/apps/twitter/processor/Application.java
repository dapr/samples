/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */

package io.dapr.apps.twitter.processor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import static java.lang.System.out;

@SpringBootApplication(scanBasePackages = { "io.dapr.apps.twitter.processor", "io.dapr.springboot" })
public class Application {

    public static void main(String[] args) {
        printJavaVersion();
        SpringApplication.run(Application.class, args);
    }

    private static final void printJavaVersion() {
        var runtime = System.getProperty("java.runtime.name");
        var vendor = System.getProperty("java.vendor.version");
        var build = System.getProperty("java.vm.version");
        out.printf("\n%s %s (build %s)", runtime, vendor, build);
    }

}
