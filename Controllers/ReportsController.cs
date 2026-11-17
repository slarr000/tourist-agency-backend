using Microsoft.AspNetCore.Mvc;
using Npgsql;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;
using TouristAgencyApp.ReportDTOs;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReportsController : ControllerBase
    {
        private readonly IReportRepository _reportRepository;

        public ReportsController(IReportRepository reportRepository)
        {
            _reportRepository = reportRepository;
        }

        // Запрос 1
        [HttpGet("customs-list")]
        public async Task<IActionResult> GetCustomsList([FromQuery] int? flightId, [FromQuery] string? category)
        {
            if (flightId < 1)
            {
                return BadRequest(new { message = "Выберите корректный рейс." });
            }
            try
            {
                return Ok(await _reportRepository.GetCustomsTouristListAsync(flightId, category));
            }
            catch (PostgresException exception) when (exception.SqlState == "22023")
            {
                return BadRequest(new { message = "Выбранный рейс не существует. Обновите список рейсов." });
            }
        }

        // Запрос 2
        [HttpGet("hotel-check-in-list")]
        public async Task<IActionResult> GetHotelCheckInList([FromQuery] string? hotelName, [FromQuery] string? category)
        {
            return Ok(await _reportRepository.GetHotelCheckInListAsync(hotelName, category));
        }

        // Запрос 3
        [HttpGet("tourists-count")]
        public async Task<IActionResult> GetTouristsCount([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate, [FromQuery] string? category)
        {
            if (startDate > endDate)
            {
                return BadRequest(new { message = "Начало периода не может быть позже его окончания." });
            }
            return Ok(await _reportRepository.GetTouristCountAsync(startDate, endDate, category));
        }

      
        [HttpGet("tourist-profile/{touristId}")]
        public async Task<IActionResult> GetTouristProfile(int touristId)
        {
            var profile = await _reportRepository.GetTouristProfileAsync(touristId);
            return profile is null ? NotFound() : Ok(profile);
        }
      

        // Запрос 5
        [HttpGet("hotel-occupancy")]
        public async Task<IActionResult> GetHotelOccupancy(
            [FromQuery] DateTime? startDate,
            [FromQuery] DateTime? endDate,
            [FromQuery] string? category)
        {
            if (startDate > endDate)
            {
                return BadRequest(new { message = "Начало периода не может быть позже его окончания." });
            }
            return Ok(await _reportRepository.GetHotelOccupancyAsync(startDate, endDate, category));
        }

        // Запрос 6
        [HttpGet("excursions-tourists-count")]
        public async Task<IActionResult> GetExcursionTouristsCount([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
        {
            if (startDate == default || endDate == default || startDate > endDate)
            {
                return BadRequest(new { message = "Укажите корректные даты начала и окончания периода." });
            }
            return Ok(await _reportRepository.GetExcursionTouristsCountAsync(startDate, endDate));
        }

        // Запрос 7
        [HttpGet("excursions-summary")]
        public async Task<IActionResult> GetExcursionSummary()
        {
            return Ok(await _reportRepository.GetExcursionSummaryAsync());
        }

        [HttpGet("excursion-agency-quality")]
        public async Task<IActionResult> GetExcursionAgencyQuality()
        {
            return Ok(await _reportRepository.GetExcursionAgencyQualityAsync());
        }

        [HttpGet("excursion-participants")]
        public async Task<IActionResult> GetExcursionParticipants(
            [FromQuery] DateTime startDate, [FromQuery] DateTime endDate,
            [FromQuery] int? agencyId, [FromQuery] int? excursionId)
        {
            if (startDate == default || endDate == default || startDate > endDate || agencyId < 1 || excursionId < 1)
            {
                return BadRequest(new { message = "Проверьте период, агентство и экскурсию." });
            }
            return Ok(await _reportRepository.GetExcursionParticipantsAsync(startDate, endDate, agencyId, excursionId));
        }

        // Запрос 8 (Синхронизировано с твоим рабочим методом)
        [HttpGet("flight-load")]
        public async Task<IActionResult> GetFlightLoad(
            [FromQuery] DateTime startDate,
            [FromQuery] DateTime endDate,
            [FromQuery] string? flightNumber)
        {
            if (startDate == default || endDate == default || startDate > endDate)
            {
                return BadRequest(new { message = "Начало периода не может быть позже его окончания." });
            }
            return Ok(await _reportRepository.GetFlightLoadReportAsync(startDate, endDate, flightNumber));
        }

        // Запрос 9 (Синхронизировано с твоим рабочим методом)
        [HttpGet("cargo-summary")]
        public async Task<IActionResult> GetCargoSummary()
        {
            return Ok(await _reportRepository.GetCargoSummaryReportAsync());
        }

        // Запросы 10, 11, 13 (Синхронизировано с твоим рабочим методом)
        [HttpGet("financial-summary")]
        public async Task<IActionResult> GetFinancialSummary(
            [FromQuery] DateTime startDate,
            [FromQuery] DateTime endDate,
            [FromQuery] int? flightId,
            [FromQuery] string? category)
        {
            if (startDate == default || endDate == default || startDate > endDate || flightId < 1 ||
                (!string.IsNullOrWhiteSpace(category) && category.Trim() is not ("Отдых" or "Шоп-тур")))
            {
                return BadRequest(new { message = "Проверьте период и ID группы." });
            }
            return Ok(await _reportRepository.GetFinancialSummaryAsync(startDate, endDate, flightId, category));
        }

        [HttpGet("financial-items")]
        public async Task<IActionResult> GetFinancialItems(
            [FromQuery] DateTime startDate,
            [FromQuery] DateTime endDate,
            [FromQuery] int? flightId,
            [FromQuery] string? category)
        {
            if (startDate == default || endDate == default || startDate > endDate || flightId < 1 ||
                (!string.IsNullOrWhiteSpace(category) && category.Trim() is not ("Отдых" or "Шоп-тур")))
            {
                return BadRequest(new { message = "Проверьте период и ID группы." });
            }
            return Ok(await _reportRepository.GetFinancialItemsAsync(startDate, endDate, flightId, category));
        }

        [HttpGet("financial-details")]
        public async Task<IActionResult> GetFinancialDetails(
            [FromQuery] DateTime startDate, [FromQuery] DateTime endDate,
            [FromQuery] int? flightId, [FromQuery] string? category)
        {
            if (startDate == default || endDate == default || startDate > endDate || flightId < 1 ||
                (!string.IsNullOrWhiteSpace(category) && category.Trim() is not ("Отдых" or "Шоп-тур")))
            {
                return BadRequest(new { message = "Проверьте период, группу и категорию." });
            }
            return Ok(await _reportRepository.GetFinancialReportDetailsAsync(startDate, endDate, flightId, category));
        }

        [HttpGet("monthly-business")]
        public async Task<IActionResult> GetMonthlyBusinessReport([FromQuery] int year, [FromQuery] int month)
        {
            if (year < 2000 || year > 2100 || month is < 1 or > 12)
            {
                return BadRequest(new { message = "Укажите корректные год и месяц." });
            }
            return Ok(await _reportRepository.GetMonthlyBusinessReportAsync(year, month));
        }

        [HttpGet("monthly-business-details")]
        public async Task<IActionResult> GetMonthlyBusinessDetails([FromQuery] int year, [FromQuery] int month, [FromQuery] int? version)
        {
            if (year < 2000 || year > 2100 || month is < 1 or > 12)
            {
                return BadRequest(new { message = "Укажите корректные год и месяц." });
            }
            try
            {
                return Ok(await _reportRepository.GetMonthlyBusinessDetailsAsync(year, month, version));
            }
            catch (PostgresException exception) when (exception.SqlState == "22023")
            {
                return BadRequest(new { message = exception.MessageText });
            }
        }

        [HttpPost("monthly-business-close")]
        public async Task<IActionResult> CloseMonthlyBusiness([FromBody] MonthlyReportCloseDto request)
        {
            if (request.Confirmed != true)
                return BadRequest(new { message = "Подтвердите список путёвок и количество мест." });
            var actor = User.Identity?.Name;
            if (string.IsNullOrWhiteSpace(actor))
                return Unauthorized();
            try
            {
                return Ok(await _reportRepository.CloseMonthlyBusinessReportAsync(request, actor));
            }
            catch (PostgresException exception) when (exception.SqlState == "22023")
            {
                return BadRequest(new { message = exception.MessageText });
            }
        }

        [HttpGet("cargo-turnover")]
        public async Task<IActionResult> GetCargoTurnover([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
        {
            if (startDate == default || endDate == default || startDate > endDate)
            {
                return BadRequest(new { message = "Начало периода не может быть позже его окончания." });
            }
            return Ok(await _reportRepository.GetCargoTurnoverAsync(startDate, endDate));
        }

        // Запрос 12
        [HttpGet("cargo-statistics")]
        public async Task<IActionResult> GetCargoStatistics([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            if (startDate > endDate)
            {
                return BadRequest(new { message = "Начало периода не может быть позже его окончания." });
            }
            return Ok(await _reportRepository.GetCargoTypeStatisticsAsync(startDate, endDate));
        }

        // Запрос 14
        [HttpGet("category-ratio")]
        public async Task<IActionResult> GetCategoryRatio([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            if (startDate > endDate)
            {
                return BadRequest(new { message = "Начало периода не может быть позже его окончания." });
            }
            return Ok(await _reportRepository.GetTouristsCategoryRatioAsync(startDate, endDate));
        }

        // Запрос 15 (ФИНАЛ)
        [HttpGet("flight-tourist-details")]
        public async Task<IActionResult> GetFlightTouristDetails([FromQuery] string flightNumber)
        {
            if (string.IsNullOrWhiteSpace(flightNumber))
            {
                return BadRequest(new { message = "Укажите номер рейса." });
            }
            return Ok(await _reportRepository.GetFlightTouristDetailsAsync(flightNumber));
        }

        [HttpGet("flight-details-by-id")]
        public async Task<IActionResult> GetFlightTouristDetailsById([FromQuery] int? flightId)
        {
            if (flightId is null or < 1)
            {
                return BadRequest(new { message = "Выберите рейс." });
            }
            try
            {
                return Ok(await _reportRepository.GetFlightTouristDetailsByIdAsync(flightId.Value));
            }
            catch (PostgresException exception) when (exception.SqlState == "22023")
            {
                return BadRequest(new { message = "Выбранный рейс не существует. Обновите список рейсов." });
            }
        }

        // =========================================================
        // ДОПОЛНИТЕЛЬНЫЕ ОТЧЕТЫ (Вне списка 1-15)
        // =========================================================

        [HttpGet("passport-control")]
        public async Task<IActionResult> GetPassportControl()
        {
            return Ok(await _reportRepository.GetPassportControlReportAsync());
        }

        [HttpGet("family-tours")]
        public async Task<IActionResult> GetFamilyTours()
        {
            return Ok(await _reportRepository.GetFamilyToursReportAsync());
        }

        [HttpGet("visa-status")]
        public async Task<IActionResult> GetVisaStatus([FromQuery] bool hasVisa)
        {
            return Ok(await _reportRepository.GetVisaStatusReportAsync(hasVisa));
        }
    }
}