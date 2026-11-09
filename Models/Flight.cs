namespace TouristAgencyApp.Models
{
    public class Flight
    {
        public int flight_id { get; set; }
        public string flight_number { get; set; } = string.Empty;
        public DateTime flight_date { get; set; }
        public string aircraft_type { get; set; } = string.Empty;

        // НОВОЕ ПОЛЕ: Тип рейса (Грузовой / Пассажирский)
        public string flight_type { get; set; } = string.Empty;
        public int seat_capacity { get; set; }
    }
}