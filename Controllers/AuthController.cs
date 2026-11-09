using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.Auth;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController(IEmployeeAuthRepository employeeAuthRepository) : ControllerBase
{
    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
    {
        if (Encoding.UTF8.GetByteCount(request.Password) > 72)
        {
            return BadRequest(new { message = "Пароль не должен превышать 72 байта в UTF-8." });
        }

        var employee = await employeeAuthRepository.AuthenticateAsync(request.Login, request.Password);
        if (employee is null)
        {
            return Unauthorized(new { message = "Неверный логин или пароль." });
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, employee.EmployeeId.ToString()),
            new Claim(ClaimTypes.Name, employee.Login),
            new Claim(ClaimTypes.Role, employee.Role),
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity),
            new AuthenticationProperties
            {
                IsPersistent = false,
                AllowRefresh = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8),
            });

        return Ok(employee);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("me")]
    public IActionResult GetCurrentEmployee()
    {
        return Ok(new
        {
            employeeId = User.FindFirstValue(ClaimTypes.NameIdentifier),
            login = User.Identity?.Name,
            role = User.FindFirstValue(ClaimTypes.Role),
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return NoContent();
    }
}
