using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface IPassportRepository
    {
        Task<IEnumerable<Passport>> GetAllAsync();
        Task<int> AddAsync(PassportCreateDto passport);

        // Новые методы:
        Task<Passport?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, PassportCreateDto passport);
        Task<bool> DeleteAsync(int id);
    }
}