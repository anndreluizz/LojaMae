using LojaMae.Api.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// =========================
// DB CONTEXT (PostgreSQL)
// =========================
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// =========================
// CORS LIBERADO TOTAL (DEV)
// =========================
builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontDev", policy =>
    {
        policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

// =========================
// Controllers + Swagger
// =========================
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// =========================
// Swagger
// =========================
app.UseSwagger();
app.UseSwaggerUI();

// ⚠️ IMPORTANTE
// COMENTAMOS HTTPS REDIRECTION PARA DEV
// Isso evita conflito de protocolo
// app.UseHttpsRedirection();

app.UseCors("FrontDev");

app.UseAuthorization();

app.MapControllers();

app.Run();