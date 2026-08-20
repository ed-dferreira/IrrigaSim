package com.irrigasim.data

private var onboardingVistoMem = false
private var temaEscuroMem = false
private var tamanhoFonteMem = TamanhoFonte.PADRAO
private var altoContrasteMem = false
private var textoNegritoMem = false
private var animacoesReduzidasMem = false
private var modoLeitorTelaMem = false

actual object PreferenciasApp {
    actual fun onboardingVisto(): Boolean = onboardingVistoMem
    actual fun marcarOnboardingVisto() { onboardingVistoMem = true }

    actual fun temaEscuro(): Boolean = temaEscuroMem
    actual fun definirTemaEscuro(ativo: Boolean) { temaEscuroMem = ativo }

    actual fun tamanhoFonte(): TamanhoFonte = tamanhoFonteMem
    actual fun definirTamanhoFonte(tamanho: TamanhoFonte) { tamanhoFonteMem = tamanho }

    actual fun altoContraste(): Boolean = altoContrasteMem
    actual fun definirAltoContraste(ativo: Boolean) { altoContrasteMem = ativo }

    actual fun textoNegrito(): Boolean = textoNegritoMem
    actual fun definirTextoNegrito(ativo: Boolean) { textoNegritoMem = ativo }

    actual fun animacoesReduzidas(): Boolean = animacoesReduzidasMem
    actual fun definirAnimacoesReduzidas(ativo: Boolean) { animacoesReduzidasMem = ativo }

    actual fun modoLeitorTela(): Boolean = modoLeitorTelaMem
    actual fun definirModoLeitorTela(ativo: Boolean) { modoLeitorTelaMem = ativo }

    actual fun limpar() {
        onboardingVistoMem = false
        temaEscuroMem = false
        tamanhoFonteMem = TamanhoFonte.PADRAO
        altoContrasteMem = false
        textoNegritoMem = false
        animacoesReduzidasMem = false
        modoLeitorTelaMem = false
    }
}
