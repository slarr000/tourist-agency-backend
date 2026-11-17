using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class FinanceRepository(IConfiguration configuration)
    : StoredCrudRepository<Finance, FinanceCreateDto>(configuration), IFinanceRepository
{
    protected override string Entity => "finance";
}
