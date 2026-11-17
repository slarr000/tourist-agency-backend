using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class TourPackageSaleRepository(IConfiguration configuration)
    : StoredCrudRepository<TourPackageSale, TourPackageSaleCreateDto>(configuration)
{
    protected override string Entity => "tour_package_sale";
}
