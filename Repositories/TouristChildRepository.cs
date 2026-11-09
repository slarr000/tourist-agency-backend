using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class TouristChildRepository(IConfiguration configuration)
    : StoredCrudRepository<TouristChild, TouristChildCreateDto>(configuration), ITouristChildRepository
{
    protected override string Entity => "tourist_child";
}
