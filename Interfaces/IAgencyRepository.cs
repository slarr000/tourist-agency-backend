using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface IAgencyRepository
    {
        Task<IEnumerable<Agency>> GetAllAsync();
        Task<int> AddAsync(AgencyCreateDto agency);

        Task<Agency?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, AgencyCreateDto agency);
        Task<bool> DeleteAsync(int id);
    }
}