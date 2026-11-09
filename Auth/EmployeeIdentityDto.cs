namespace TouristAgencyApp.Auth;

public sealed class EmployeeIdentityDto
{
    public int EmployeeId { get; set; }
    public string Login { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
}
