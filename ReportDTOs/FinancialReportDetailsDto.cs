namespace TouristAgencyApp.ReportDTOs;

public class FinancialReportDetailsDto
{
    public FinancialSummaryDto Summary { get; set; } = new();
    public FinancialItemDto[] Items { get; set; } = [];
}
