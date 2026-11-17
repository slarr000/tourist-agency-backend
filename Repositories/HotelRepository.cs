using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class HotelRepository(IConfiguration configuration)
    : StoredCrudRepository<Hotel, HotelCreateDto>(configuration), IHotelRepository
{
    protected override string Entity => "hotel";

    public async Task<IEnumerable<Hotel>> GetPagedAndFilteredAsync(HotelQueryParameters parameters)
    {
        using var db = CreateConnection();
        return await StoredProcedureDataAccess.GetHotelsAsync<Hotel>(
            db,
            parameters.SearchTerm,
            parameters.MinStars,
            parameters.MaxPrice,
            parameters.PageNumber,
            parameters.PageSize);
    }
}
