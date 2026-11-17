using System.Data;
using Dapper;
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

        public async Task<IEnumerable<CustomsTouristListDto>> GetCustomsTouristListAsync(int? flightId, string? category)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var result = await db.QuerySingleAsync<string>(
                "CALL public.coursework_customs_by_flight(CAST(@FlightId AS integer), @Category, NULL)",
                new { FlightId = flightId, Category = Normalize(category) });
            return StoredProcedureDataAccess.DeserializeList<CustomsTouristListDto>(result);
        }

        public Task<IEnumerable<HotelCheckInListDto>> GetHotelCheckInListAsync(string? hotelName, string? category) =>
            GetReportRowsAsync<HotelCheckInListDto>(
                "hotel_check_in",
                new { HotelName = Normalize(hotelName), Category = Normalize(category) });

        public async Task<TouristCountDto> GetTouristCountAsync(
            DateTime? startDate,
            DateTime? endDate,
            string? category)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var result = await db.QuerySingleAsync<string>(
                "CALL public.coursework_tourist_count_with_children(CAST(@StartDate AS date), CAST(@EndDate AS date), @Category, NULL)",
                new { StartDate = startDate, EndDate = endDate, Category = Normalize(category) });
            return StoredProcedureDataAccess.Deserialize<TouristCountDto>(result);
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

        public async Task<IEnumerable<ExcursionParticipantDto>> GetExcursionParticipantsAsync(
            DateTime startDate, DateTime endDate, int? agencyId, int? excursionId)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var result = await db.QuerySingleAsync<string>(
                "CALL public.coursework_excursion_participants(CAST(@StartDate AS date), CAST(@EndDate AS date), @AgencyId, @ExcursionId, NULL)",
                new { StartDate = startDate, EndDate = endDate, AgencyId = agencyId, ExcursionId = excursionId });
            return StoredProcedureDataAccess.DeserializeList<ExcursionParticipantDto>(result);
        }

        public Task<IEnumerable<FlightLoadReportDto>> GetFlightLoadReportAsync(
            DateTime startDate,
            DateTime endDate,
            string? flightNumber) =>
            GetReportRowsAsync<FlightLoadReportDto>(
                "flight_load",
                new { StartDate = startDate, EndDate = endDate, FlightNumber = Normalize(flightNumber) });

        public Task<IEnumerable<CargoSummaryReportDto>> GetCargoSummaryReportAsync() =>
            GetReportRowsAsync<CargoSummaryReportDto>("cargo_summary", new { });

        public async Task<CargoTurnoverDto> GetCargoTurnoverAsync(DateTime startDate, DateTime endDate)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var result = await db.QuerySingleAsync<string>(
                "CALL public.coursework_cargo_turnover_details(CAST(@StartDate AS date), CAST(@EndDate AS date), NULL)",
                new { StartDate = startDate, EndDate = endDate });
            return StoredProcedureDataAccess.Deserialize<CargoTurnoverDto>(result);
        }

        public async Task<FinancialSummaryDto> GetFinancialSummaryAsync(
            DateTime startDate,
            DateTime endDate,
            int? flightId,
            string? category)
        {
            return (await GetFinancialReportDetailsAsync(startDate, endDate, flightId, category)).Summary;
        }

        public async Task<IEnumerable<FinancialItemDto>> GetFinancialItemsAsync(
            DateTime startDate,
            DateTime endDate,
            int? flightId,
            string? category) =>
            (await GetFinancialReportDetailsAsync(startDate, endDate, flightId, category)).Items;

        public async Task<FinancialReportDetailsDto> GetFinancialReportDetailsAsync(
            DateTime startDate, DateTime endDate, int? flightId, string? category)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var result = await db.QuerySingleAsync<string>(
                "CALL public.coursework_financial_report_details(CAST(@StartDate AS date), CAST(@EndDate AS date), @FlightId, @Category, NULL)",
                new { StartDate = startDate, EndDate = endDate, FlightId = flightId, Category = Normalize(category) });
            return StoredProcedureDataAccess.Deserialize<FinancialReportDetailsDto>(result);
        }

        public async Task<MonthlyBusinessReportDto> GetMonthlyBusinessReportAsync(int year, int month) =>
            (await GetMonthlyBusinessDetailsAsync(year, month)).Summary;

        public async Task<MonthlyBusinessDetailsDto> GetMonthlyBusinessDetailsAsync(int year, int month, int? version = null)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var result = await db.QuerySingleAsync<string>(
                "CALL public.coursework_monthly_report_get(@Year, @Month, @Version, NULL)",
                new { Year = year, Month = month, Version = version });
            return StoredProcedureDataAccess.Deserialize<MonthlyBusinessDetailsDto>(result);
        }

        public async Task<MonthlyBusinessDetailsDto> CloseMonthlyBusinessReportAsync(
            TouristAgencyApp.DTOs.MonthlyReportCloseDto request, string actor)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var catalog = System.Text.Json.JsonSerializer.Serialize(request.Catalog,
                new System.Text.Json.JsonSerializerOptions { PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.SnakeCaseLower });
            var result = await db.QuerySingleAsync<string>(
                "CALL public.coursework_monthly_report_close(@Year, @Month, @ExpectedVersion, CAST(@Catalog AS jsonb), @Reason, @Actor, NULL)",
                new { request.Year, request.Month, request.ExpectedVersion, Catalog = catalog, request.Reason, Actor = actor });
            return StoredProcedureDataAccess.Deserialize<MonthlyBusinessDetailsDto>(result);
        }

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

        public async Task<IEnumerable<FlightTouristDetailsDto>> GetFlightTouristDetailsByIdAsync(int flightId)
        {
            using IDbConnection db = new NpgsqlConnection(_connectionString);
            var result = await db.QuerySingleAsync<string>(
                "CALL public.coursework_flight_details_by_id(@FlightId, NULL)", new { FlightId = flightId });
            return StoredProcedureDataAccess.DeserializeList<FlightTouristDetailsDto>(result);
        }

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
