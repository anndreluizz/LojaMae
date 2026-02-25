using LojaMae.Api.Data;
using LojaMae.Api.Dtos;
using LojaMae.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CaixaController : ControllerBase
{
    private readonly AppDbContext _context;

    public CaixaController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("aberto")]
    public async Task<ActionResult<CaixaResponseDto>> GetCaixaAberto()
    {
        var caixa = await _context.CaixaAberto
            .FromSqlRaw("SELECT * FROM public.caixa_aberto()")
            .AsNoTracking()
            .FirstOrDefaultAsync();

        if (caixa == null)
            return NotFound(new ErrorResponseDto { Message = "Nenhum caixa aberto." });

        // ✅ Mapeia do model keyless para o DTO
        var dto = new CaixaResponseDto
        {
            // ⚠️ Ajuste conforme os campos reais:
            // VendaId = caixa.VendaId,
            // Total = caixa.Total,
            // DataAbertura = caixa.DataAbertura
        };

        return Ok(dto);
    }
}