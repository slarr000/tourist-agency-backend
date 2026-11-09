namespace TouristAgencyApp.ReportDTOs
{
    public class FamilyTourReportDto
    {
        public string ParentFullName { get; set; } = string.Empty;
        public string ChildName { get; set; } = string.Empty;
        public int ChildAge { get; set; }
        public string FlightNumber { get; set; } = string.Empty;
    }
}