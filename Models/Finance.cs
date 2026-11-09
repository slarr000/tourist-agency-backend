namespace TouristAgencyApp.Models
{
    public class Finance
    {
        public int transaction_id { get; set; }
        public string transaction_type { get; set; } = string.Empty;
        public string category { get; set; } = string.Empty;
        public decimal amount { get; set; }
        public DateTime transaction_date { get; set; }
        public string? description { get; set; }
        public int? flight_id { get; set; }
        public int? tourist_id { get; set; }
    }
}