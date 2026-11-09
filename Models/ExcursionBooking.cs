namespace TouristAgencyApp.Models
{
    public class ExcursionBooking
    {
        public int booking_id { get; set; }
        public int tourist_id { get; set; }
        public int excursion_id { get; set; }
        public int? child_id { get; set; }
    }
}