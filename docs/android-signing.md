# Assinatura de builds Android

O APK distribuído em Releases precisa ser assinado sempre com o mesmo keystore
para que o Android aceite atualizações sobre instalações existentes. O keystore
e suas senhas não devem ser enviados ao Git ou compartilhados publicamente.

## Criar a chave

Em uma máquina segura com o JDK instalado, execute na raiz do projeto:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias irrigasim
```

Guarde o arquivo `upload-keystore.jks`, as senhas e o alias (`irrigasim`) em
local seguro com cópia de backup. Perder essa chave impede assinar atualizações
compatíveis com as versões já instaladas.

## Configurar GitHub Actions

Converta o keystore em Base64 sem quebra de linha:

```bash
base64 -w 0 upload-keystore.jks
```

No GitHub, abra **Settings → Secrets and variables → Actions** e crie estes
repository secrets:

| Secret | Valor |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Saída do comando Base64 acima |
| `ANDROID_KEYSTORE_PASSWORD` | Senha do keystore |
| `ANDROID_KEY_ALIAS` | Alias escolhido, por exemplo `irrigasim` |
| `ANDROID_KEY_PASSWORD` | Senha da chave (pode ser igual à do keystore) |

O workflow grava temporariamente o keystore no runner, assina o APK e o AAB e
encerra a execução se algum secret estiver ausente. O keystore não é publicado
como artefato.

## Build local assinado (opcional)

Crie `android/key.properties` (já ignorado pelo Git) com:

```properties
storeFile=app/upload-keystore.jks
storePassword=SENHA_DO_KEYSTORE
keyAlias=irrigasim
keyPassword=SENHA_DA_CHAVE
```

Coloque o keystore em `android/app/upload-keystore.jks` e execute
`flutter build apk --release`. Sem `key.properties`, o build local continua
usando a assinatura debug, mas o workflow de Release exige a assinatura
configurada acima.

> O `applicationId` deve permanecer igual (`com.example.irrigasim`) para que o
> Android reconheça a nova versão como atualização do mesmo app.
