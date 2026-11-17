using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface ITouristChildRepository
    {
        Task<IEnumerable<TouristChild>> GetAllAsync();
        Task<int> AddAsync(TouristChildCreateDto child);

        // Новые методы:
        Task<TouristChild?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, TouristChildCreateDto child);
        Task<bool> DeleteAsync(int id);
    }
}