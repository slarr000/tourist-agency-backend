using System.Data;
using Microsoft.Extensions.Configuration;
using Npgsql;

namespace TouristAgencyApp.Repositories;

public abstract class StoredCrudRepository<TModel, TCreate>
    where TModel : class
    where TCreate : class
{
    private readonly string _connectionString;

    protected StoredCrudRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new ArgumentNullException("Connection string is missing");
    }

    protected abstract string Entity { get; }

    protected IDbConnection CreateConnection() => new NpgsqlConnection(_connectionString);

    public async Task<IEnumerable<TModel>> GetAllAsync()
    {
        using var db = CreateConnection();
        return await StoredProcedureDataAccess.GetAllAsync<TModel>(db, Entity);
    }

    public async Task<int> AddAsync(TCreate value)
    {
        using var db = CreateConnection();
        return await StoredProcedureDataAccess.CreateAsync(db, Entity, value);
    }

    public async Task<TModel?> GetByIdAsync(int id)
    {
        using var db = CreateConnection();
        return await StoredProcedureDataAccess.GetByIdAsync<TModel>(db, Entity, id);
    }

    public async Task<bool> UpdateAsync(int id, TCreate value)
    {
        using var db = CreateConnection();
        return await StoredProcedureDataAccess.UpdateAsync(db, Entity, id, value);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        using var db = CreateConnection();
        return await StoredProcedureDataAccess.DeleteAsync(db, Entity, id);
    }
}
