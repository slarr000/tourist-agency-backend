namespace TouristAgencyApp.ReportDTOs;

public class ExcursionAgencyQualityDto
{
    public string AgencyName { get; set; } = string.Empty;
    public decimal QualityRating { get; set; }
    public long QualityRank { get; set; }
    public long ExcursionCount { get; set; }
    public long BookedParticipants { get; set; }
}
