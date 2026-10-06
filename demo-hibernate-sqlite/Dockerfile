# Build context is the REPO ROOT: docker build -f demo-hibernate-sqlite/Dockerfile .
FROM maven:3-eclipse-temurin-27 AS build
WORKDIR /repo/demo-hibernate-sqlite
COPY demo-hibernate-sqlite/pom.xml ./
RUN mvn -B -q dependency:go-offline -DskipTests || true
COPY demo-hibernate-sqlite/src ./src
RUN mvn -B -DskipTests package

# ../test.sh hibernate-sqlite: runs the endpoint tests against this container's own copy of the dataset.
FROM build AS test
COPY demo.sqlite /repo/demo.sqlite
CMD ["mvn", "-B", "--no-transfer-progress", "test"]

FROM eclipse-temurin:27-jre
WORKDIR /app/demo-hibernate-sqlite
COPY demo-hibernate-sqlite/run.sh ./run.sh
COPY --from=build /repo/demo-hibernate-sqlite/target/*.jar ./target/
COPY demo.sqlite /app/demo.sqlite
ENV PORT=8080
EXPOSE 8080
CMD ["./run.sh", "start"]
