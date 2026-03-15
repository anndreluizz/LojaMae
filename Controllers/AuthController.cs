using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LojaMae.Api.Data;
using LojaMae.Api.Dtos;

namespace LojaMae.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;

    public AuthController(AppDbContext context)
    {
        _context = context;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        // Busca o usuário no banco (usando SQL puro para bater com sua tabela manual)
        var usuario = await _context.Database
            .SqlQueryRaw<UsuarioLogadoDto>(
                "SELECT id AS \"Id\", nome AS \"Nome\", email AS \"Email\", perfil AS \"Perfil\" " +
                "FROM public.usuarios " +
                "WHERE email = {0} AND senha = {1} AND ativo = true LIMIT 1",
                dto.Email, dto.Senha
            )
            .FirstOrDefaultAsync();

        if (usuario == null)
            return Unauthorized(new { message = "E-mail ou senha incorretos!" });

        return Ok(usuario);
    }
}