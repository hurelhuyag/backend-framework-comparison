# Build context is the REPO ROOT: docker build -f demo-hibernate-sqlite/Dockerfile .
FROM maven:3-eclipse-temurin-27 AS build
WORKDIR /repo/demo-hibernate-sqlite
COPY demo-hibernate-sqlite/pom.xml ./
RUN mvn -B -q dependency:go-offline -DskipTests || true
COPY demo-hibernate-sqlite/src ./src
RUN mvn -B -DskipTests package

# ../test.sh hibernate-sqlite: runs the endpoint tests against the database named by the
# DATABASE_URL / PG* variables it passes in (a fresh clone of demo_template).
FROM build AS test
CMD ["mvn", "-B", "--no-transfer-progress", "test"]

FROM eclipse-temurin:27-jre
WORKDIR /app/demo-hibernate-sqlite
COPY demo-hibernate-sqlite/run.sh ./run.sh
COPY --from=build /repo/demo-hibernate-sqlite/target/*.jar ./target/
ENV PORT=8080
ENV DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32
EXPOSE 8080
CMD ["./run.sh", "start"]
