namespace TouristAgencyApp.Models
{
    public class Excursion
    {
        public int excursion_id { get; set; }
        public int agency_id { get; set; }
        public string excursion_name { get; set; } = string.Empty;
        public DateTime schedule_date { get; set; }
        public decimal price { get; set; }
    }
}