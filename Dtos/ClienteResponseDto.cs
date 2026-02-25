namespace LojaMae.Api.Dtos;

public class ClienteResponseDto
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
    public string? Cidade { get; set; }
}