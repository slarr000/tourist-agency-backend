namespace TouristAgencyApp.ReportDTOs
{
    public class FlightTouristDetailsDto
    {
        public string FlightNumber { get; set; } = string.Empty;
        public DateTime FlightDate { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public bool HasVisa { get; set; }
        public string? HotelName { get; set; }
        public string? RoomNumber { get; set; }
        public string? CargoType { get; set; }
        public int? PlacesCount { get; set; }
        public decimal? CargoWeight { get; set; }
        public decimal? VolumeWeight { get; set; }
        public string? Tags { get; set; }
        public string? Marking { get; set; }
    }
}