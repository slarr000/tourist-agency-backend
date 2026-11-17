namespace TouristAgencyApp.ReportDTOs
{
    public class TouristCountDto
    {
        public int TotalTourists { get; set; }
        public int AdultCount { get; set; }
        public int ChildrenCount { get; set; }
        public string? Category { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
}