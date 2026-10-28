/// Origem de um dado do projeto de irrigação por sulcos.
///
/// A ordem dos valores não é usada na persistência; apenas [Enum.name] é
/// serializado. Não renomeie os valores sem migrar os cenários salvos.
enum ProvenienciaDado {
  naoInformado,
  ilustrativo,
  informado,
  medido,
  calculado,
}
