namespace TouristAgencyApp.ReportDTOs;

public class FinancialItemDto
{
    public string TransactionType { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public long TransactionCount { get; set; }
    public decimal Amount { get; set; }
}
