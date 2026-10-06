# Build context is the REPO ROOT: docker build -f demo-dotnet/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY demo-dotnet/demo-dotnet.csproj ./
RUN dotnet restore
COPY demo-dotnet/ ./
RUN dotnet publish -c Release -o /out --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app/demo-dotnet
COPY demo-dotnet/run.sh ./run.sh
COPY --from=build /out ./publish
COPY demo.sqlite /app/demo.sqlite
ENV PORT=8082
EXPOSE 8082
CMD ["./run.sh", "start"]
