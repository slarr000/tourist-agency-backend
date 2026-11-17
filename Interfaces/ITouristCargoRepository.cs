using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface ITouristCargoRepository
    {
        Task<IEnumerable<TouristCargo>> GetAllAsync();
        Task<int> AddAsync(TouristCargoCreateDto cargo);

        // Новые методы:
        Task<TouristCargo?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, TouristCargoCreateDto cargo);
        Task<bool> DeleteAsync(int id);
    }
}