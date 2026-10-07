using System.Text.Json.Nodes;
using DemoDotnet.Data;
using Microsoft.AspNetCore.Mvc.Testing;
using Npgsql;
using Xunit;

namespace DemoDotnet.Tests;

// Boots the real app (Program.cs) in-process against the PostgreSQL database given by the environment
// (DATABASE_URL / PG*; test.sh hands it a fresh clone of demo_template). The only write any test makes
// is UpdateContent on content 2, so ResetData() restores that row before every test and on dispose.
public sealed class ApiFactory : WebApplicationFactory<Program>
{
    // Content 2's text in demo_template (db/generate.sql).
    private const string OriginalContent2 = "Analysis: NBA #2";

    private readonly string _connectionString = DatabaseSettings.ConnectionString();

    public ApiFactory()
    {
        ResetData();
    }

    public void ResetData()
    {
        using var connection = new NpgsqlConnection(_connectionString);
        connection.Open();
        using var command = new NpgsqlCommand("UPDATE content SET content = @text WHERE id = 2", connection);
        command.Parameters.AddWithValue("text", OriginalContent2);
        command.ExecuteNonQuery();
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        try { ResetData(); } catch (NpgsqlException) { }
    }
}

[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<ApiFactory>
{
    public const string Name = "api";
}

// Each test gets a fresh class instance; resetting in the constructor restores the one row the update
// test writes, so it cannot leak into the others.
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
