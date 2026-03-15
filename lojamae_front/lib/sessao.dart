class Sessao {
  static int? id;
  static String? nome;
  static String? email;
  static String? perfil; // 'admin' ou 'funcionario'

  static void limpar() {
    id = null;
    nome = null;
    email = null;
    perfil = null;
  }
}