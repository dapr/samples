# build stage build the jar with all our resources
FROM maven:3-openjdk-11 as build

VOLUME /tmp
WORKDIR /build

COPY pom.xml .
RUN mvn dependency:go-offline

ADD src/ /build/src/
RUN mvn package

# package stage
FROM gcr.io/distroless/java:11

ARG JAR_FILE
COPY --from=build /build/target/app.jar /opt/app.jar
WORKDIR /opt/

EXPOSE 3000
CMD [ "app.jar", "--server.port=3000" ]