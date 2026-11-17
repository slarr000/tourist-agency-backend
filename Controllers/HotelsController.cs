using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HotelsController : ControllerBase
    {
        private readonly IHotelRepository _hotelRepository;

        public HotelsController(IHotelRepository hotelRepository)
        {
            _hotelRepository = hotelRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetHotels([FromQuery] HotelQueryParameters parameters)
        {
            if (parameters.PageNumber < 1) parameters.PageNumber = 1;
            if (parameters.PageSize < 1) parameters.PageSize = 10;
            if (parameters.PageSize > 50) parameters.PageSize = 50;

            var hotels = await _hotelRepository.GetPagedAndFilteredAsync(parameters);
            return Ok(hotels);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetHotelById(int id)
        {
            var hotel = await _hotelRepository.GetByIdAsync(id);
            if (hotel == null)
            {
                return NotFound($"Гостиница с ID {id} не найдена.");
            }
            return Ok(hotel);
        }

        [HttpPost]
        public async Task<IActionResult> CreateHotel([FromBody] HotelCreateDto hotelDto)
        {
            var newHotelId = await _hotelRepository.AddAsync(hotelDto);
            return Created($"/api/Hotels/{newHotelId}", new { id = newHotelId });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateHotel(int id, [FromBody] HotelCreateDto hotelDto)
        {
            var updated = await _hotelRepository.UpdateAsync(id, hotelDto);
            if (!updated)
            {
                return NotFound($"Гостиница с ID {id} для обновления не найдена.");
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteHotel(int id)
        {
            var deleted = await _hotelRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound($"Гостиница с ID {id} для удаления не найдена.");
            }

            return NoContent();
        }
    }
}