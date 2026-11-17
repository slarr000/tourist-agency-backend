using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class TouristCargoRepository(IConfiguration configuration)
    : StoredCrudRepository<TouristCargo, TouristCargoCreateDto>(configuration), ITouristCargoRepository
{
    protected override string Entity => "tourist_cargo";
}
