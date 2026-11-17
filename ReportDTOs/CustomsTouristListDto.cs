namespace TouristAgencyApp.ReportDTOs
{
    public class CustomsTouristListDto
    {
        public string FullName { get; set; } = string.Empty;
        public string ParticipantType { get; set; } = string.Empty;
        public string? GuardianName { get; set; }
        public string? PassportNumber { get; set; }
        public string? BirthCertificateNumber { get; set; }
        public string FlightNumber { get; set; } = string.Empty;
        public int FlightId { get; set; }
        public DateTime FlightDate { get; set; }
        public string Category { get; set; } = string.Empty;
    }
}