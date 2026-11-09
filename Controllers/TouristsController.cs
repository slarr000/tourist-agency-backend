using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TouristsController : ControllerBase
    {
        private readonly ITouristRepository _touristRepository;

        public TouristsController(ITouristRepository touristRepository)
        {
            _touristRepository = touristRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetTourists()
        {
            return Ok(await _touristRepository.GetAllAsync());
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetTourist(int id)
        {
            var tourist = await _touristRepository.GetByIdAsync(id);
            return tourist is null ? NotFound() : Ok(tourist);
        }

        [HttpPost]
        public async Task<IActionResult> CreateTourist([FromBody] TouristCreateDto dto)
        {
            var id = await _touristRepository.AddAsync(dto);
            var tourist = await _touristRepository.GetByIdAsync(id);

            return CreatedAtAction(nameof(GetTourist), new { id }, tourist);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateTourist(int id, [FromBody] TouristCreateDto dto)
        {
            return await _touristRepository.UpdateAsync(id, dto) ? NoContent() : NotFound();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteTourist(int id)
        {
            return await _touristRepository.DeleteAsync(id) ? NoContent() : NotFound();
        }

    }
}
