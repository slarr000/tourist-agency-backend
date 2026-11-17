namespace TouristAgencyApp.Models
{
    public class Agency
    {
        public int agency_id { get; set; }
        public string agency_name { get; set; } = string.Empty;
        public decimal quality_rating { get; set; }
    }
}