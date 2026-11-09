using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FinancesController : ControllerBase
    {
        private readonly IFinanceRepository _financeRepository;

        public FinancesController(IFinanceRepository financeRepository)
        {
            _financeRepository = financeRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllFinances()
        {
            var finances = await _financeRepository.GetAllAsync();
            return Ok(finances);
        }

        [HttpPost]
        public async Task<IActionResult> CreateFinance([FromBody] FinanceCreateDto financeDto)
        {
            var newFinanceId = await _financeRepository.AddAsync(financeDto);
            return Created($"/api/Finances/{newFinanceId}", new { id = newFinanceId });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetFinanceById(int id)
        {
            var finance = await _financeRepository.GetByIdAsync(id);
            if (finance == null) return NotFound($"Транзакция с ID {id} не найдена.");
            return Ok(finance);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateFinance(int id, [FromBody] FinanceCreateDto financeDto)
        {
            var updated = await _financeRepository.UpdateAsync(id, financeDto);
            if (!updated) return NotFound($"Транзакция с ID {id} для обновления не найдена.");
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteFinance(int id)
        {
            var deleted = await _financeRepository.DeleteAsync(id);
            if (!deleted) return NotFound($"Транзакция с ID {id} для удаления не найдена.");
            return NoContent();
        }
    }
}