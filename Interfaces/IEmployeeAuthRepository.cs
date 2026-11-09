using TouristAgencyApp.Auth;

namespace TouristAgencyApp.Interfaces;

public interface IEmployeeAuthRepository
{
    Task<EmployeeIdentityDto?> AuthenticateAsync(string login, string password);
}
