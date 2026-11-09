using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class ExcursionRepository(IConfiguration configuration)
    : StoredCrudRepository<Excursion, ExcursionCreateDto>(configuration), IExcursionRepository
{
    protected override string Entity => "excursion";
}
