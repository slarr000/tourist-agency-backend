using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class AgencyRepository(IConfiguration configuration)
    : StoredCrudRepository<Agency, AgencyCreateDto>(configuration), IAgencyRepository
{
    protected override string Entity => "agency";
}
