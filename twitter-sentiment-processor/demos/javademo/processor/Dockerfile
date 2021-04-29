# Build stage build the jar with all our resources
FROM maven:3-openjdk-11 as build

WORKDIR /build
COPY pom.xml ./
ADD src /build/src
RUN mvn package

# Base Image
FROM ubuntu:20.04

# Download and Extract the Microsoft Build of OpenJDK from the Microsoft OpenJDK website
RUN apt-get update && \
    apt-get install -y wget && \
    wget https://aka.ms/download-jdk/microsoft-jdk-11.0.11.9.1-linux-x64.tar.gz -O msopenjdk11.tar.gz && \
    tar zxvf msopenjdk11.tar.gz && \
    rm -rf msopenjdk11.tar.gz /var/lib/apt/lists/*

# Create a smaller Java runtime, and delete the JDK
RUN /jdk-11.0.11+9/bin/jlink \
        --add-modules java.se,jdk.httpserver,jdk.unsupported,jdk.jfr \
        --strip-debug \
        --no-man-pages \
        --no-header-files \
        --compress=2 \
        --output /javaruntime && \
    rm -rf /jdk-11.0.11+9/

ARG JAR_FILE
COPY --from=build /build/target/app.jar /opt/app.jar
WORKDIR /opt/

EXPOSE 3000
CMD [ "/javaruntime/bin/java", "-jar", "app.jar", "--server.port=3000" ]
