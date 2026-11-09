using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class TouristVisitRepository(IConfiguration configuration)
    : StoredCrudRepository<TouristVisit, TouristVisitCreateDto>(configuration), ITouristVisitRepository
{
    protected override string Entity => "tourist_visit";
}
