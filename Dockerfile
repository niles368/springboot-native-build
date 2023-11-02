## Stage 1 : build with maven builder image with native capabilities
# FROM quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21 AS build
FROM registry.access.redhat.com/quarkus/mandrel-22-rhel8:22.3-28 AS builder

COPY --chown=quarkus:quarkus mvnw /code/mvnw
COPY --chown=quarkus:quarkus .mvn /code/.mvn
COPY --chown=quarkus:quarkus pom_i.xml /code/pom.xml
USER quarkus

# Set the working directory to /home/app
WORKDIR /code
# maven依賴外掛的離線模式,可以省略
RUN ./mvnw -B org.apache.maven.plugins:maven-dependency-plugin:3.6.1:go-offline
COPY src /code/src


# Build
# RUN ./mvnw package -Dnative
RUN ./mvnw --no-transfer-progress native:compile -Pnative

# The deployment Image
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.8-1072.1697626218

WORKDIR /work/
# Copy the native executable into the containers
COPY --from=builder /code/target/hello /work/application
# COPY --from=builder /code/target/*-runner /work/application

# set up permissions for user `1001`
RUN chmod 775 /work /work/application \
  && chown -R 1001 /work \
  && chmod -R "g+rwX" /work \
  && chown -R 1001:root /work

EXPOSE 8080
USER 1001

CMD ["./application"]
# CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]