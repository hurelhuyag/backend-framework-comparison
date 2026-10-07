using Npgsql;

namespace DemoDotnet.Data;

// Builds the Npgsql connection string from the environment: DATABASE_URL
// (postgres://user:pass@host:port/db) when set, otherwise the libpq PG* variables.
// The connection pool is capped at DB_POOL_SIZE (default 32); other pool knobs stay at Npgsql defaults.
public static class DatabaseSettings
{
    public static string ConnectionString()
    {
        var builder = new NpgsqlConnectionStringBuilder
        {
            Host = Env("PGHOST", "127.0.0.1"),
            Port = int.Parse(Env("PGPORT", "5432")),
            Username = Env("PGUSER", "bench"),
            Password = Env("PGPASSWORD", "bench"),
            Database = Env("PGDATABASE", "demo"),
        };

        var url = Environment.GetEnvironmentVariable("DATABASE_URL");
        if (!string.IsNullOrEmpty(url))
        {
            var uri = new Uri(url);
            builder.Host = uri.Host;
            if (uri.Port > 0) builder.Port = uri.Port;
            var userInfo = uri.UserInfo.Split(':', 2);
            if (userInfo[0].Length > 0) builder.Username = Uri.UnescapeDataString(userInfo[0]);
            if (userInfo.Length > 1) builder.Password = Uri.UnescapeDataString(userInfo[1]);
            var database = uri.AbsolutePath.TrimStart('/');
            if (database.Length > 0) builder.Database = Uri.UnescapeDataString(database);
        }

        builder.MaxPoolSize = int.Parse(Env("DB_POOL_SIZE", "32"));
        // Npgsql 10 defaults to GSS Encryption Mode=Prefer and probes for libgssapi_krb5, which the
        // aspnet image lacks (harmless "Cannot load library" error on every new connection). The server
        // does not offer GSS encryption, so disabling the probe changes nothing but the log noise.
        builder.GssEncryptionMode = GssEncryptionMode.Disable;
        return builder.ConnectionString;
    }

    private static string Env(string name, string fallback) =>
        Environment.GetEnvironmentVariable(name) is { Length: > 0 } value ? value : fallback;
}
