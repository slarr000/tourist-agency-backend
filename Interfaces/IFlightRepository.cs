using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface IFlightRepository
    {
        Task<IEnumerable<Flight>> GetAllAsync();
        Task<int> AddAsync(FlightCreateDto flight);

        // Новые методы:
        Task<Flight?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, FlightCreateDto flight);
        Task<bool> DeleteAsync(int id);
    }
}