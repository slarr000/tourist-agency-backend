namespace TouristAgencyApp.Models
{
    public class Booking
    {
        public int booking_id { get; set; }
        public int tourist_id { get; set; }
        public int? visit_id { get; set; }
        public int hotel_id { get; set; }
        public DateTime check_in_date { get; set; }
        public DateTime check_out_date { get; set; }
        public string room_number { get; set; } = string.Empty;
    }
}