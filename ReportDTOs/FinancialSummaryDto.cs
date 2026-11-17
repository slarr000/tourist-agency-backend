namespace TouristAgencyApp.ReportDTOs
{
    public class FinancialSummaryDto
    {
        public decimal TotalIncome { get; set; }
        public decimal TotalExpense { get; set; }
        public decimal NetProfit { get; set; }
        public decimal? ProfitabilityPercent { get; set; }
        public decimal UnallocatedIncome { get; set; }
        public decimal UnallocatedExpense { get; set; }
        public long UnallocatedOperationCount { get; set; }
    }


}