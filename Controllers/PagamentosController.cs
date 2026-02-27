using LojaMae.Api.Data;
using LojaMae.Api.Dtos;
using LojaMae.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PagamentosController : ControllerBase
{
    private readonly AppDbContext _context;

    public PagamentosController(AppDbContext context)
    {
        _context = context;
    }

    // POST api/pagamentos
    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] PagamentoCreateDto dto)
    {
        // 1) Buscar caixa aberto
        var caixaAberto = await _context.CaixaAberto
            .FromSqlRaw(@"SELECT * FROM public.caixa_aberto()")
            .AsNoTracking()
            .FirstOrDefaultAsync();

        if (caixaAberto is null)
        {
            return Conflict(new ErrorResponseDto
            {
                Message = "Não existe caixa aberto. Abra o caixa antes de registrar pagamento."
            });
        }

        // 2) Criar pagamento com CaixaId automático
        var pagamento = new Pagamento
        {
            VendaId = dto.VendaId,
            Forma = dto.Forma,
            Valor = dto.Valor,
            DataPagamento = DateTime.UtcNow,
            CaixaId = caixaAberto.Id
        };

        _context.Pagamentos.Add(pagamento);
        await _context.SaveChangesAsync();

        var response = new PagamentoResponseDto
        {
            Id = pagamento.Id,
            VendaId = pagamento.VendaId,
            CaixaId = pagamento.CaixaId,
            Forma = pagamento.Forma,
            Valor = pagamento.Valor,
            DataPagamento = pagamento.DataPagamento
        };

        return Ok(response);
    }

    // GET api/pagamentos/5 (opcional, mas útil)
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var pagamento = await _context.Pagamentos.AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id);

        if (pagamento is null)
            return NotFound(new ErrorResponseDto { Message = "Pagamento não encontrado." });

        var response = new PagamentoResponseDto
        {
            Id = pagamento.Id,
            VendaId = pagamento.VendaId,
            CaixaId = pagamento.CaixaId,
            Forma = pagamento.Forma,
            Valor = pagamento.Valor,
            DataPagamento = pagamento.DataPagamento
        };

        return Ok(response);
    }
}