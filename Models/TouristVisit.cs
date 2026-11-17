namespace TouristAgencyApp.Models
{
    public class TouristVisit
    {
        public int visit_id { get; set; }
        public int tourist_id { get; set; }
        public int flight_id { get; set; }
        public DateTime arrival_date { get; set; }
        public DateTime departure_date { get; set; }
    }
}