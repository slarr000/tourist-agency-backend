using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface ITouristVisitRepository
    {
        Task<IEnumerable<TouristVisit>> GetAllAsync();
        Task<int> AddAsync(TouristVisitCreateDto visit);
        Task<TouristVisit?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, TouristVisitCreateDto visit);
        Task<bool> DeleteAsync(int id);
    }
}