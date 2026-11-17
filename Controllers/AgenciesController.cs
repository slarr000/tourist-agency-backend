using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AgenciesController : ControllerBase
    {
        private readonly IAgencyRepository _agencyRepository;

        public AgenciesController(IAgencyRepository agencyRepository)
        {
            _agencyRepository = agencyRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllAgencies()
        {
            var agencies = await _agencyRepository.GetAllAsync();
            return Ok(agencies);
        }

        [HttpPost]
        public async Task<IActionResult> CreateAgency([FromBody] AgencyCreateDto agencyDto)
        {
            if (string.IsNullOrWhiteSpace(agencyDto.agency_name))
            {
                return BadRequest("Название агентства не может быть пустым.");
            }

            var newAgencyId = await _agencyRepository.AddAsync(agencyDto);
            return Created($"/api/Agencies/{newAgencyId}", new { id = newAgencyId });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetAgencyById(int id)
        {
            var agency = await _agencyRepository.GetByIdAsync(id);
            if (agency == null)
            {
                return NotFound($"Агентство с ID {id} не найдено.");
            }
            return Ok(agency);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateAgency(int id, [FromBody] AgencyCreateDto agencyDto)
        {
            if (string.IsNullOrWhiteSpace(agencyDto.agency_name))
            {
                return BadRequest("Название агентства не может быть пустым.");
            }

            var updated = await _agencyRepository.UpdateAsync(id, agencyDto);
            if (!updated)
            {
                return NotFound($"Агентство с ID {id} для обновления не найдено.");
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAgency(int id)
        {
            var deleted = await _agencyRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound($"Агентство с ID {id} для удаления не найдено.");
            }

            return NoContent();
        }
    }
}