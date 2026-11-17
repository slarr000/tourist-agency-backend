using TouristAgencyApp.ReportDTOs;

namespace TouristAgencyApp.Interfaces
{
    public interface IReportRepository
    {
        Task<IEnumerable<CustomsTouristListDto>> GetCustomsTouristListAsync(int? flightId, string? category);
        Task<IEnumerable<HotelCheckInListDto>> GetHotelCheckInListAsync(string? hotelName, string? category);
        Task<TouristCountDto> GetTouristCountAsync(DateTime? startDate, DateTime? endDate, string? category);
        Task<TouristProfileDto?> GetTouristProfileAsync(int touristId);
        Task<IEnumerable<HotelOccupancyDto>> GetHotelOccupancyAsync(DateTime? startDate, DateTime? endDate, string? category);
        Task<ExcursionTouristsCountDto> GetExcursionTouristsCountAsync(DateTime startDate, DateTime endDate);
        Task<IEnumerable<ExcursionSummaryDto>> GetExcursionSummaryAsync();
        Task<IEnumerable<ExcursionAgencyQualityDto>> GetExcursionAgencyQualityAsync();
        Task<IEnumerable<ExcursionParticipantDto>> GetExcursionParticipantsAsync(DateTime startDate, DateTime endDate, int? agencyId, int? excursionId);

        Task<IEnumerable<FlightLoadReportDto>> GetFlightLoadReportAsync(DateTime startDate, DateTime endDate, string? flightNumber);
        Task<IEnumerable<CargoSummaryReportDto>> GetCargoSummaryReportAsync();
        Task<CargoTurnoverDto> GetCargoTurnoverAsync(DateTime startDate, DateTime endDate);
        Task<FinancialSummaryDto> GetFinancialSummaryAsync(DateTime startDate, DateTime endDate, int? flightId, string? category);
        Task<IEnumerable<FinancialItemDto>> GetFinancialItemsAsync(DateTime startDate, DateTime endDate, int? flightId, string? category);
        Task<FinancialReportDetailsDto> GetFinancialReportDetailsAsync(DateTime startDate, DateTime endDate, int? flightId, string? category);
        Task<MonthlyBusinessReportDto> GetMonthlyBusinessReportAsync(int year, int month);
        Task<MonthlyBusinessDetailsDto> GetMonthlyBusinessDetailsAsync(int year, int month, int? version = null);
        Task<MonthlyBusinessDetailsDto> CloseMonthlyBusinessReportAsync(TouristAgencyApp.DTOs.MonthlyReportCloseDto request, string actor);

        Task<IEnumerable<CargoStatisticsDto>> GetCargoTypeStatisticsAsync(DateTime? startDate, DateTime? endDate);
        Task<TouristsCategoryRatioDto> GetTouristsCategoryRatioAsync(DateTime? startDate, DateTime? endDate);
        Task<IEnumerable<FlightTouristDetailsDto>> GetFlightTouristDetailsAsync(string flightNumber);
        Task<IEnumerable<FlightTouristDetailsDto>> GetFlightTouristDetailsByIdAsync(int flightId);

        // Дополнительные
        Task<IEnumerable<PassportControlDto>> GetPassportControlReportAsync();
        Task<IEnumerable<FamilyTourReportDto>> GetFamilyToursReportAsync();
        Task<IEnumerable<VisaStatusReportDto>> GetVisaStatusReportAsync(bool hasVisaFilter);
    }
}