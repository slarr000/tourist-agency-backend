namespace TouristAgencyApp.ReportDTOs
{
    public class VisaStatusReportDto
    {
        public string FullName { get; set; } = string.Empty;
        public string FlightNumber { get; set; } = string.Empty;
        public DateTime FlightDate { get; set; }
        public bool HasVisa { get; set; }
    }
}
