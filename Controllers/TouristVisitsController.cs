using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TouristVisitsController : ControllerBase
    {
        private readonly ITouristVisitRepository _visitRepository;

        public TouristVisitsController(ITouristVisitRepository visitRepository)
        {
            _visitRepository = visitRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllVisits()
        {
            var visits = await _visitRepository.GetAllAsync();
            return Ok(visits);
        }

        [HttpPost]
        public async Task<IActionResult> CreateVisit([FromBody] TouristVisitCreateDto visitDto)
        {
            if (visitDto.arrival_date > visitDto.departure_date)
            {
                return BadRequest("Дата прилета не может быть позже даты отлета.");
            }

            var newVisitId = await _visitRepository.AddAsync(visitDto);
            return Created($"/api/TouristVisits/{newVisitId}", new { id = newVisitId });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetVisitById(int id)
        {
            var visit = await _visitRepository.GetByIdAsync(id);
            if (visit == null) return NotFound($"Визит с ID {id} не найден.");
            return Ok(visit);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateVisit(int id, [FromBody] TouristVisitCreateDto visitDto)
        {
            if (visitDto.arrival_date > visitDto.departure_date)
            {
                return BadRequest("Дата прилета не может быть позже даты отлета.");
            }

            var updated = await _visitRepository.UpdateAsync(id, visitDto);
            if (!updated) return NotFound($"Визит с ID {id} для обновления не найден.");
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVisit(int id)
        {
            var deleted = await _visitRepository.DeleteAsync(id);
            if (!deleted) return NotFound($"Визит с ID {id} для удаления не найден.");
            return NoContent();
        }
    }
}