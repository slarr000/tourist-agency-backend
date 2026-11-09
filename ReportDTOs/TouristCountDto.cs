namespace TouristAgencyApp.ReportDTOs
{
    public class TouristCountDto
    {
        public int TotalTourists { get; set; }
        public string? Category { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
}