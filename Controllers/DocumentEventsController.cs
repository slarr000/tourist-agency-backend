using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Repositories;

namespace TouristAgencyApp.Controllers;

[Route("api/[controller]")]
[ApiController]
public class DocumentEventsController(DocumentEventRepository repository) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll() => Ok(await repository.GetAllAsync());

    [HttpPost]
    public async Task<IActionResult> Create(DocumentEventCreateDto dto)
    {
        var id = await repository.AddAsync(dto);
        return Created($"/api/DocumentEvents/{id}", new { id });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var item = await repository.GetByIdAsync(id);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, DocumentEventCreateDto dto) =>
        await repository.UpdateAsync(id, dto) ? NoContent() : NotFound();

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id) =>
        await repository.DeleteAsync(id) ? NoContent() : NotFound();
}
