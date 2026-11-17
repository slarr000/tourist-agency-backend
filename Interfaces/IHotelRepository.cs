using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Interfaces
{
    public interface IHotelRepository
    {
        Task<IEnumerable<Hotel>> GetAllAsync();
        Task<int> AddAsync(HotelCreateDto hotel);
        Task<Hotel?> GetByIdAsync(int id);
        Task<bool> UpdateAsync(int id, HotelCreateDto hotel);
        Task<bool> DeleteAsync(int id);

        // Новый метод с пагинацией и фильтрацией
        Task<IEnumerable<Hotel>> GetPagedAndFilteredAsync(HotelQueryParameters parameters);
    }
}