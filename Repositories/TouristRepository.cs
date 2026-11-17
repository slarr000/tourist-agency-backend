using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class TouristRepository(IConfiguration configuration)
    : StoredCrudRepository<Tourist, TouristCreateDto>(configuration), ITouristRepository
{
    protected override string Entity => "tourist";
}
