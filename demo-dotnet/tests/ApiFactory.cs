using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Xunit;

namespace DemoDotnet.Tests;

// Boots the real app (Program.cs) in-process against a throwaway COPY of the repo-root demo.sqlite.
// The app reads DEMO_DB once while building the host, so the copy's path is fixed up front and
// ResetData() overwrites that copy from the original before every test. The original is only read.
public sealed class ApiFactory : WebApplicationFactory<Program>
{
    private readonly string _dir;
    private readonly string _sourceDb;

    public string DbPath { get; }

    public ApiFactory()
    {
        _sourceDb = FindRepoDemoDb();
        _dir = Path.Combine(Path.GetTempPath(), "demo-dotnet-tests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(_dir);
        DbPath = Path.Combine(_dir, "demo.sqlite");
        Environment.SetEnvironmentVariable("DEMO_DB", DbPath);
        ResetData();
    }

    // Fresh copy of the real dataset. Tests run one at a time, so no request holds a connection here;
    // clearing the pool closes the app's idle connections to the previous copy first.
    public void ResetData()
    {
        SqliteConnection.ClearAllPools();
        File.Copy(_sourceDb, DbPath, overwrite: true);
    }

    // The repo-root demo.sqlite: walk up from the test binaries to the directory that holds both
    // demo-dotnet/ and demo.sqlite (a stray demo-dotnet/demo.sqlite from a local run is not picked).
    private static string FindRepoDemoDb()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
        {
            var candidate = Path.Combine(dir.FullName, "demo.sqlite");
            if (File.Exists(candidate) && Directory.Exists(Path.Combine(dir.FullName, "demo-dotnet")))
            {
                return candidate;
            }
        }
        throw new FileNotFoundException("demo.sqlite not found above " + AppContext.BaseDirectory);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        SqliteConnection.ClearAllPools();
        try { Directory.Delete(_dir, recursive: true); } catch (IOException) { }
    }
}

[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<ApiFactory>
{
    public const string Name = "api";
}

// Each test gets a fresh class instance; resetting in the constructor gives every test a pristine
// copy of the dataset, so the update test cannot leak into the others.
public abstract class ApiTestBase
{
    protected ApiFactory Factory { get; }
    private readonly HttpClient _client;

    protected ApiTestBase(ApiFactory factory)
    {
        Factory = factory;
        factory.ResetData();
        _client = factory.CreateClient();
    }

    // Sends a request; returns the status code, the raw body and the body parsed as JSON (null if it is not JSON).
    protected async Task<(int Status, string Body, JsonNode? Json)> Send(HttpMethod method, string path, string? jsonBody = null)
    {
        using var request = new HttpRequestMessage(method, path);
        if (jsonBody is not null)
        {
            request.Content = new StringContent(jsonBody, System.Text.Encoding.UTF8, "application/json");
        }
        using var response = await _client.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();
        JsonNode? json = null;
        try { json = JsonNode.Parse(body); } catch (System.Text.Json.JsonException) { }
        return ((int)response.StatusCode, body, json);
    }

    // Whole-document comparison: exact key sets, exact values, exact array order.
    protected static void AssertJsonEquals(string expectedJson, JsonNode? actual)
    {
        var expected = JsonNode.Parse(expectedJson);
        Assert.True(
            JsonNode.DeepEquals(expected, actual),
            $"JSON mismatch.\nExpected: {expected?.ToJsonString()}\nActual:   {actual?.ToJsonString()}");
    }
}
