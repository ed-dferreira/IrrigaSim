import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/authentication/providers.dart';

import '../data/tamanho_fonte.dart';
import 'perfil_view_model.dart';

const _appVersion = '1.0.0';

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
      ref
          .read(perfilProvider.notifier)
          .sincronizarCom(ref.read(authProvider).user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(perfilProvider);
    final user = ref.watch(authProvider).user;
    final viewModel = ref.read(perfilProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    ref.listen<AuthState>(
      authProvider,
      (_, next) => viewModel.sincronizarCom(next.user),
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Perfil e preferências',
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gerencie sua conta e adapte o IrrigaSim ao seu jeito.',
                        style: text.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _ProfileCard(
                        name: user?.nome ?? 'Usuário',
                        email: user?.email ?? '',
                        institution: user?.instituicao,
                        course: user?.curso,
                        photoUrl: user?.photoUrl,
                        profile: profile,
                        viewModel: viewModel,
                      ),
                      const SizedBox(height: 16),
                      _StatisticsGrid(profile: profile),
                      const SizedBox(height: 28),
                      Semantics(
                        header: true,
                        child: Text(
                          'Preferências',
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, inner) {
                          final preferences = _PreferencesCard(
                            profile: profile,
                            viewModel: viewModel,
                          );
                          final about = _AboutCard(
                            onLogout: () =>
                                ref.read(authProvider.notifier).logout(),
                          );
                          if (inner.maxWidth < 820) {
                            return Column(
                              children: [
                                preferences,
                                const SizedBox(height: 16),
                                about,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: preferences),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: about),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? institution;
  final String? course;
  final String? photoUrl;
  final PerfilState profile;
  final PerfilViewModel viewModel;
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.institution,
    required this.course,
    required this.photoUrl,
    required this.profile,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Dados do perfil de $name',
      child: Card(
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: profile.editando
              ? _EditProfile(profile: profile, viewModel: viewModel)
              : _ProfileSummary(
                  name: name,
                  email: email,
                  institution: institution,
                  course: course,
                  photoUrl: photoUrl,
                  onEdit: viewModel.iniciarEdicao,
                ),
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final String name;
  final String email;
  final String? institution;
  final String? course;
  final String? photoUrl;
  final VoidCallback onEdit;
  const _ProfileSummary({
    required this.name,
    required this.email,
    required this.institution,
    required this.course,
    required this.photoUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final avatar = _UserAvatar(name: name, photoUrl: photoUrl);
        final details = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: text.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
              textAlign: compact ? TextAlign.center : TextAlign.start,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: text.bodyMedium?.copyWith(
                  color: colors.onPrimaryContainer.withValues(alpha: .78),
                ),
                textAlign: compact ? TextAlign.center : TextAlign.start,
              ),
            ],
            if (institution != null && institution!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 17,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      [institution, course]
                          .whereType<String>()
                          .where((v) => v.isNotEmpty)
                          .join(' • '),
                      style: text.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
        final edit = OutlinedButton.icon(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onPrimaryContainer,
            side: BorderSide(
              color: colors.onPrimaryContainer.withValues(alpha: .5),
            ),
          ),
          icon: const Icon(AppIcons.editarPerfil),
          label: const Text('Editar perfil'),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: avatar),
              const SizedBox(height: 16),
              details,
              const SizedBox(height: 20),
              edit,
            ],
          );
        }
        return Row(
          children: [
            avatar,
            const SizedBox(width: 20),
            Expanded(child: details),
            const SizedBox(width: 20),
            edit,
          ],
        );
      },
    );
  }
}

