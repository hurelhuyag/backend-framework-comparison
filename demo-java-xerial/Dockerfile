# Build context is the REPO ROOT: docker build -f demo-java-xerial/Dockerfile .
#
# demo-hibernate-sqlite built with -Pxerial: the SAME application on xerial's sqlite-jdbc (JNI,
# bundled SQLite) instead of ffm-sqlite-jdbc, so the two rows differ only in the JDBC driver.
FROM maven:3-eclipse-temurin-27 AS build
WORKDIR /repo/demo-hibernate-sqlite
COPY demo-hibernate-sqlite/pom.xml ./
RUN mvn -B -q -Pxerial dependency:go-offline -DskipTests || true
COPY demo-hibernate-sqlite/src ./src
RUN mvn -B -Pxerial -DskipTests package

FROM build AS test
COPY demo.sqlite /repo/demo.sqlite
CMD ["mvn", "-B", "--no-transfer-progress", "-Pxerial", "test"]

FROM eclipse-temurin:27-jre
WORKDIR /app/demo-java-xerial
COPY demo-java-xerial/run.sh ./run.sh
COPY demo-hibernate-sqlite/run.sh ./java-run.sh
COPY --from=build /repo/demo-hibernate-sqlite/target/*.jar ./target/
COPY demo.sqlite /app/demo.sqlite
ENV PORT=8085
EXPOSE 8085
CMD ["./run.sh", "start"]
