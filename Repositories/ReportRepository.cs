using System.Data;
using Microsoft.Extensions.Configuration;
using Npgsql;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.ReportDTOs;

namespace TouristAgencyApp.Repositories
{
    public class ReportRepository : IReportRepository
    {
        private readonly string _connectionString;

        public ReportRepository(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException("Connection string is missing");
        }

        public Task<IEnumerable<CustomsTouristListDto>> GetCustomsTouristListAsync(string? category) =>
            GetReportRowsAsync<CustomsTouristListDto>(
                "customs_tourists",
                new { Category = Normalize(category) });

        public Task<IEnumerable<HotelCheckInListDto>> GetHotelCheckInListAsync(string? hotelName, string? category) =>
            GetReportRowsAsync<HotelCheckInListDto>(
                "hotel_check_in",
                new { HotelName = Normalize(hotelName), Category = Normalize(category) });

        public async Task<TouristCountDto> GetTouristCountAsync(
            DateTime? startDate,
            DateTime? endDate,
            string? category)
        {
            return await GetReportObjectAsync<TouristCountDto>(
                "tourist_count",
                new { StartDate = startDate, EndDate = endDate, Category = Normalize(category) });
        }

        public Task<TouristProfileDto?> GetTouristProfileAsync(int touristId) =>
            GetNullableReportObjectAsync<TouristProfileDto>(
                "tourist_profile",
                new { TouristId = touristId });

        public Task<IEnumerable<HotelOccupancyDto>> GetHotelOccupancyAsync(
            DateTime? startDate,
            DateTime? endDate,
            string? category) =>
            GetReportRowsAsync<HotelOccupancyDto>(
                "hotel_occupancy",
                new { StartDate = startDate, EndDate = endDate, Category = Normalize(category) });

        public async Task<ExcursionTouristsCountDto> GetExcursionTouristsCountAsync(
            DateTime startDate,
            DateTime endDate)
        {
            return await GetReportObjectAsync<ExcursionTouristsCountDto>(
                "excursion_tourists_count",
                new { StartDate = startDate, EndDate = endDate });
        }

        public Task<IEnumerable<ExcursionSummaryDto>> GetExcursionSummaryAsync() =>
            GetReportRowsAsync<ExcursionSummaryDto>("excursion_summary", new { });

        public Task<IEnumerable<ExcursionAgencyQualityDto>> GetExcursionAgencyQualityAsync() =>
            GetReportRowsAsync<ExcursionAgencyQualityDto>("excursion_agency_quality", new { });

        public Task<IEnumerable<FlightLoadReportDto>> GetFlightLoadReportAsync(
            DateTime startDate,
            DateTime endDate,
            string? flightNumber) =>
            GetReportRowsAsync<FlightLoadReportDto>(
                "flight_load",
                new { StartDate = startDate, EndDate = endDate, FlightNumber = Normalize(flightNumber) });

        public Task<IEnumerable<CargoSummaryReportDto>> GetCargoSummaryReportAsync() =>
            GetReportRowsAsync<CargoSummaryReportDto>("cargo_summary", new { });

        public async Task<CargoTurnoverDto> GetCargoTurnoverAsync(DateTime startDate, DateTime endDate) =>
            await GetReportObjectAsync<CargoTurnoverDto>(
                "cargo_turnover",
                new { StartDate = startDate, EndDate = endDate });

        public async Task<FinancialSummaryDto> GetFinancialSummaryAsync(
            DateTime startDate,
            DateTime endDate,
            int? flightId,
            string? category)
        {
            return await GetReportObjectAsync<FinancialSummaryDto>(
                "financial_summary",
                new
                {
                    StartDate = startDate,
                    EndDate = endDate,
                    FlightId = flightId,
                    Category = Normalize(category)
                });
        }

        public Task<IEnumerable<FinancialItemDto>> GetFinancialItemsAsync(
            DateTime startDate,
            DateTime endDate,
            int? flightId,
            string? category) =>
            GetReportRowsAsync<FinancialItemDto>(
                "financial_items",
                new
                {
                    StartDate = startDate,
                    EndDate = endDate,
                    FlightId = flightId,
                    Category = Normalize(category)
                });

        public async Task<MonthlyBusinessReportDto> GetMonthlyBusinessReportAsync(int year, int month) =>
            await GetReportObjectAsync<MonthlyBusinessReportDto>(
                "monthly_business",
                new { Year = year, Month = month });

        public Task<IEnumerable<CargoStatisticsDto>> GetCargoTypeStatisticsAsync(
            DateTime? startDate,
            DateTime? endDate) =>
            GetReportRowsAsync<CargoStatisticsDto>(
                "cargo_type_statistics",
                new { StartDate = startDate, EndDate = endDate });

        public async Task<TouristsCategoryRatioDto> GetTouristsCategoryRatioAsync(
            DateTime? startDate,
            DateTime? endDate) =>
            await GetReportObjectAsync<TouristsCategoryRatioDto>(
                "tourists_category_ratio",
                new { StartDate = startDate, EndDate = endDate });

        public Task<IEnumerable<FlightTouristDetailsDto>> GetFlightTouristDetailsAsync(string flightNumber) =>
            GetReportRowsAsync<FlightTouristDetailsDto>(
                "flight_tourist_details",
                new { FlightNumber = flightNumber });

        public Task<IEnumerable<PassportControlDto>> GetPassportControlReportAsync() =>
            GetReportRowsAsync<PassportControlDto>("passport_control", new { });

        public Task<IEnumerable<FamilyTourReportDto>> GetFamilyToursReportAsync() =>
            GetReportRowsAsync<FamilyTourReportDto>("family_tours", new { });

        public Task<IEnumerable<VisaStatusReportDto>> GetVisaStatusReportAsync(bool hasVisaFilter) =>
            GetReportRowsAsync<VisaStatusReportDto>(
                "visa_status",
                new { HasVisaFilter = hasVisaFilter });

        private async Task<IEnumerable<T>> GetReportRowsAsync<T>(string reportKey, object parameters)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var result = await StoredProcedureDataAccess.CallJsonProcedureAsync<T[]>(
                db,
                reportKey,
                parameters);
            return result;
        }

        private async Task<T> GetReportObjectAsync<T>(string reportKey, object parameters)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            return await StoredProcedureDataAccess.CallJsonProcedureAsync<T>(
                db,
                reportKey,
                parameters);
        }

        private async Task<T?> GetNullableReportObjectAsync<T>(string reportKey, object parameters)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            return await StoredProcedureDataAccess.CallJsonProcedureNullableAsync<T>(
                db,
                reportKey,
                parameters);
        }

        private static string? Normalize(string? value) =>
            string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
