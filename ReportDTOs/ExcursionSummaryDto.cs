namespace TouristAgencyApp.ReportDTOs
{
    public class ExcursionSummaryDto
    {
        public string ExcursionName { get; set; } = string.Empty;
        public string AgencyName { get; set; } = string.Empty;
        public decimal AgencyQuality { get; set; }
        public DateTime ScheduleDate { get; set; }
        public decimal Price { get; set; }
        public long TotalTourists { get; set; }
        public long AdultTourists { get; set; }
        public long Children { get; set; }
    }
}