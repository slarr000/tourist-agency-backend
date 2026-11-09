namespace TouristAgencyApp.ReportDTOs;

public class MonthlyBusinessReportDto
{
    public int Year { get; set; }
    public int Month { get; set; }
    public long SoldVouchers { get; set; }
    public long IssuedPassports { get; set; }
    public long VisasProcessed { get; set; }
    public long ChildDocumentsProcessed { get; set; }
    public long TotalDocuments { get; set; }
    public decimal VoucherRevenue { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal TotalExpenses { get; set; }
    public decimal NetProfit { get; set; }
    public string[] MostDemandedPackages { get; set; } = [];
    public string[] PackagesWithoutSales { get; set; } = [];
}
