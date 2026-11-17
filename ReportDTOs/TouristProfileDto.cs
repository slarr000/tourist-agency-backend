namespace TouristAgencyApp.ReportDTOs
{
    public class TouristProfileDto
    {
        public string FullName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string? PassportNumber { get; set; }
        public bool HasVisa { get; set; }
        public long TotalVisits { get; set; }
        public string[] VisitHistory { get; set; } = [];
        public string[] HotelHistory { get; set; } = [];
        public string[] ExcursionHistory { get; set; } = [];
        public string[] CargoHistory { get; set; } = [];
    }
}