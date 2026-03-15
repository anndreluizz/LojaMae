using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LojaMae.Api.Data;
using LojaMae.Api.Dtos;

namespace LojaMae.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DashboardController : ControllerBase
{
    private readonly AppDbContext _context;

    public DashboardController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("resumo")]
    public async Task<IActionResult> ObterResumo()
    {
        try
        {
            // 1) Faturamento Total e Qtd Vendas (Apenas vendas fechadas) usando a coluna Total (já com desconto)
            var vendasFechadas = await _context.Vendas
                .Where(v => v.Status == "Fechada")
                .ToListAsync();

            var faturamento = vendasFechadas.Sum(v => v.Total);
            var totalVendas = vendasFechadas.Count;

            // 2) Tentamos obter a distribuição por forma de pagamento a partir da view vw_caixa_diario (se existir)
            List<DashboardFormaPagamentoDto> pagamentos = new List<DashboardFormaPagamentoDto>();

            try
            {
                var sql =
                    "SELECT metodo AS \"Forma\", SUM(total_recebido)::numeric AS \"Total\" " +
                    "FROM public.vw_caixa_diario " +
                    "WHERE dia = CURRENT_DATE " +
                    "GROUP BY metodo;";

                pagamentos = await _context.Database
                    .SqlQueryRaw<DashboardFormaPagamentoDto>(sql)
                    .ToListAsync();
            }
            catch
            {
                // Se a view não existir ou ocorrer erro, deixamos a lista vazia (ou poderia preencher zeros)
            }

            var resumo = new DashboardResumoDto
            {
                FaturamentoTotal = faturamento,
                TotalVendas = totalVendas,
                Pagamentos = pagamentos
            };

            return Ok(resumo);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ErrorResponseDto
            {
                Message = "[DASHBOARD_RESUMO] Erro: " + ex.Message
            });
        }
    }
}