using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class FlightRepository(IConfiguration configuration)
    : StoredCrudRepository<Flight, FlightCreateDto>(configuration), IFlightRepository
{
    protected override string Entity => "flight";
}
