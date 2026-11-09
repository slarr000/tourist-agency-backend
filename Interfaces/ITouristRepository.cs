using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface ITouristRepository
    {
        Task<IEnumerable<Tourist>> GetAllAsync();
        Task<int> AddAsync(TouristCreateDto tourist);

        Task<Tourist?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, TouristCreateDto tourist);
        Task<bool> DeleteAsync(int id);
    }
}