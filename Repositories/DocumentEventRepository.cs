using TouristAgencyApp.DTOs;
using TouristAgencyApp.Models;

namespace TouristAgencyApp.Repositories;

public class DocumentEventRepository(IConfiguration configuration)
    : StoredCrudRepository<DocumentEvent, DocumentEventCreateDto>(configuration)
{
    protected override string Entity => "document_event";
}
