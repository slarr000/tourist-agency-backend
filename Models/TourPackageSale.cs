namespace TouristAgencyApp.Models;

public class TourPackageSale
{
    public int sale_id { get; set; }
    public int package_id { get; set; }
    public int tourist_id { get; set; }
    public int flight_id { get; set; }
    public DateOnly sold_date { get; set; }
    public decimal? sale_price { get; set; }
}
