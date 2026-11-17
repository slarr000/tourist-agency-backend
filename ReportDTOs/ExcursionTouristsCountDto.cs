namespace TouristAgencyApp.ReportDTOs
{
    public class ExcursionTouristsCountDto
    {
        public long TotalTourists { get; set; }
        public long AdultTourists { get; set; }
        public long Children { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}