using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TouristCargoController : ControllerBase
    {
        private readonly ITouristCargoRepository _cargoRepository;

        public TouristCargoController(ITouristCargoRepository cargoRepository)
        {
            _cargoRepository = cargoRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllCargo()
        {
            var cargo = await _cargoRepository.GetAllAsync();
            return Ok(cargo);
        }

        [HttpPost]
        public async Task<IActionResult> CreateCargo([FromBody] TouristCargoCreateDto cargoDto)
        {
            var newCargoId = await _cargoRepository.AddAsync(cargoDto);
            return Created($"/api/TouristCargo/{newCargoId}", new { id = newCargoId });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetCargoById(int id)
        {
            var cargo = await _cargoRepository.GetByIdAsync(id);
            if (cargo == null)
            {
                return NotFound($"Груз с ID {id} не найден.");
            }
            return Ok(cargo);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateCargo(int id, [FromBody] TouristCargoCreateDto cargoDto)
        {
            var updated = await _cargoRepository.UpdateAsync(id, cargoDto);
            if (!updated)
            {
                return NotFound($"Груз с ID {id} для обновления не найден.");
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCargo(int id)
        {
            var deleted = await _cargoRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound($"Груз с ID {id} для удаления не найден.");
            }

            return NoContent();
        }
    }
}