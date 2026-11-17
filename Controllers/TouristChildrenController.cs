using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Interfaces;

namespace TouristAgencyApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TouristChildrenController : ControllerBase
    {
        private readonly ITouristChildRepository _childRepository;

        public TouristChildrenController(ITouristChildRepository childRepository)
        {
            _childRepository = childRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllChildren()
        {
            var children = await _childRepository.GetAllAsync();
            return Ok(children);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetChildById(int id)
        {
            var child = await _childRepository.GetByIdAsync(id);
            if (child == null)
            {
                return NotFound($"Ребенок с ID {id} не найден.");
            }
            return Ok(child);
        }

        [HttpPost]
        public async Task<IActionResult> CreateChild([FromBody] TouristChildCreateDto childDto)
        {
            var newChildId = await _childRepository.AddAsync(childDto);
            return Created($"/api/TouristChildren/{newChildId}", new { id = newChildId });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateChild(int id, [FromBody] TouristChildCreateDto childDto)
        {
            var updated = await _childRepository.UpdateAsync(id, childDto);
            if (!updated)
            {
                return NotFound($"Ребенок с ID {id} для обновления не найден.");
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteChild(int id)
        {
            var deleted = await _childRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound($"Ребенок с ID {id} для удаления не найден.");
            }

            return NoContent();
        }
    }
}