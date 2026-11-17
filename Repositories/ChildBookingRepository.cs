using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class ChildBookingRepository(IConfiguration configuration)
    : StoredCrudRepository<ChildBooking, ChildBookingCreateDto>(configuration)
{
    protected override string Entity => "child_booking";
}
