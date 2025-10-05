<#!
.SYNOPSIS
  Developer convenience commands for common backend tasks.

.DESCRIPTION
  Wraps docker-compose + container exec flows for Windows PowerShell.

.EXAMPLES
  ./scripts/dev.ps1 up
  ./scripts/dev.ps1 seed
  ./scripts/dev.ps1 smoke
#>
param(
    [Parameter(Position = 0)][string]$Command = "help"
)

function Invoke-Compose {
    param([string[]]$ComposeArgs)
    write-host "[docker-compose] $ComposeArgs" -ForegroundColor Cyan
    docker-compose @ComposeArgs
    if ($LASTEXITCODE -ne 0) { throw "docker-compose failed ($LASTEXITCODE)" }
}

switch ($Command) {
    'up' {
        Invoke-Compose -ComposeArgs @('up', '-d', '--build')
    }
    'down' {
        Invoke-Compose -ComposeArgs @('down', '-v')
    }
    'logs' {
        Invoke-Compose -ComposeArgs @('logs', '-f', 'api')
    }
    'migrate' {
        Invoke-Compose -ComposeArgs @('exec', 'api', 'alembic', 'upgrade', 'head')
    }
    'seed' {
        Invoke-Compose -ComposeArgs @('exec', 'api', 'python', '-m', 'scripts.seed_minimal_data')
    }
    'reset' {
        Invoke-Compose -ComposeArgs @('exec', 'api', 'python', 'scripts/reset_database.py', '--seed')
    }
    'smoke' {
        Invoke-Compose -ComposeArgs @('exec', 'api', 'python', 'scripts/smoke_test_api.py')
    }
    'psql' {
        Invoke-Compose -ComposeArgs @('exec', 'postgres', 'psql', '-U', 'lostfound', '-d', 'lostfound')
    }
    'beatlogs' {
        Invoke-Compose -ComposeArgs @('logs', '-f', 'worker-beat')
    }
    default {
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  up       - build and start stack"
        Write-Host "  down     - stop and remove stack (volumes)" 
        Write-Host "  migrate  - run alembic upgrade head"
        Write-Host "  seed     - run seed script"
        Write-Host "  reset    - full DB reset + seed"
        Write-Host "  smoke    - run API smoke test"
        Write-Host "  logs     - tail api logs"
        Write-Host "  psql     - open psql shell"
        Write-Host "  beatlogs - tail celery beat (MV refresh)"
        exit 0
    }
}
