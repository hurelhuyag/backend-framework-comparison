using DemoDotnet.Dtos;
using DemoDotnet.Services;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;

namespace DemoDotnet.Controllers;

// Mounted at both /contents and /api/contents so either benchmark URL shape works.
[ApiController]
[Route("contents")]
[Route("api/contents")]
public sealed class ContentsController(
    IContentService contentService,
    IValidator<UpdateContentDto> updateValidator) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedContentsDto>> GetPage(
        [FromQuery] PageQuery page,
        CancellationToken cancellationToken) =>
        Ok(await contentService.GetPageAsync(page, cancellationToken));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ContentDto>> GetById(int id, CancellationToken cancellationToken)
    {
        var content = await contentService.GetByIdAsync(id, cancellationToken);

        return content is null ? NotFound("content not found") : Ok(content);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ContentDto>> Update(
        int id,
        [FromBody] UpdateContentDto body,
        CancellationToken cancellationToken)
    {
        var validation = await updateValidator.ValidateAsync(body, cancellationToken);

        if (!validation.IsValid)
        {
            return BadRequest(validation.Errors.Select(failure => failure.ErrorMessage));
        }

        var content = await contentService.UpdateTextAsync(id, body.Content, cancellationToken);

        return content is null ? NotFound("content not found") : Ok(content);
    }
}
