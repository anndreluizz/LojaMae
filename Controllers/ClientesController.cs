using LojaMae.Api.Data;
using LojaMae.Api.Dtos;
using LojaMae.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace LojaMae.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ClientesController : ControllerBase
{
    private readonly AppDbContext _context;

    public ClientesController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/clientes
    [HttpGet]
    public async Task<ActionResult<List<ClienteResponseDto>>> Get()
    {
        var clientes = await _context.Clientes
            .Select(c => new ClienteResponseDto
            {
                Id = c.Id,
                Nome = c.Nome,
                Telefone = c.Telefone,
                Cidade = c.Cidade
            })
            .ToListAsync();

        return Ok(clientes);
    }

    // GET: api/clientes/1
    [HttpGet("{id}")]
    public async Task<ActionResult<ClienteResponseDto>> GetById(int id)
    {
        var cliente = await _context.Clientes.FindAsync(id);

        if (cliente == null)
            return NotFound();

        return new ClienteResponseDto
        {
            Id = cliente.Id,
            Nome = cliente.Nome,
            Telefone = cliente.Telefone,
            Cidade = cliente.Cidade
        };
    }

    // POST: api/clientes
    [HttpPost]
    public async Task<ActionResult<ClienteResponseDto>> Post([FromBody] ClienteCreateDto dto)
    {
        var cliente = new Cliente
        {
            Nome = dto.Nome,
            Telefone = dto.Telefone,
            Cidade = dto.Cidade
        };

        _context.Clientes.Add(cliente);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException pg && pg.SqlState == "23505")
        {
            return Conflict(new ErrorResponseDto
            {
                Message = "Já existe um cliente cadastrado com este telefone."
            });
        }

        var response = new ClienteResponseDto
        {
            Id = cliente.Id,
            Nome = cliente.Nome,
            Telefone = cliente.Telefone,
            Cidade = cliente.Cidade
        };

        return CreatedAtAction(nameof(GetById), new { id = cliente.Id }, response);
    }
}