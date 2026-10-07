# Build context is the REPO ROOT: docker build -f demo-dotnet/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY demo-dotnet/demo-dotnet.csproj ./
RUN dotnet restore
COPY demo-dotnet/ ./
RUN dotnet publish -c Release -o /out --no-restore

# Endpoint tests: ./test.sh dotnet  (builds --target test, then runs the image; exit code = result).
# A plain build skips this stage. The tests connect to the PostgreSQL database given by
# DATABASE_URL / PG* at run time (test.sh hands them a fresh clone of demo_template).
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS test
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
WORKDIR /repo/demo-dotnet
COPY demo-dotnet/demo-dotnet.csproj ./
COPY demo-dotnet/tests/demo-dotnet.Tests.csproj ./tests/
RUN dotnet restore tests/demo-dotnet.Tests.csproj
COPY demo-dotnet/ ./
RUN dotnet build tests/demo-dotnet.Tests.csproj --no-restore
CMD ["dotnet", "test", "tests/demo-dotnet.Tests.csproj", "--no-build"]

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app/demo-dotnet
COPY demo-dotnet/run.sh ./run.sh
COPY --from=build /out ./publish
ENV PORT=8082 \
    DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32
EXPOSE 8082
CMD ["./run.sh", "start"]
