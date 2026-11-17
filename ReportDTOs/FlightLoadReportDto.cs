namespace TouristAgencyApp.ReportDTOs
{
    public class FlightLoadReportDto
    {
        public int FlightId { get; set; }
        public string FlightNumber { get; set; } = string.Empty;
        public DateTime FlightDate { get; set; }
        public string FlightType { get; set; } = string.Empty;
        public int SeatCapacity { get; set; }
        public long PassengerCount { get; set; }
        public long AvailableSeats { get; set; }
        public long CargoPlaces { get; set; }
        public decimal ActualWeight { get; set; }
        public decimal VolumeWeight { get; set; }
    }
}