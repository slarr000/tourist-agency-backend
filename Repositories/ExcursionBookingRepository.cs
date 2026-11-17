using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class ExcursionBookingRepository(IConfiguration configuration)
    : StoredCrudRepository<ExcursionBooking, ExcursionBookingCreateDto>(configuration), IExcursionBookingRepository
{
    protected override string Entity => "excursion_booking";
}
