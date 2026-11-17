namespace TouristAgencyApp.ReportDTOs;

public class MonthlyBusinessDetailsDto
{
    public MonthlyBusinessReportDto Summary { get; set; } = new();
    public MonthlySaleDto[] Sales { get; set; } = [];
    public MonthlyDocumentDto[] Documents { get; set; } = [];
    public int? Version { get; set; }
    public DateTimeOffset? ClosedAt { get; set; }
    public string? ClosedBy { get; set; }
    public string? Reason { get; set; }
    public MonthlyReportVersionDto[] Versions { get; set; } = [];
    public MonthlyReportCatalogDto[]? Catalog { get; set; }
}

public class MonthlyReportVersionDto
{
    public int Version { get; set; }
    public DateTimeOffset ClosedAt { get; set; }
    public string ClosedBy { get; set; } = string.Empty;
    public string? Reason { get; set; }
}

public class MonthlyReportCatalogDto
{
    public int PackageId { get; set; }
    public string PackageCode { get; set; } = string.Empty;
    public string PackageName { get; set; } = string.Empty;
    public int MonthlyCapacity { get; set; }
}

public class MonthlySaleDto
{
    public int SaleId { get; set; }
    public DateOnly SoldDate { get; set; }
    public string PackageName { get; set; } = string.Empty;
    public string PackageCode { get; set; } = string.Empty;
    public string TouristName { get; set; } = string.Empty;
    public string FlightNumber { get; set; } = string.Empty;
    public DateTime FlightDate { get; set; }
    public decimal? SalePrice { get; set; }
}

public class MonthlyDocumentDto
{
    public int DocumentEventId { get; set; }
    public DateOnly ProcessedDate { get; set; }
    public string DocumentType { get; set; } = string.Empty;
    public string TouristName { get; set; } = string.Empty;
    public string? ChildName { get; set; }
}
