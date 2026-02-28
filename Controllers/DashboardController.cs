using LojaMae.Api.Data;
using LojaMae.Api.Dtos;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace LojaMae.Api.Controllers;

[ApiController]
[Route("api/dashboard")]
public class DashboardController : ControllerBase
{
    private readonly AppDbContext _context;

    public DashboardController(AppDbContext context)
    {
        _context = context;
    }

    // GET api/dashboard/resumo
    [HttpGet("resumo")]
    public async Task<IActionResult> Resumo()
    {
        var caixaAberto = await _context.CaixaAberto
            .FromSqlRaw(@"SELECT * FROM public.caixa_aberto()")
            .AsNoTracking()
            .FirstOrDefaultAsync();

        var hoje = await _context.CaixaHojeView
            .FromSqlRaw(@"
                SELECT dia, total_dia
                FROM vw_caixa_total_dia
                WHERE dia = CURRENT_DATE
                LIMIT 1
            ")
            .AsNoTracking()
            .FirstOrDefaultAsync();

        var dto = new DashboardResumoDto
        {
            CaixaAberto = caixaAberto is not null,
            Dia = DateOnly.FromDateTime(DateTime.UtcNow),
            TotalRecebidoHoje = hoje?.TotalDia ?? 0m
        };

        return Ok(dto);
    }

    // GET api/dashboard/formas-hoje
    [HttpGet("formas-hoje")]
    public async Task<IActionResult> FormasHoje()
    {
        var dados = await _context.Database
            .SqlQueryRaw<DashboardFormaPagamentoDto>(@"
                SELECT 
                    forma AS ""Forma"",
                    COALESCE(SUM(valor), 0) AS ""Total""
                FROM pagamentos
                WHERE DATE(data_pagamento) = CURRENT_DATE
                GROUP BY forma
                ORDER BY forma
            ")
            .ToListAsync();

        return Ok(dados);
    }

    // ✅ NOVO: GET api/dashboard/diario?dias=7
    [HttpGet("diario")]
    public async Task<IActionResult> Diario([FromQuery] int dias = 7)
    {
        if (dias < 1) dias = 1;
        if (dias > 365) dias = 365;

        var param = new NpgsqlParameter("dias", dias);

        var dados = await _context.CaixaHojeView
            .FromSqlRaw(@"
                SELECT dia, total_dia
                FROM vw_caixa_total_dia
                WHERE dia >= (CURRENT_DATE - (@dias * INTERVAL '1 day'))
                ORDER BY dia
            ", param)
            .AsNoTracking()
            .ToListAsync();

        // Retorna no formato da view mesmo: [{ dia, totalDia }]
        return Ok(dados);
    }
}