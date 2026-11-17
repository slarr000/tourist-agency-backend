namespace TouristAgencyApp.Models;

public class TourPackage
{
    public int package_id { get; set; }
    public string package_code { get; set; } = string.Empty;
    public string package_name { get; set; } = string.Empty;
    public string destination { get; set; } = string.Empty;
    public string category { get; set; } = string.Empty;
    public decimal price { get; set; }
    public int monthly_capacity { get; set; }
    public DateOnly? available_from { get; set; }
    public DateOnly? available_until { get; set; }
    public bool is_active { get; set; }
}
