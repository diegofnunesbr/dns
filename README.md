# dns

Gerencia os registros DNS do domínio `diegofnunesbr.com` no Cloudflare
via Terraform/Terragrunt - inspirado no padrão real da empresa
(`iac/oracle/.../dns`): registros declarados em YAML, não um `resource`
por registro, com o nome da pasta sendo o próprio domínio.

Diferenças em relação ao padrão da empresa: aqui é Cloudflare (não OCI
DNS), Terraform puro (não OpenTofu, pra ficar consistente com o
repositório `terraform` existente), backend local (não GitLab HTTP
backend) e sem a separação por categoria de zona (`public/private/
parking/subdomain`) - só uma zona por enquanto.

## Pré-requisitos

- Terraform >= 1.5 e Terragrunt >= 0.60
- Um API Token do Cloudflare com escopo `DNS Write` restrito à zona
  `diegofnunesbr.com` (não a Global API Key) - ver
  [dashboard do Cloudflare](https://dash.cloudflare.com/profile/api-tokens)

## Estrutura do repositório

```text
dns/
├── modules/
│   └── cloudflare/
│       └── zone/                 # módulo reutilizável: 1 zona + N registros
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── diegofnunesbr.com/             # nome da pasta = nome da zona
│   ├── terragrunt.hcl
│   └── records.yaml               # registros dessa zona
└── terragrunt.hcl                 # root: backend + provider Cloudflare
```

## Formato do `records.yaml`

Uma lista de objetos, um por registro:

```yaml
- type: A
  name: "@"
  content: "203.0.113.10"
- type: A
  name: vpn
  content: "203.0.113.10"
  proxied: false
- type: CNAME
  name: www
  content: "diegofnunesbr.com"
  proxied: true
- type: TXT
  name: "@"
  content: "v=spf1 -all"
- type: MX
  name: "@"
  content: "mail.example.com"
  priority: 10
  ttl: 3600
```

Campos: `type` e `name` (`@` pra raiz da zona) e `content` são
obrigatórios. `ttl` default `1` (= "Auto" no Cloudflare). `proxied`
default `false`, só vale pra `A`/`AAAA`/`CNAME` (liga o proxy
laranja do Cloudflare). `priority` só é necessário pra `MX`/`SRV`/`URI`.

Múltiplos registros `TXT` no mesmo `name` (ex.: SPF + verificação de
domínio) são só duas entradas na lista, cada uma com seu `content`.

## Token do Cloudflare (uma vez por máquina)

Mesmo modelo usado no repositório de DNS da empresa (lá com
`TF_VAR_BACKEND_USER`/`TF_VAR_BACKEND_PASSWORD`): a credencial fica
exportada no `~/.bashrc` de quem roda, nunca no repositório. Rode uma vez,
colando o token quando pedir (não aparece na tela nem no histórico):

```bash
read -rsp "Token Cloudflare: " T; echo
printf 'export CLOUDFLARE_API_TOKEN=%q\n' "$T" >> ~/.bashrc; unset T
chmod 600 ~/.bashrc
. ~/.bashrc
```

O `root.hcl` exige a variável (`get_env("CLOUDFLARE_API_TOKEN")`): sem ela,
o terragrunt para logo no início com "Required environment variable
CLOUDFLARE_API_TOKEN - not found", em vez de um 403 da API do Cloudflare.
O provider lê a variável direto do ambiente, então o token não é gravado
em nenhum arquivo gerado (`provider.tf`, `.terragrunt-cache`). Token
trocado no Cloudflare? Edite a linha no `~/.bashrc`.

## Uso

```bash
cd diegofnunesbr.com
terragrunt init
terragrunt plan
terragrunt apply
```

## Adicionar uma zona nova

1. Crie uma pasta com o nome exato do domínio (ex.: `outrodominio.com/`).
2. Copie `diegofnunesbr.com/terragrunt.hcl` como está (não precisa
   editar nada, o nome da zona vem do nome da pasta).
3. Crie o `records.yaml` dessa pasta com os registros da zona nova.
4. `cd outrodominio.com && terragrunt init && terragrunt apply`.
