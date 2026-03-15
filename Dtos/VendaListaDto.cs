namespace LojaMae.Api.Dtos;

public class VendaListaDto
{
    public int Id { get; set; }
    public DateTime DataVenda { get; set; }
    public decimal Total { get; set; }
    public string? ClienteNome { get; set; }
    public string? Status { get; set; }
}