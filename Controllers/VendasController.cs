using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LojaMae.Api.Data;
using LojaMae.Api.Dtos;
using Npgsql;

namespace LojaMae.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VendasController : ControllerBase
{
    private readonly AppDbContext _context;

    public VendasController(AppDbContext context)
    {
        _context = context;
    }

    // =========================
    // CAIXA
    // =========================

    // GET api/vendas/caixa/hoje
    [HttpGet("caixa/hoje")]
    public async Task<IActionResult> CaixaHoje()
    {
        try
        {
            var hoje = DateTime.UtcNow.Date;
            var total = await _context.Vendas
                .Where(v => v.Status == "Fechada" && v.DataVenda.Date == hoje)
                .SumAsync(v => (decimal?)v.Total) ?? 0m;

            return Ok(new CaixaHojeDto
            {
                Dia = hoje,
                TotalDia = total
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ErrorResponseDto
            {
                Message = "[CAIXA_HOJE] Erro inesperado: " + ex.Message
            });
        }
    }

    // GET api/vendas/caixa/diario?dias=7
    [HttpGet("caixa/diario")]
    public async Task<IActionResult> CaixaDiario([FromQuery] int dias = 7)
    {
        if (dias <= 0) dias = 7;
        if (dias > 365) dias = 365;

        try
        {
            var sql =
                "SELECT " +
                "  dia AS \"Dia\", " +
                "  metodo AS \"Metodo\", " +
                "  total_recebido AS \"TotalRecebido\" " +
                "FROM public.vw_caixa_diario " +
                "WHERE dia >= (CURRENT_DATE - ({0} - 1)) " +
                "ORDER BY dia DESC, metodo;";

            var lista = await _context.Database
                .SqlQueryRaw<CaixaDiarioDto>(sql, dias)
                .ToListAsync();

            return Ok(lista);
        }
        catch (PostgresException ex)
        {
            return BadRequest(new ErrorResponseDto { Message = ex.MessageText });
        }
    }

    // ✅ GET api/vendas/ultimos-dias?dias=7
    [HttpGet("ultimos-dias")]
    public async Task<IActionResult> VendasUltimosDias([FromQuery] int dias = 7)
    {
        if (dias <= 0) dias = 7;
        if (dias > 365) dias = 365;

        try
        {
            var sql =
                "SELECT " +
                "  dia AS \"Dia\", " +
                "  SUM(total_recebido) AS \"Total\" " +
                "FROM public.vw_caixa_diario " +
                "WHERE dia >= (CURRENT_DATE - ({0} - 1)) " +
                "GROUP BY dia " +
                "ORDER BY dia;";

            var lista = await _context.Database
                .SqlQueryRaw<VendasUltimosDiasDto>(sql, dias)
                .ToListAsync();

            return Ok(lista);
        }
        catch (PostgresException ex)
        {
            return BadRequest(new ErrorResponseDto { Message = ex.MessageText });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ErrorResponseDto
            {
                Message = "[ULTIMOS_DIAS] Erro: " + ex.Message
            });
        }
    }

    // =========================
    // ✅ DESCONTO
    // =========================