class _EditProfile extends StatelessWidget {
  final PerfilState profile;
  final PerfilViewModel viewModel;
  const _EditProfile({required this.profile, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editar informações',
          style: text.titleLarge?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        _EditField(
          label: 'Nome',
          value: profile.nome,
          onChanged: viewModel.atualizarNome,
        ),
        const SizedBox(height: 12),
        _EditField(
          label: 'Instituição',
          value: profile.instituicao,
          onChanged: viewModel.atualizarInstituicao,
        ),
        const SizedBox(height: 12),
        _EditField(
          label: 'Curso',
          value: profile.curso,
          onChanged: viewModel.atualizarCurso,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: viewModel.cancelarEdicao,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: viewModel.salvarEdicao,
                child: const Text('Salvar alterações'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _EditField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value,
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label),
  );
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _UserAvatar({required this.name, required this.photoUrl});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Semantics(
      image: true,
      label: 'Foto de perfil de $name',
      child: CircleAvatar(
        radius: 43,
        backgroundColor: colors.onPrimaryContainer.withValues(alpha: .12),
        foregroundImage: photoUrl == null || photoUrl!.isEmpty
            ? null
            : NetworkImage(photoUrl!),
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  final PerfilState profile;
  const _StatisticsGrid({required this.profile});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Semantics(
          label:
              '${profile.totalSimulacoes} simulações salvas. Método favorito: ${profile.metodoFavorito ?? 'ainda não definido'}',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: _StatCard(
                  value: profile.totalSimulacoes.toString(),
                  label: 'Simulações salvas',
                  icon: AppIcons.estatisticas,
                  primary: true,
                ),
              ),
              SizedBox(
                width: width,
                child: _StatCard(
                  value: profile.metodoFavorito ?? '—',
                  label: 'Método favorito',
                  icon: AppIcons.simulations,
                  primary: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool primary;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.primary,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = primary
        ? colors.onSecondaryContainer
        : colors.onTertiaryContainer;
    return Card(
      color: primary ? colors.secondaryContainer : colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: foreground),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: foreground.withValues(alpha: .78)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final PerfilState profile;
  final PerfilViewModel viewModel;
  const _PreferencesCard({required this.profile, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _PreferenceSwitch(
            title: 'Tema escuro',
            description: 'Usa a paleta grafite e esmeralda',
            icon: AppIcons.temaEscuro,
            value: profile.temaEscuro,
            onChanged: viewModel.alternarTemaEscuro,
          ),
          const _InsetDivider(),
          _PreferenceSwitch(
            title: 'Alto contraste',
            description: 'Aumenta a separação entre elementos',
            icon: AppIcons.altoContraste,
            value: profile.altoContraste,
            onChanged: viewModel.alternarAltoContraste,
          ),
          const _InsetDivider(),
          _PreferenceSwitch(
            title: 'Texto em negrito',
            description: 'Reforça o peso de todos os textos',
            icon: AppIcons.textoNegrito,
            value: profile.textoNegrito,
            onChanged: viewModel.alternarTextoNegrito,
          ),
          const _InsetDivider(),
          _PreferenceSwitch(
            title: 'Reduzir animações',
            description: 'Diminui movimentos e transições',
            icon: AppIcons.animacoesReduzidas,
            value: profile.animacoesReduzidas,
            onChanged: viewModel.alternarAnimacoesReduzidas,
          ),
          const _InsetDivider(),
          _PreferenceSwitch(
            title: 'Leitor de tela',
            description: 'Fornece descrições mais detalhadas',
            icon: AppIcons.leitorDeTela,
            value: profile.modoLeitorTela,
            onChanged: viewModel.alternarModoLeitorTela,
          ),
          const _InsetDivider(),
          _FontSizeControl(
            value: profile.tamanhoFonte,
            onChanged: viewModel.definirTamanhoFonte,
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PreferenceSwitch({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      toggled: value,
      label: '$title. $description',
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: colors.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  final TamanhoFonte value;
  final ValueChanged<TamanhoFonte> onChanged;
  const _FontSizeControl({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final options = TamanhoFonte.values;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  AppIcons.tamanhoFonte,
                  color: colors.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tamanho da fonte',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Ajusta o texto em todo o aplicativo',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value.index.toDouble(),
            min: 0,
            max: (options.length - 1).toDouble(),
            divisions: options.length - 1,
            label: value.label,
            onChanged: (next) =>
                onChanged(options[next.round().clamp(0, options.length - 1)]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: options.map((option) {
              final selected = option == value;
              return Text(
                option.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 20, endIndent: 20);
}

class _AboutCard extends StatelessWidget {
  final VoidCallback onLogout;
  const _AboutCard({required this.onLogout});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: colors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Sobre o IrrigaSim',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Apoio à aprendizagem e à simulação de irrigação por superfície.',
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const _InfoRow(label: 'Versão', value: _appVersion),
                const SizedBox(height: 12),
                const _InfoRow(label: 'Desenvolvido por', value: 'UFLA/DEG'),
                const SizedBox(height: 12),
                const _InfoRow(label: 'Modelos', value: 'Kostiakov–Lewis'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair da conta'),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar seus dados sincronizados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onLogout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
