# Build context is the REPO ROOT: docker build -f demo-hibernate-sqlite/Dockerfile .
FROM maven:3-eclipse-temurin-25 AS build
WORKDIR /src
COPY demo-hibernate-sqlite/pom.xml ./
RUN mvn -B -q dependency:go-offline -DskipTests || true
COPY demo-hibernate-sqlite/src ./src
# jte-maven-plugin aborts if its template root is missing; this app only serves JSON, so an
# empty template dir satisfies it without changing the project.
RUN mkdir -p src/main/jte && mvn -B -DskipTests package

FROM eclipse-temurin:25-jre
WORKDIR /app/demo-hibernate-sqlite
COPY demo-hibernate-sqlite/run.sh ./run.sh
COPY --from=build /src/target/*.jar ./target/
COPY demo.sqlite /app/demo.sqlite
ENV PORT=8080
EXPOSE 8080
CMD ["./run.sh", "start"]
