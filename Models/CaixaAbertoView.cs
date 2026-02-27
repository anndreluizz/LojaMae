using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Models;

[Keyless]
public class CaixaAbertoView
{
    public int Id { get; set; }
    public DateTime DataAbertura { get; set; }
    public decimal ValorInicial { get; set; }
    public bool Aberto { get; set; }
}