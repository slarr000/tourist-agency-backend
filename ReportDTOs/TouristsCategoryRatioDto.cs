namespace TouristAgencyApp.ReportDTOs
{
    public class TouristsCategoryRatioDto
    {
        public int HolidayCount { get; set; }
        public int ShopTourCount { get; set; }
        public int TotalTourists { get; set; }
        public decimal HolidayPercentage { get; set; }
        public decimal ShopTourPercentage { get; set; }
    }
}