namespace TouristAgencyApp.ReportDTOs
{
    public class HotelOccupancyDto
    {
        public string HotelName { get; set; } = string.Empty;
        public string Country { get; set; } = string.Empty;
        public long OccupiedRooms { get; set; }
        public long ResidentTourists { get; set; }
        public long ResidentChildren { get; set; }
        public long TotalResidents { get; set; }
    }
}
