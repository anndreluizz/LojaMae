using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using LojaMae.Api.Data;
using LojaMae.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProdutosController : ControllerBase
{
    private readonly AppDbContext _context;

    public ProdutosController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Produto>>> Get()
    {
        return await _context.Produtos.OrderBy(p => p.Nome).ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Produto>> GetById(int id)
    {
        var produto = await _context.Produtos.FindAsync(id);
        if (produto == null) return NotFound();
        return produto;
    }

    [HttpGet("codigo/{codigo}")]
    public async Task<ActionResult<Produto>> GetByCodigo(string codigo)
    {
        var produto = await _context.Produtos
            .FirstOrDefaultAsync(p => p.CodigoBarras == codigo);
        if (produto == null) return NotFound();
        return produto;
    }

    [HttpPost]
    public async Task<ActionResult<Produto>> Post([FromBody] Produto produto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try 
        {
            // Forçamos a data para UTC e garantimos o Kind correto
            produto.DataCadastro = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Utc);

            Console.WriteLine($"[DEBUG] Salvando Produto: {produto.Nome} | Codigo: {produto.CodigoBarras}");

            _context.Produtos.Add(produto);
            await _context.SaveChangesAsync();
            
            return CreatedAtAction(nameof(GetById), new { id = produto.Id }, produto);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ERRO NO POST] {ex.Message}");
            // Retorna o erro detalhado para o Flutter conseguir mostrar na tela
            return StatusCode(500, new { erro = ex.Message, detalhe = ex.InnerException?.Message });
        }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Put(int id, [FromBody] Produto produtoAtualizado)
    {
        var produto = await _context.Produtos.FindAsync(id);
        if (produto == null) return NotFound();

        produto.Nome = produtoAtualizado.Nome;
        produto.Preco = produtoAtualizado.Preco;
        produto.Estoque = produtoAtualizado.Estoque;
        produto.CodigoBarras = produtoAtualizado.CodigoBarras;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var produto = await _context.Produtos.FindAsync(id);
        if (produto == null) return NotFound();
        
        _context.Produtos.Remove(produto);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}