using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ExcursionsController : ControllerBase
    {
        private readonly IExcursionRepository _excursionRepository;

        public ExcursionsController(IExcursionRepository excursionRepository)
        {
            _excursionRepository = excursionRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllExcursions()
        {
            var excursions = await _excursionRepository.GetAllAsync();
            return Ok(excursions);
        }

        [HttpPost]
        public async Task<IActionResult> CreateExcursion([FromBody] ExcursionCreateDto excursionDto)
        {
            if (string.IsNullOrWhiteSpace(excursionDto.excursion_name))
            {
                return BadRequest("Название экскурсии не может быть пустым.");
            }

            var newExcursionId = await _excursionRepository.AddAsync(excursionDto);
            return Created($"/api/Excursions/{newExcursionId}", new { id = newExcursionId });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetExcursionById(int id)
        {
            var excursion = await _excursionRepository.GetByIdAsync(id);
            if (excursion == null)
            {
                return NotFound($"Экскурсия с ID {id} не найдена.");
            }
            return Ok(excursion);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateExcursion(int id, [FromBody] ExcursionCreateDto excursionDto)
        {
            if (string.IsNullOrWhiteSpace(excursionDto.excursion_name))
            {
                return BadRequest("Название экскурсии не может быть пустым.");
            }

            var updated = await _excursionRepository.UpdateAsync(id, excursionDto);
            if (!updated)
            {
                return NotFound($"Экскурсия с ID {id} для обновления не найдена.");
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteExcursion(int id)
        {
            var deleted = await _excursionRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound($"Экскурсия с ID {id} для удаления не найдена.");
            }

            return NoContent();
        }
    }
}