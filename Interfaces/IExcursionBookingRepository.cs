using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface IExcursionBookingRepository
    {
        Task<IEnumerable<ExcursionBooking>> GetAllAsync();
        Task<int> AddAsync(ExcursionBookingCreateDto booking);

        // Новые методы:
        Task<ExcursionBooking?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, ExcursionBookingCreateDto booking);
        Task<bool> DeleteAsync(int id);
    }
}