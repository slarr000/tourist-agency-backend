namespace TouristAgencyApp.ReportDTOs
{
    public class CargoSummaryReportDto
    {
        public string FlightNumber { get; set; } = string.Empty;
        public int TotalPlaces { get; set; }
        public decimal TotalActualWeight { get; set; }
        public decimal TotalInsuranceCost { get; set; }
    }

 
}