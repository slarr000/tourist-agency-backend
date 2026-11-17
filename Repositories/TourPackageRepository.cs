using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class TourPackageRepository(IConfiguration configuration)
    : StoredCrudRepository<TourPackage, TourPackageCreateDto>(configuration)
{
    protected override string Entity => "tour_package";
}
