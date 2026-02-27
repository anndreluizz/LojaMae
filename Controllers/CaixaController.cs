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

    // =========================================
    // GET - CAIXA ABERTO (saldo automático via VIEW vw_caixa_saldo)
    // =========================================
[HttpGet("aberto")]
public async Task<ActionResult<CaixaResponseDto>> GetCaixaAberto()
{
    var caixa = await _context.Database
        .SqlQueryRaw<CaixaAbertoView>(@"
            SELECT
              caixa_id        AS ""Id"",
              data_abertura   AS ""DataAbertura"",
              data_fechamento AS ""DataFechamento"",
              valor_inicial   AS ""ValorInicial"",
              total_pagamentos AS ""TotalPagamentos"",
              saldo_atual     AS ""SaldoAtual"",
              (data_fechamento IS NULL) AS ""Aberto""
            FROM public.vw_caixa_saldo
            WHERE data_fechamento IS NULL
            ORDER BY caixa_id DESC
            LIMIT 1
        ")
        .AsNoTracking()
        .FirstOrDefaultAsync();

    if (caixa == null)
        return NotFound(new ErrorResponseDto { Message = "Nenhum caixa aberto." });

    return Ok(new CaixaResponseDto
    {
        Id = caixa.Id,
        Status = caixa.Aberto ? "ABERTO" : "FECHADO",
        ValorInicial = caixa.ValorInicial,
        SaldoCaixa = caixa.SaldoAtual
    });
}
    // =========================================
    // POST - ABRIR CAIXA
    // =========================================
    [HttpPost("abrir")]
    public async Task<IActionResult> AbrirCaixa([FromBody] CaixaAbrirDto dto)
    {
        var jaTemAberto = await _context.Caixas.AnyAsync(c => c.Aberto);
        if (jaTemAberto)
            return Conflict(new ErrorResponseDto { Message = "Já existe um caixa aberto." });

        if (dto.ValorInicial < 0)
            return BadRequest(new ErrorResponseDto { Message = "Valor inicial não pode ser negativo." });

        var caixa = new Caixa
        {
            DataAbertura = DateTime.UtcNow, // timestamptz
            ValorInicial = dto.ValorInicial,
            Aberto = true,
            DataFechamento = null,
            ValorFinal = null
        };

        _context.Caixas.Add(caixa);
        await _context.SaveChangesAsync();

        return Ok(new CaixaResponseDto
        {
            Id = caixa.Id,
            Status = "ABERTO",
            ValorInicial = caixa.ValorInicial,
            SaldoCaixa = caixa.ValorInicial
        });
    }

    // =========================================
    // POST - FECHAR CAIXA (salva ValorFinal automaticamente = saldo_atual)
    // =========================================
    [HttpPost("fechar")]
    public async Task<IActionResult> FecharCaixa([FromBody] CaixaFecharDto dto)
    {
        // pega o caixa aberto mais recente
        var caixaDb = await _context.Caixas
            .Where(c => c.Aberto)
            .OrderByDescending(c => c.DataAbertura)
            .FirstOrDefaultAsync();

        if (caixaDb == null)
            return NotFound(new ErrorResponseDto { Message = "Nenhum caixa aberto para fechar." });

        // pega o saldo atual calculado pela VIEW
        var saldoView = await _context.CaixaAberto
            .FromSqlRaw(@"
                SELECT
                  caixa_id        AS ""Id"",
                  data_abertura   AS ""DataAbertura"",
                  data_fechamento AS ""DataFechamento"",
                  valor_inicial   AS ""ValorInicial"",
                  total_pagamentos AS ""TotalPagamentos"",
                  saldo_atual     AS ""SaldoAtual"",
                  (data_fechamento IS NULL) AS ""Aberto""
                FROM public.vw_caixa_saldo
                WHERE caixa_id = {0}
                LIMIT 1;
            ", caixaDb.Id)
            .AsNoTracking()
            .FirstOrDefaultAsync();

        if (saldoView == null)
            return StatusCode(500, new ErrorResponseDto { Message = "Não foi possível calcular o saldo do caixa." });

        // regra: se vier ValorFinal no DTO, usa ele; senão usa saldo_atual calculado
        var valorFinal = dto.ValorFinal ?? saldoView.SaldoAtual;

        if (valorFinal < 0)
            return BadRequest(new ErrorResponseDto { Message = "Valor final não pode ser negativo." });

        caixaDb.ValorFinal = valorFinal;
        caixaDb.DataFechamento = DateTime.UtcNow; // timestamptz
        caixaDb.Aberto = false;

        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = "Caixa fechado com sucesso.",
            caixaDb.Id,
            caixaDb.DataAbertura,
            caixaDb.DataFechamento,
            caixaDb.ValorInicial,
            caixaDb.ValorFinal,
            TotalPagamentos = saldoView.TotalPagamentos
        });
    }
}