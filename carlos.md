# Build e deploy (fork Carloslauriano/chatwoot)

## Comando de build

```bash
docker buildx build \
  -t southamerica-east1-docker.pkg.dev/sistema-ram/sistemaram/chatwoot:v4.20.0 \
  -f docker/Dockerfile \
  --cache-from=type=registry,ref=southamerica-east1-docker.pkg.dev/sistema-ram/sistemaram/chatwoot:buildcache \
  --cache-to=type=registry,ref=southamerica-east1-docker.pkg.dev/sistema-ram/sistemaram/chatwoot:buildcache,mode=max \
  --provenance=false \
  --push \
  .
```

Troque a tag (`v4.20.0`) a cada release. `--push` já envia ao Artifact Registry.

## Antes de subir (checklist)

1. **Árvore limpa e sincronizada**: `git status` sem pendências, `develop` == `origin/develop`. A imagem é construída do working tree, não do commit.
2. **Auth no registry**: `gcloud auth configure-docker southamerica-east1-docker.pkg.dev`.
3. **Versão/tag**: `VERSION_CW`, `package.json` e `config/app.yml` estão em `4.20.0`, igual à tag do build. Nunca reutilize uma tag já em produção.
4. **Gemfile.lock e schema.rb**: após merge com upstream, rodar `bundle install` e `bin/rails db:migrate` e conferir que não geram diff (resolvidos à mão no merge de 17/11).
5. **Migrations novas**: `ls db/migrate | tail` e comparar com o que já rodou em produção. Rodar `bin/rails db:migrate` no deploy (ou job de migração) ANTES de subir o app novo.
6. **Backup do banco** antes de migrations pesadas (upstream traz índices em `contact_inboxes`, `data_exports`, `conversations`).
7. **Teste local da imagem**: subir com `docker run`/compose apontando para um banco de teste e checar `/api` e o login.
8. **Customizações do fork**: abrir tickets (kanban, timer), MCP de tickets (`POST /accounts/:id/mcp`), config MCP no perfil, e o nome de contato não sobrescrito pelo canal API.
9. **Variáveis de ambiente**: conferir novas envs exigidas pelo upstream (ex.: webhooks Meta agora exigem verify token e assinatura; Instagram login unificado).
10. **Rollback**: anote a tag atual em produção antes do deploy para voltar rápido. Branches `backup/develop-pre-upstream-merge-*` guardam o estado pré-merge.
11. **Cache**: se o build ficar estranho, rode uma vez sem `--cache-from` para descartar cache corrompido.
12. **Depois do deploy**: olhar logs do web e do sidekiq (erros de migration, jobs falhando) e testar um fluxo de ticket e uma conversa.

## Sincronizar com upstream

```bash
git fetch upstream develop
git branch backup/develop-pre-upstream-merge-$(date +%F) develop
git merge upstream/develop      # nunca rebase/reset/force: preserva seus commits
```
