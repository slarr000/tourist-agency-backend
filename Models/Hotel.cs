namespace TouristAgencyApp.Models
{
    public class Hotel
    {
        public int hotel_id { get; set; }
        public string hotel_name { get; set; } = string.Empty;
        public int stars_count { get; set; }
        public string address { get; set; } = string.Empty;
        public decimal price_per_night { get; set; }
    }
}