using System.Data;
using System.Text.Json;
using Dapper;

namespace TouristAgencyApp.Repositories;

internal static class StoredProcedureDataAccess
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower
    };

    public static async Task<IEnumerable<T>> GetAllAsync<T>(IDbConnection db, string entity)
    {
        var records = await db.QuerySingleAsync<string>(
            "CALL public.app_get_all_proc(@Entity, NULL)",
            new { Entity = entity });

        return DeserializeList<T>(records);
    }

    public static async Task<T?> GetByIdAsync<T>(IDbConnection db, string entity, int id)
    {
        var record = await db.QueryFirstOrDefaultAsync<string>(
            "CALL public.app_get_by_id_proc(@Entity, @Id, NULL)",
            new { Entity = entity, Id = id });

        return record is null ? default : Deserialize<T>(record);
    }

    public static async Task<int> CreateAsync(IDbConnection db, string entity, object data)
    {
        return await db.QuerySingleAsync<int>(
            "CALL public.app_create_proc(@Entity, CAST(@Data AS jsonb), NULL)",
            new { Entity = entity, Data = Serialize(data) });
    }

    public static async Task<bool> UpdateAsync(IDbConnection db, string entity, int id, object data)
    {
        return await db.QuerySingleAsync<bool>(
            "CALL public.app_update_proc(@Entity, @Id, CAST(@Data AS jsonb), NULL)",
            new { Entity = entity, Id = id, Data = Serialize(data) });
    }

    public static async Task<bool> DeleteAsync(IDbConnection db, string entity, int id)
    {
        return await db.QuerySingleAsync<bool>(
            "CALL public.app_delete_proc(@Entity, @Id, NULL)",
            new { Entity = entity, Id = id });
    }

    public static async Task<IEnumerable<T>> GetHotelsAsync<T>(
        IDbConnection db,
        string? searchTerm,
        int? minStars,
        decimal? maxPrice,
        int pageNumber,
        int pageSize)
    {
        var records = await db.QuerySingleAsync<string>(
            """
            CALL public.app_get_hotels_proc(
                @SearchTerm, @MinStars, @MaxPrice, @PageSize, @PageNumber, NULL)
            """,
            new
            {
                SearchTerm = searchTerm,
                MinStars = minStars,
                MaxPrice = maxPrice,
                PageSize = pageSize,
                PageNumber = pageNumber
            });

        return DeserializeList<T>(records);
    }

    public static async Task<T> CallJsonProcedureAsync<T>(
        IDbConnection db,
        string reportKey,
        object parameters)
    {
        var result = await db.QuerySingleAsync<string>(
            "CALL public.coursework_run_report(@ReportKey, CAST(@Parameters AS jsonb), NULL)",
            new
            {
                ReportKey = reportKey,
                Parameters = Serialize(parameters)
            });

        return Deserialize<T>(result);
    }

    public static async Task<T?> CallJsonProcedureNullableAsync<T>(
        IDbConnection db,
        string reportKey,
        object parameters)
    {
        var result = await db.QuerySingleAsync<string>(
            "CALL public.coursework_run_report(@ReportKey, CAST(@Parameters AS jsonb), NULL)",
            new
            {
                ReportKey = reportKey,
                Parameters = Serialize(parameters)
            });

        return JsonSerializer.Deserialize<T>(result, JsonOptions);
    }

    public static T[] DeserializeList<T>(string value)
    {
        return JsonSerializer.Deserialize<T[]>(value, JsonOptions)
            ?? throw new InvalidOperationException($"Database returned JSON null for {typeof(T).Name} list.");
    }

    public static string Serialize(object value)
    {
        return JsonSerializer.Serialize(value, JsonOptions);
    }

    public static T Deserialize<T>(string value)
    {
        return JsonSerializer.Deserialize<T>(value, JsonOptions)
            ?? throw new InvalidOperationException($"Database returned JSON null for {typeof(T).Name}.");
    }
}
