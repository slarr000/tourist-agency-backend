using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PassportsController : ControllerBase
    {
        private readonly IPassportRepository _passportRepository;

        public PassportsController(IPassportRepository passportRepository)
        {
            _passportRepository = passportRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllPassports()
        {
            var passports = await _passportRepository.GetAllAsync();
            return Ok(passports);
        }

        [HttpPost]
        public async Task<IActionResult> CreatePassport([FromBody] PassportCreateDto passportDto)
        {
            var newPassportId = await _passportRepository.AddAsync(passportDto);
            return Created($"/api/Passports/{newPassportId}", new { id = newPassportId });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetPassportById(int id)
        {
            var passport = await _passportRepository.GetByIdAsync(id);
            if (passport == null)
            {
                return NotFound($"Паспорт с ID {id} не найден.");
            }
            return Ok(passport);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdatePassport(int id, [FromBody] PassportCreateDto passportDto)
        {
            var updated = await _passportRepository.UpdateAsync(id, passportDto);
            if (!updated)
            {
                return NotFound($"Паспорт с ID {id} для обновления не найден.");
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePassport(int id)
        {
            var deleted = await _passportRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound($"Паспорт с ID {id} для удаления не найден.");
            }

            return NoContent();
        }
    }
}