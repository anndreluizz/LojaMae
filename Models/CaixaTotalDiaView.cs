using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Models;

[Keyless]
public class CaixaTotalDiaView
{
    public DateOnly Dia { get; set; }
    public decimal TotalDia { get; set; }
}