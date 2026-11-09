namespace TouristAgencyApp.ReportDTOs
{
    public class PassportControlDto
    {
        public string FullName { get; set; } = string.Empty;
        public string PassportNumber { get; set; } = string.Empty;
        public DateTime ExpirationDate { get; set; }
        public int DaysUntilExpiration { get; set; }
    }
}