using Microsoft.Extensions.Configuration;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class BookingRepository(IConfiguration configuration)
    : StoredCrudRepository<Booking, BookingCreateDto>(configuration), IBookingRepository
{
    protected override string Entity => "booking";
}
