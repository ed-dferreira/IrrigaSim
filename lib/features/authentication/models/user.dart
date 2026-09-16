class User {
  final String uid;
  final String? nome;
  final String? email;
  final String? photoUrl;
  final String? instituicao;
  final String? curso;
  final DateTime? dataCriacao;

  const User({
    required this.uid,
    this.nome,
    this.email,
    this.photoUrl,
    this.instituicao,
    this.curso,
    this.dataCriacao,
  });
}
