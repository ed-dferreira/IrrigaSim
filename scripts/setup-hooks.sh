#!/bin/bash

# ============================================================
# Setup Git Hooks - IrrigaSim
# ============================================================
#
# COMO FUNCIONA:
# Este script configura o Git para usar os hooks locais
# do projeto. Execute uma vez após clonar o repositório.
#
# Uso:
#   ./scripts/setup-hooks.sh
#
# Ou manualmente:
#   git config core.hooksPath .githooks
# ============================================================

echo "🔧 Configurando Git Hooks para IrrigaSim..."

# Verifica se está no diretório correto
if [ ! -d ".githooks" ]; then
    echo "❌ Erro: Execute este script na raiz do repositório."
    exit 1
fi

# Configura o Git para usar os hooks locais
git config core.hooksPath .githooks

echo "✅ Hooks configurados com sucesso!"
echo ""
echo "📌 O hook 'commit-msg' verificará suas mensagens de commit."
echo "   Formato esperado: <type>(<scope>): <description>"
echo ""
echo "   Tipos: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
echo ""
echo "📝 Exemplos:"
echo "   git commit -m 'feat(auth): adiciona login com Google'"
echo "   git commit -m 'fix: corrige crash na tela de irrigação'"
echo "   git commit -m 'docs: atualiza README'"
echo ""
echo "⚡ Para ignorar o hook (não recomendado):"
echo "   git commit --no-verify -m 'sua mensagem'"
echo ""
