using Microsoft.AspNetCore.Mvc;
using TouristAgencyApp.DTOs;
using TouristAgencyApp.Repositories;

namespace TouristAgencyApp.Controllers;

[Route("api/[controller]")]
[ApiController]
public class TourPackageSalesController(TourPackageSaleRepository repository) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll() => Ok(await repository.GetAllAsync());
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id) =>
        await repository.GetByIdAsync(id) is { } item ? Ok(item) : NotFound();
    [HttpPost]
    public async Task<IActionResult> Create(TourPackageSaleCreateDto dto)
    {
        var id = await repository.AddAsync(dto);
        return Created($"/api/TourPackageSales/{id}", new { id });
    }
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, TourPackageSaleCreateDto dto) =>
        await repository.UpdateAsync(id, dto) ? NoContent() : NotFound();
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id) =>
        await repository.DeleteAsync(id) ? NoContent() : NotFound();
}
