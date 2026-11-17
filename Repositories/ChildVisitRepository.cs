using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class ChildVisitRepository(IConfiguration configuration)
    : StoredCrudRepository<ChildVisit, ChildVisitCreateDto>(configuration)
{
    protected override string Entity => "child_visit";
}
