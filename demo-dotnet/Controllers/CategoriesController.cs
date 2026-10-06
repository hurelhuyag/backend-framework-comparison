using DemoDotnet.Dtos;
using DemoDotnet.Services;
using Microsoft.AspNetCore.Mvc;

namespace DemoDotnet.Controllers;

[ApiController]
[Route("categories")]
[Route("api/categories")]
public sealed class CategoriesController(ICategoryService categoryService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CategoryDto>>> GetAll(CancellationToken cancellationToken) =>
        Ok(await categoryService.GetAllAsync(cancellationToken));
}
