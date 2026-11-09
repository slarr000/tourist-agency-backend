using System.Data;
using System.Text.Json;
using Dapper;
using Microsoft.Extensions.Configuration;
using Npgsql;
using TouristAgencyApp.Auth;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Repositories;

public sealed class EmployeeAuthRepository(IConfiguration configuration) : IEmployeeAuthRepository
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new ArgumentNullException("Connection string is missing");

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public async Task<EmployeeIdentityDto?> AuthenticateAsync(string login, string password)
    {
        using IDbConnection db = new NpgsqlConnection(_connectionString);
        var result = await db.QuerySingleOrDefaultAsync<string>(
            "CALL public.app_authenticate_employee_proc(@Login, @Password, NULL)",
            new { Login = login.Trim(), Password = password });

        return string.IsNullOrWhiteSpace(result)
            ? null
            : JsonSerializer.Deserialize<EmployeeIdentityDto>(result, JsonOptions);
    }
}
