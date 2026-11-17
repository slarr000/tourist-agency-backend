using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ExcursionBookingsController : ControllerBase
    {
        private readonly IExcursionBookingRepository _bookingRepository;

        public ExcursionBookingsController(IExcursionBookingRepository bookingRepository)
        {
            _bookingRepository = bookingRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllBookings()
        {
            var bookings = await _bookingRepository.GetAllAsync();
            return Ok(bookings);
        }

        [HttpPost]
        public async Task<IActionResult> CreateBooking([FromBody] ExcursionBookingCreateDto bookingDto)
        {
            var newBookingId = await _bookingRepository.AddAsync(bookingDto);
            return Created($"/api/ExcursionBookings/{newBookingId}", new { id = newBookingId });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetBookingById(int id)
        {
            var booking = await _bookingRepository.GetByIdAsync(id);
            if (booking == null)
            {
                return NotFound($"Бронирование с ID {id} не найдено.");
            }
            return Ok(booking);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateBooking(int id, [FromBody] ExcursionBookingCreateDto bookingDto)
        {
            var updated = await _bookingRepository.UpdateAsync(id, bookingDto);
            if (!updated)
            {
                return NotFound($"Бронирование с ID {id} для обновления не найдено.");
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteBooking(int id)
        {
            var deleted = await _bookingRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound($"Бронирование с ID {id} для удаления не найдено.");
            }

            return NoContent();
        }
    }
}