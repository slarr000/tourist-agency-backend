using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class PassportRepository(IConfiguration configuration)
    : StoredCrudRepository<Passport, PassportCreateDto>(configuration), IPassportRepository
{
    protected override string Entity => "passport";
}
