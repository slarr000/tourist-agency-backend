using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs;

public sealed class MonthlyReportCloseDto
{
    [Range(2000, 2100)]
    public int Year { get; set; }
    [Range(1, 12)]
    public int Month { get; set; }
    [Range(0, int.MaxValue)]
    [Required]
    public int? ExpectedVersion { get; set; }
    [Required]
    public List<MonthlyReportCatalogItem>? Catalog { get; set; }
    [Required]
    public bool? Confirmed { get; set; }
    [MaxLength(1000)]
    public string? Reason { get; set; }
}

public sealed class MonthlyReportCatalogItem
{
    [Range(1, 999999999)]
    public int PackageId { get; set; }
    [Range(0, 999999999)]
    public int MonthlyCapacity { get; set; }
}
