namespace LojaMae.Api.Dtos;

public class VendaDetalheDto
{
    public int Id { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal Total { get; set; }
    public List<VendaItemDto> Itens { get; set; } = new();
}