using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BookingsController : ControllerBase
    {
        private readonly IBookingRepository _bookingRepository;

        public BookingsController(IBookingRepository bookingRepository)
        {
            _bookingRepository = bookingRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllBookings()
        {
            var bookings = await _bookingRepository.GetAllAsync();
            return Ok(bookings);
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

        [HttpPost]
        public async Task<IActionResult> CreateBooking([FromBody] BookingCreateDto bookingDto)
        {
            // Здесь можно добавить базовую валидацию дат, если необходимо
            if (bookingDto.check_in_date > bookingDto.check_out_date)
            {
                return BadRequest("Дата заезда не может быть позже даты выезда.");
            }

            var newBookingId = await _bookingRepository.AddAsync(bookingDto);
            return Created($"/api/Bookings/{newBookingId}", new { id = newBookingId });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateBooking(int id, [FromBody] BookingCreateDto bookingDto)
        {
            if (bookingDto.check_in_date > bookingDto.check_out_date)
            {
                return BadRequest("Дата заезда не может быть позже даты выезда.");
            }

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