    // POST api/vendas/{id}/desconto
    // Body: { "desconto": 5.00 }
    [HttpPost("{id:int}/desconto")]
    public async Task<IActionResult> AplicarDesconto(int id, [FromBody] DescontoDto dto)
    {
        if (dto == null || dto.Desconto < 0)
            return BadRequest(new ErrorResponseDto { Message = "Informe um desconto válido (>= 0)." });

        try
        {
            // 1) Calcula o subtotal da venda a partir dos itens já adicionados
            var subtotal = await _context.ItensVenda
                .Where(i => i.VendaId == id)
                .Select(i => i.PrecoUnitario * i.Quantidade)
                .SumAsync();

            // 2) Recupera a venda e atualiza desconto + total (total = subtotal - desconto)
            var venda = await _context.Vendas.FindAsync(id);
            if (venda == null)
                return NotFound(new ErrorResponseDto { Message = "Venda não encontrada" });

            venda.Desconto = dto.Desconto;
            var novoTotal = subtotal - dto.Desconto;
            if (novoTotal < 0) novoTotal = 0m;
            venda.Total = novoTotal;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Desconto aplicado com sucesso",
                vendaId = venda.Id,
                total = venda.Total,
                desconto = venda.Desconto
            });
        }
        catch (PostgresException ex)
        {
            return BadRequest(new ErrorResponseDto { Message = ex.MessageText });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ErrorResponseDto { Message = "[DESCONTO] Erro: " + ex.Message });
        }
    }

    // =========================
    // DEBUG
    // =========================

    // GET api/vendas/debug
    [HttpGet("debug")]
    public async Task<IActionResult> DebugBanco()
    {
        var db = await _context.Database
            .SqlQueryRaw<string>("SELECT current_database() AS \"Value\"")
            .SingleAsync();

        var schema = await _context.Database
            .SqlQueryRaw<string>("SELECT current_schema() AS \"Value\"")
            .SingleAsync();

        var searchPath = await _context.Database
            .SqlQueryRaw<string>("SELECT current_setting('search_path') AS \"Value\"")
            .SingleAsync();

        var funcoes = await _context.Database
            .SqlQueryRaw<string>(
                "SELECT (n.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')') AS \"Value\" " +
                "FROM pg_proc p " +
                "JOIN pg_namespace n ON n.oid = p.pronamespace " +
                "WHERE p.proname ILIKE 'abrir_venda%' " +
                "ORDER BY 1;")
            .ToListAsync();

        return Ok(new { db, schema, searchPath, funcoes });
    }

    // =========================
    // VENDAS
    // =========================

    // ✅ GET api/vendas  (Histórico)
    [HttpGet]
    public async Task<IActionResult> ListarVendas()
    {
        try
        {
            var vendas = await _context.Vendas
                .OrderByDescending(v => v.Id)
                .Select(v => new VendaListaDto
                {
                    Id = v.Id,
                    DataVenda = v.DataVenda,
                    Total = v.Total,
                    Status = v.Status,
                    ClienteNome = _context.Clientes
                        .Where(c => c.Id == v.ClienteId)
                        .Select(c => c.Nome)
                        .FirstOrDefault()
                })
                .ToListAsync();

            return Ok(vendas);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ErrorResponseDto
            {
                Message = "[LISTAR_VENDAS] Erro: " + ex.Message
            });
        }
    }

    // POST api/vendas/abrir
    // Body: { "clienteId": 1 }
    [HttpPost("abrir")]
    public async Task<IActionResult> AbrirVenda([FromBody] AbrirVendaDto dto)
    {
        if (dto == null || dto.ClienteId <= 0)
            return BadRequest(new ErrorResponseDto { Message = "Informe um clienteId válido." });

        try
        {
            var vendaId = await _context.Database
                .SqlQueryRaw<int>(
                    "SELECT public.abrir_venda_api({0}) AS \"Value\"",
                    dto.ClienteId
                )
                .SingleAsync();

            return Ok(new { vendaId });
        }
        catch (PostgresException ex)
        {
            return BadRequest(new ErrorResponseDto { Message = ex.MessageText });
        }
    }

    // POST api/vendas/{vendaId}/itens
    [HttpPost("{vendaId:int}/itens")]
    public async Task<IActionResult> AdicionarItem(int vendaId, [FromBody] VendaItemCreateDto dto)
    {
        if (dto == null || dto.ProdutoId <= 0 || dto.Quantidade <= 0)
            return BadRequest(new ErrorResponseDto { Message = "ProdutoId e Quantidade devem ser válidos." });

        try
        {
            await _context.Database.ExecuteSqlRawAsync(
                "SELECT public.adicionar_item_venda({0}, {1}, {2});",
                vendaId,
                dto.ProdutoId,
                dto.Quantidade
            );

            return Ok(new { message = "Item adicionado com sucesso" });
        }
        catch (PostgresException ex)
        {
            return BadRequest(new ErrorResponseDto { Message = ex.MessageText });
        }
    }

    // GET api/vendas/{id}
    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObterVenda(int id)
    {
        var vendaBase = await _context.Vendas
            .Where(v => v.Id == id)
            .Select(v => new
            {
                v.Id,
                v.Status,
                v.Total
            })
            .FirstOrDefaultAsync();

        if (vendaBase == null)
            return NotFound(new ErrorResponseDto { Message = "Venda não encontrada" });

        var itens = await _context.ItensVenda
            .Where(i => i.VendaId == id)
            .Join(
                _context.Produtos,
                i => i.ProdutoId,
                p => p.Id,
                (i, p) => new VendaItemDto
                {
                    ProdutoId = i.ProdutoId,
                    ProdutoNome = p.Nome,
                    Quantidade = i.Quantidade,
                    PrecoUnitario = i.PrecoUnitario,
                    Subtotal = i.Quantidade * i.PrecoUnitario
                }
            )
            .ToListAsync();

        var venda = new VendaDetalheDto
        {
            Id = vendaBase.Id,
            Status = vendaBase.Status,
            Total = vendaBase.Total,
            Itens = itens
        };

        return Ok(venda);
    }

    // POST api/vendas/{id}/fechar
    [HttpPost("{id:int}/fechar")]
    public async Task<IActionResult> FecharVenda(int id)
    {
        try
        {
            await _context.Database.ExecuteSqlRawAsync(
                "SELECT public.fechar_venda({0});",
                id
            );

            return Ok(new { message = "Venda fechada com sucesso" });
        }
        catch (PostgresException ex)
        {
            return BadRequest(new ErrorResponseDto { Message = ex.MessageText });
        }
    }

    // POST api/vendas/{id}/pagar
    [HttpPost("{id:int}/pagar")]
    public async Task<IActionResult> Pagar(int id, [FromBody] PagamentoCreateDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponseDto { Message = "Dados de pagamento inválidos." });

        try
        {
            await _context.Database.ExecuteSqlRawAsync(
                "SELECT public.registrar_pagamento_venda({0}, {1}, {2});",
                id,
                dto.Valor,
                dto.Forma
            );

            return Ok(new { message = "Pagamento registrado com sucesso" });
        }
        catch (PostgresException ex)
        {
            return BadRequest(new ErrorResponseDto { Message = ex.MessageText });
        }
    }
}