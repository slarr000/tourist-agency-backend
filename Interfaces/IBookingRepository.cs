using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface IBookingRepository
    {
        Task<IEnumerable<Booking>> GetAllAsync();
        Task<int> AddAsync(BookingCreateDto booking);

        // Новые методы:
        Task<Booking?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, BookingCreateDto booking);
        Task<bool> DeleteAsync(int id);
    }
}