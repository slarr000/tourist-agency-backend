using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface IFinanceRepository
    {
        Task<IEnumerable<Finance>> GetAllAsync();
        Task<int> AddAsync(FinanceCreateDto finance);
        Task<Finance?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, FinanceCreateDto finance);
        Task<bool> DeleteAsync(int id);
    }
}