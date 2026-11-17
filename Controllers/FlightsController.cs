using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FlightsController : ControllerBase
    {
        private readonly IFlightRepository _flightRepository;

        public FlightsController(IFlightRepository flightRepository)
        {
            _flightRepository = flightRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllFlights()
        {
            var flights = await _flightRepository.GetAllAsync();
            return Ok(flights);
        }

        [HttpPost]
        public async Task<IActionResult> CreateFlight([FromBody] FlightCreateDto flightDto)
        {
            if (string.IsNullOrWhiteSpace(flightDto.flight_number))
            {
                return BadRequest("Номер рейса не может быть пустым.");
            }

            var newFlightId = await _flightRepository.AddAsync(flightDto);

            return Created($"/api/Flights/{newFlightId}", new { id = newFlightId });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetFlightById(int id)
        {
            var flight = await _flightRepository.GetByIdAsync(id);
            if (flight == null)
            {
                return NotFound($"Рейс с ID {id} не найден.");
            }
            return Ok(flight);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateFlight(int id, [FromBody] FlightCreateDto flightDto)
        {
            if (string.IsNullOrWhiteSpace(flightDto.flight_number))
            {
                return BadRequest("Номер рейса не может быть пустым.");
            }

            var updated = await _flightRepository.UpdateAsync(id, flightDto);
            if (!updated)
            {
                return NotFound($"Рейс с ID {id} для обновления не найден.");
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteFlight(int id)
        {
            var deleted = await _flightRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound($"Рейс с ID {id} для удаления не найден.");
            }

            return NoContent();
        }
    }
}