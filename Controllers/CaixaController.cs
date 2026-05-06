using LojaMae.Api.Data;
using LojaMae.Api.Dtos;
using LojaMae.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using System.Data;

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
    // GET - CAIXA ABERTO
    // =========================================
    [HttpGet("aberto")]
    public async Task<ActionResult<CaixaResponseDto>> GetCaixaAberto()
    {
        var caixa = await _context.Database
            .SqlQueryRaw<CaixaAbertoView>(@"
                SELECT
                  caixa_id         AS ""Id"",
                  data_abertura    AS ""DataAbertura"",
                  data_fechamento  AS ""DataFechamento"",
                  valor_inicial    AS ""ValorInicial"",
                  total_pagamentos AS ""TotalPagamentos"",
                  saldo_atual      AS ""SaldoAtual"",
                  (data_fechamento IS NULL) AS ""Aberto""
                FROM public.vw_caixa_saldo
                WHERE data_fechamento IS NULL
                ORDER BY caixa_id DESC
                LIMIT 1
            ")
            .AsNoTracking()
            .FirstOrDefaultAsync();

        if (caixa == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Message = "Nenhum caixa aberto."
            });
        }

        return Ok(new CaixaResponseDto
        {
            Id = caixa.Id,
            Status = caixa.Aberto ? "ABERTO" : "FECHADO",
            DataAbertura = caixa.DataAbertura,
            ValorInicial = caixa.ValorInicial,
            TotalPagamentos = caixa.TotalPagamentos,
            SaldoCaixa = caixa.SaldoAtual
        });
    }

    // =========================================
    // GET - FORMAS DE PAGAMENTO DO CAIXA ABERTO
    // =========================================
    [HttpGet("formas-pagamento")]
    public async Task<ActionResult<IEnumerable<CaixaFormaPagamentoDto>>> GetFormasPagamento()
    {
        var caixaAberto = await _context.Caixas
            .Where(c => c.DataFechamento == null)
            .OrderByDescending(c => c.DataAbertura)
            .FirstOrDefaultAsync();

        if (caixaAberto == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Message = "Nenhum caixa aberto."
            });
        }

        var resultado = await _context.Pagamentos
            .Where(p => p.CaixaId == caixaAberto.Id)
            .GroupBy(p => p.Forma)
            .Select(g => new CaixaFormaPagamentoDto
            {
                FormaPagamento = g.Key,
                Total = g.Sum(x => x.Valor)
            })
            .ToListAsync();

        return Ok(resultado);
    }

    // =========================================
    // POST - ABRIR CAIXA
    // =========================================
    [HttpPost("abrir")]
    public async Task<IActionResult> AbrirCaixa([FromBody] CaixaAbrirDto dto)
    {
        var jaTemAberto = await _context.Caixas
            .AnyAsync(c => c.DataFechamento == null);

        if (jaTemAberto)
        {
            return Conflict(new ErrorResponseDto
            {
                Message = "Já existe um caixa aberto."
            });
        }

        if (dto == null)
        {
            return BadRequest(new ErrorResponseDto
            {
                Message = "Dados inválidos."
            });
        }

        if (dto.ValorInicial < 0)
        {
            return BadRequest(new ErrorResponseDto
            {
                Message = "Valor inicial não pode ser negativo."
            });
        }

        var caixa = new Caixa
        {
            DataAbertura = DateTime.UtcNow,
            ValorInicial = dto.ValorInicial,
            Aberto = true,
            DataFechamento = null,
            ValorFinal = null,
            Diferenca = null
        };

        _context.Caixas.Add(caixa);
        await _context.SaveChangesAsync();

        return Ok(new CaixaResponseDto
        {
            Id = caixa.Id,
            Status = "ABERTO",
            DataAbertura = caixa.DataAbertura,
            ValorInicial = caixa.ValorInicial,
            TotalPagamentos = 0,
            SaldoCaixa = caixa.ValorInicial
        });
    }

    // =========================================
    // POST - FECHAR CAIXA
    // =========================================
    [HttpPost("fechar")]
    public async Task<IActionResult> FecharCaixa([FromBody] CaixaFecharDto dto)
    {
        var caixaDb = await _context.Caixas
            .Where(c => c.DataFechamento == null)
            .OrderByDescending(c => c.DataAbertura)
            .FirstOrDefaultAsync();

        if (caixaDb == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Message = "Nenhum caixa aberto para fechar."
            });
        }

        var conn = (NpgsqlConnection)_context.Database.GetDbConnection();
        if (conn.State != ConnectionState.Open)
        {
            await conn.OpenAsync();
        }

        CaixaAbertoView? saldoView = null;

        await using (var cmd = new NpgsqlCommand(@"
            SELECT
              caixa_id,
              data_abertura,
              data_fechamento,
              valor_inicial,
              total_pagamentos,
              saldo_atual,
              (data_fechamento IS NULL) AS aberto
            FROM public.vw_caixa_saldo
            WHERE caixa_id = @caixaId
            ORDER BY caixa_id DESC
            LIMIT 1
        ", conn))
        {
            cmd.Parameters.AddWithValue("@caixaId", caixaDb.Id);

            await using (var reader = await cmd.ExecuteReaderAsync())
            {
                if (await reader.ReadAsync())
                {
                    saldoView = new CaixaAbertoView
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("caixa_id")),
                        DataAbertura = reader.GetDateTime(reader.GetOrdinal("data_abertura")),
                        DataFechamento = reader.IsDBNull(reader.GetOrdinal("data_fechamento"))
                            ? null
                            : reader.GetDateTime(reader.GetOrdinal("data_fechamento")),
                        ValorInicial = reader.GetDecimal(reader.GetOrdinal("valor_inicial")),
                        TotalPagamentos = reader.GetDecimal(reader.GetOrdinal("total_pagamentos")),
                        SaldoAtual = reader.GetDecimal(reader.GetOrdinal("saldo_atual")),
                        Aberto = reader.GetBoolean(reader.GetOrdinal("aberto"))
                    };
                }
            }
        }

        if (saldoView == null)
        {
            return StatusCode(500, new ErrorResponseDto
            {
                Message = "Não foi possível calcular o saldo do caixa."
            });
        }

        var valorFinal = dto?.ValorFinal ?? saldoView.SaldoAtual;

        if (valorFinal < 0)
        {
            return BadRequest(new ErrorResponseDto
            {
                Message = "Valor final não pode ser negativo."
            });
        }

        caixaDb.ValorFinal = valorFinal;
        caixaDb.DataFechamento = DateTime.UtcNow;
        caixaDb.Aberto = false;
        caixaDb.Diferenca = dto?.Diferenca ?? (valorFinal - saldoView.SaldoAtual);

        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = "Caixa fechado com sucesso.",
            caixaDb.Id,
            caixaDb.DataAbertura,
            caixaDb.DataFechamento,
            caixaDb.ValorInicial,
            caixaDb.ValorFinal,
            caixaDb.Diferenca,
            TotalPagamentos = saldoView.TotalPagamentos,
            SaldoAtual = saldoView.SaldoAtual
        });
    }
}