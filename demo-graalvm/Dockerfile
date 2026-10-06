# Build context is the REPO ROOT: docker build -f demo-graalvm/Dockerfile .
#
# Native image of the SAME application as demo-hibernate-sqlite, so the GraalVM row and the
# OpenJDK row differ only in how the app was compiled.
FROM ghcr.io/graalvm/graalvm-community:25 AS build
# The GraalVM image ships no maven; borrow it from the official maven image.
COPY --from=maven:3-eclipse-temurin-25 /usr/share/maven /usr/share/maven
ENV PATH="/usr/share/maven/bin:${PATH}"
WORKDIR /src
COPY demo-hibernate-sqlite/pom.xml ./
RUN mvn -B -q -Pnative -DskipTests dependency:go-offline || true
COPY demo-hibernate-sqlite/src ./src
RUN mvn -B -DskipTests -Pnative clean package native:compile

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends zlib1g ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app/demo-graalvm
COPY demo-graalvm/run.sh ./run.sh
COPY --from=build /src/target/demo-hibernate-sqlite ./demo-graalvm-app
COPY demo.sqlite /app/demo.sqlite
ENV PORT=8083
EXPOSE 8083
CMD ["./run.sh", "start"]
