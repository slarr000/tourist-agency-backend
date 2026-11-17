using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.Auth;

public sealed class LoginRequestDto
{
    [Required]
    [StringLength(100)]
    public string Login { get; set; } = string.Empty;

    [Required]
    [StringLength(72)]
    public string Password { get; set; } = string.Empty;
}
