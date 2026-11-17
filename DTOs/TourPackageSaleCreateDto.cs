using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs;

public class TourPackageSaleCreateDto
{
    [Range(1, int.MaxValue)]
    public int package_id { get; set; }
    [Range(1, int.MaxValue)]
    public int tourist_id { get; set; }
    [Range(1, int.MaxValue)]
    public int flight_id { get; set; }
    [Required]
    public DateOnly? sold_date { get; set; }
    [Required, Range(typeof(decimal), "0", "9999999999.99", ParseLimitsInInvariantCulture = true)]
    public decimal? sale_price { get; set; }
}
