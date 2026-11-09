namespace TouristAgencyApp.Models
{
    public class TouristCargo
    {
        public int cargo_id { get; set; }
        public int tourist_id { get; set; }
        public string cargo_type { get; set; } = string.Empty;
        public int places_count { get; set; }
        public decimal actual_weight { get; set; }
        public decimal volume_weight { get; set; }
        public string marking { get; set; } = string.Empty;
        public string tags { get; set; } = string.Empty;
        public decimal packaging_cost { get; set; }
        public decimal insurance_cost { get; set; }
        public decimal total_amount { get; set; }
        public int flight_id { get; set; }
        public string status { get; set; } = "Принят на склад";
    }
}