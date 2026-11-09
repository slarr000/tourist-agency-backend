namespace TouristAgencyApp.ReportDTOs
{
    public class FinancialSummaryDto
    {
        public decimal TotalIncome { get; set; }
        public decimal TotalExpense { get; set; }
        public decimal NetProfit { get; set; }
        public decimal? ProfitabilityPercent { get; set; }
    }


}