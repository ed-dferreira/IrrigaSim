import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/features/authentication/providers.dart';
import 'perfil_view_model.dart';
import '../data/tamanho_fonte.dart';

const String _versaoApp = '1.0.0';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      ref.read(perfilProvider.notifier).sincronizarCom(authState.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final perfilState = ref.watch(perfilProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final viewModel = ref.read(perfilProvider.notifier);

    ref.listen<AuthState>(authProvider, (prev, next) {
      viewModel.sincronizarCom(next.user);
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meu perfil',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 16),

              // Card do perfil
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _AvatarUsuario(
                        fotoUrl: user?.photoUrl,
                        nome: user?.nome ?? '',
                      ),
                      const SizedBox(height: 12),
                      if (perfilState.editando) ...[
                        _CampoEdicao(
                          label: 'Nome',
                          value: perfilState.nome,
                          onChanged: viewModel.atualizarNome,
                        ),
                        const SizedBox(height: 12),
                        _CampoEdicao(
                          label: 'Instituição',
                          value: perfilState.instituicao,
                          onChanged: viewModel.atualizarInstituicao,
                        ),
                        const SizedBox(height: 12),
                        _CampoEdicao(
                          label: 'Curso',
                          value: perfilState.curso,
                          onChanged: viewModel.atualizarCurso,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: viewModel.cancelarEdicao,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: viewModel.salvarEdicao,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Salvar'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          user?.nome ?? 'Usuário',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (user?.instituicao != null &&
                            user!.instituicao!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${user.instituicao} • ${user.curso ?? ''}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: viewModel.iniciarEdicao,
                          child: Text(
                            '✏️ Editar perfil',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Estatísticas
              _SecaoTitulo('Estatísticas'),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CartaoEstatistica(
                          valor: perfilState.totalSimulacoes.toString(),
                          rotulo: 'Simulações salvas',
                          icone: AppIcons.estatisticas,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CartaoEstatistica(
                          valor: perfilState.metodoFavorito ?? '—',
                          rotulo: 'Método favorito',
                          icone: AppIcons.simulations,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Acessibilidade
              _SecaoTitulo('Acessibilidade'),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Column(
                  children: [
                    _ConfigSwitchRow(
                      titulo: 'Tema escuro',
                      descricao: 'Reduz o brilho da tela',
                      icone: AppIcons.temaEscuro,
                      checked: perfilState.temaEscuro,
                      onCheckedChange: viewModel.alternarTemaEscuro,
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _ConfigSwitchRow(
                      titulo: 'Alto contraste',
                      descricao: 'Maximiza o contraste de textos e superfícies',
                      icone: AppIcons.altoContraste,
                      checked: perfilState.altoContraste,
                      onCheckedChange: viewModel.alternarAltoContraste,
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _ConfigSwitchRow(
                      titulo: 'Texto em negrito',
                      descricao: 'Engrossa todos os textos do app',
                      icone: AppIcons.textoNegrito,
                      checked: perfilState.textoNegrito,
                      onCheckedChange: viewModel.alternarTextoNegrito,
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _ConfigSwitchRow(
                      titulo: 'Animações reduzidas',
                      descricao: 'Diminui transições e movimentos na tela',
                      icone: AppIcons.animacoesReduzidas,
                      checked: perfilState.animacoesReduzidas,
                      onCheckedChange: viewModel.alternarAnimacoesReduzidas,
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _ConfigSwitchRow(
                      titulo: 'Modo leitor de tela',
                      descricao: 'Amplia descrições para leitores de tela',
                      icone: AppIcons.leitorDeTela,
                      checked: perfilState.modoLeitorTela,
                      onCheckedChange: viewModel.alternarModoLeitorTela,
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _ControleTamanhoFonte(
                      tamanhoSelecionado: perfilState.tamanhoFonte,
                      onSelecionar: viewModel.definirTamanhoFonte,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sobre
              _SecaoTitulo('Sobre'),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _LinhaInfo(
                        label: 'Versão',
                        valor: _versaoApp,
                      ),
                      const SizedBox(height: 12),
                      _LinhaInfo(
                        label: 'Desenvolvido por',
                        valor: 'UFLA/DEG',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Modelos: Kostiakov-Lewis + Balanço de Volume',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          // TODO: Abrir URL
                        },
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.abrirChangelog,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Novidades da versão $_versaoApp',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão de sair
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sair da conta',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarUsuario extends StatelessWidget {
  final String? fotoUrl;
  final String nome;

  const _AvatarUsuario({this.fotoUrl, required this.nome});

  @override
  Widget build(BuildContext context) {
    final iniciais = nome.trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join('');
    final displayIniciais = iniciais.isEmpty ? '?' : iniciais;

    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayIniciais,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.primary,
            fontSize: 32,
          ),
        ),
      ),
    );
  }
}

class _CampoEdicao extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _CampoEdicao({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String texto;

  const _SecaoTitulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        texto,
        style: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onBackground,
        ),
      ),
    );
  }
}

class _CartaoEstatistica extends StatelessWidget {
  final String valor;
  final String rotulo;
  final IconData icone;

  const _CartaoEstatistica({
    required this.valor,
    required this.rotulo,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icone,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            rotulo,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ConfigSwitchRow extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final bool checked;
  final ValueChanged<bool> onCheckedChange;

  const _ConfigSwitchRow({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.checked,
    required this.onCheckedChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icone, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  descricao,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: checked,
            onChanged: onCheckedChange,
          ),
        ],
      ),
    );
  }
}

class _ControleTamanhoFonte extends StatelessWidget {
  final TamanhoFonte tamanhoSelecionado;
  final ValueChanged<TamanhoFonte> onSelecionar;

  const _ControleTamanhoFonte({
    required this.tamanhoSelecionado,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final opcoes = TamanhoFonte.values;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.tamanhoFonte, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tamanho da fonte',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Ajusta o texto em todo o app',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: tamanhoSelecionado.index.toDouble(),
            onChanged: (valor) {
              final indice = valor.toInt().clamp(0, opcoes.length - 1);
              onSelecionar(opcoes[indice]);
            },
            min: 0,
            max: (opcoes.length - 1).toDouble(),
            divisions: opcoes.length - 1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: opcoes.map((opcao) {
              final ativo = opcao == tamanhoSelecionado;
              return Text(
                opcao.label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                  color: ativo ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final String label;
  final String valor;

  const _LinhaInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurface),
        ),
        Text(
          valor,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
