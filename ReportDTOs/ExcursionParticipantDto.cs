namespace TouristAgencyApp.ReportDTOs;

public class ExcursionParticipantDto
{
    public DateTime ExcursionDate { get; set; }
    public string AgencyName { get; set; } = string.Empty;
    public string ExcursionName { get; set; } = string.Empty;
    public int BookingId { get; set; }
    public string ParticipantType { get; set; } = string.Empty;
    public string ParticipantName { get; set; } = string.Empty;
    public string? GuardianName { get; set; }
}
