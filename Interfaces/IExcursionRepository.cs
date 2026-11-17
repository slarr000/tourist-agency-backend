using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface IExcursionRepository
    {
        Task<IEnumerable<Excursion>> GetAllAsync();
        Task<int> AddAsync(ExcursionCreateDto excursion);

        // Новые методы:
        Task<Excursion?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, ExcursionCreateDto excursion);
        Task<bool> DeleteAsync(int id);
    }
}