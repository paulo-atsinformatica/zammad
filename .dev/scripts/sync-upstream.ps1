# Script de sincronização com o repositório original (Zammad)
# Uso: .\.dev\scripts\sync-upstream.ps1 [-UpstreamBranch develop] [-DryRun]
# Requer: estar na raiz do repositório (source), remote "upstream" configurado

param(
    [string]$UpstreamBranch = "develop",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repoRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName

Write-Host "=== Sync Upstream Zammad ===" -ForegroundColor Cyan
Write-Host "Repositório: $repoRoot"
Write-Host "Branch upstream: $UpstreamBranch"
if ($DryRun) { Write-Host "Modo DRY RUN - nenhuma alteração será feita." -ForegroundColor Yellow }
Write-Host ""

Push-Location $repoRoot

try {
    # 1. Verificar se há alterações não commitadas
    $status = git status --porcelain
    if ($status) {
        Write-Host "ERRO: Há alterações não commitadas. Faça commit ou stash antes de sincronizar." -ForegroundColor Red
        git status -sb
        exit 1
    }

    # 2. Verificar se remote upstream existe
    $remotes = git remote
    if ($remotes -notcontains "upstream") {
        Write-Host "ERRO: Remote 'upstream' não configurado. Adicione com:" -ForegroundColor Red
        Write-Host "  git remote add upstream https://github.com/zammad/zammad.git"
        exit 1
    }

    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "Branch atual: $currentBranch"
    $backupName = "backup-ats-antes-sync-$(Get-Date -Format 'yyyyMMdd-HHmm')"
    Write-Host ""

    if (-not $DryRun) {
        Write-Host "1. Buscando alterações do upstream..." -ForegroundColor Green
        git fetch upstream
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        Write-Host "2. Criando branch de backup: $backupName" -ForegroundColor Green
        git branch $backupName
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        Write-Host "3. Fazendo merge de upstream/$UpstreamBranch em $currentBranch..." -ForegroundColor Green
        git merge "upstream/$UpstreamBranch" -m "Sync upstream $UpstreamBranch - manter customizações ATS"
        $mergeExit = $LASTEXITCODE

        if ($mergeExit -eq 0) {
            Write-Host ""
            Write-Host "Merge concluído com sucesso." -ForegroundColor Green
            Write-Host "Próximos passos: rodar testes, db:migrate se necessário, rebuild de assets."
            Write-Host "Depois: git push origin $currentBranch"
        } else {
            Write-Host ""
            Write-Host "Há CONFLITOS. Resolva manualmente." -ForegroundColor Yellow
            Write-Host "Arquivos em conflito:"
            git diff --name-only --diff-filter=U
            Write-Host ""
            Write-Host "Consulte .dev/sync-upstream-guide.md - seção 4 para saber em quais arquivos manter as alterações ATS (ours)."
            Write-Host "Após resolver: git add <arquivos> e git commit"
            Write-Host "Para abortar: git merge --abort"
            Write-Host "Para voltar ao estado anterior: git reset --hard $backupName"
            exit $mergeExit
        }
    } else {
        Write-Host "[DRY RUN] Seria executado:" -ForegroundColor Gray
        Write-Host "  git fetch upstream"
        Write-Host "  git branch $backupName"
        Write-Host "  git merge upstream/$UpstreamBranch -m \"Sync upstream $UpstreamBranch - manter customizações ATS\""
        Write-Host ""
        Write-Host "Para executar de verdade, rode sem -DryRun."
    }
} finally {
    Pop-Location
}
