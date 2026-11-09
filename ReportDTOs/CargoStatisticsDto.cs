namespace TouristAgencyApp.ReportDTOs
{
    public class CargoStatisticsDto
    {
        public string CargoType { get; set; } = string.Empty;
        public long TotalPlaces { get; set; }
        public decimal TotalWeight { get; set; }
        public decimal TotalVolumeWeight { get; set; }
        public decimal Percentage { get; set; } // Доля в процентах
    }
}