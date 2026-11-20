# Build context is the REPO ROOT: docker build -f demo-hibernate-sqlite/Dockerfile .

# ffm-sqlite-jdbc is published only to GitHub Packages, which needs a token even for public
# packages, so the pinned 0.2.7 release is built from source into the local Maven repository.
FROM maven:3-eclipse-temurin-27 AS ffm-sqlite
ADD --checksum=sha256:4852225de9238e72ff93f6704e827816be6ddafb75b3e92db6666d5540ea6f68 \
    https://github.com/revsnai/ffm-sqlite/archive/259f8122c96a57b8964b3d9765f579d659552e6d.tar.gz \
    /tmp/ffm-sqlite.tar.gz
RUN mkdir /ffm-sqlite && tar -xzf /tmp/ffm-sqlite.tar.gz -C /ffm-sqlite --strip-components=1
WORKDIR /ffm-sqlite/ffm-sqlite-parent
RUN mvn -B -q -DskipTests -pl ../ffm-sqlite,../ffm-sqlite-jdbc -am install

FROM maven:3-eclipse-temurin-27 AS build
# ffm-sqlite loads the system SQLite; the tests in the test stage need it too.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=ffm-sqlite /root/.m2/repository/io/github/revsnai /root/.m2/repository/io/github/revsnai
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
RUN apt-get update \
    && apt-get install -y --no-install-recommends libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app/demo-hibernate-sqlite
COPY demo-hibernate-sqlite/run.sh ./run.sh
COPY --from=build /repo/demo-hibernate-sqlite/target/*.jar ./target/
COPY demo.sqlite /app/demo.sqlite
ENV PORT=8080
EXPOSE 8080
CMD ["./run.sh", "start"]
