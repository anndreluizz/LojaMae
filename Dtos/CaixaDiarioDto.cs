namespace LojaMae.Api.Dtos;

public class CaixaDiarioDto
{
    public DateTime Dia { get; set; }
    public string Metodo { get; set; } = string.Empty;
    public decimal TotalRecebido { get; set; }
}