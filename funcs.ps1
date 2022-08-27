$envPath = [IO.Path]::Combine($PSScriptRoot, "..", ".env")

function loadEnvFile()
{
    foreach($line in Get-Content $envPath)
    {
        $split = $line -split '='
        [System.Environment]::SetEnvironmentVariable($split[0], $split[1])
    }
}

function createEnv([Hashtable]$params, [Boolean]$append=$false)
{
    # create file if not exists
    if(-not (Test-Path $envPath))
    {
        New-Item $envPath
    }
    
    if(-not $append)
    {
        Remove-Item $envPath
        New-Item $envPath
    }
    
    foreach($key in $params.Keys)
    {
        $val = $params["$key"]
        Add-Content $envPath "$key=$val"
    }
}

function getContainerHealth([string]$containerName, [Int32]$attempts=10, [Int32]$waitInterval=5)
{
    $check = $false

    while($attempts -gt 0 -and (-not $check))
    {
        Write-Output "Waiting for $containerName container to be healthy..."
        [string]$state = $(docker container inspect $containerName)
        $check = $state -match 'healthy'

        if($check)
        {
            break
        }

        $attempts = $attempts -= 1
        Write-Output "Waiting $waitInterval seconds..."
        Start-Sleep $waitInterval
    }
    
    return $check
}

function startDb([string]$composeFolder, [string]$serviceName, [string]$projectFolder, [string]$image = "mysql:latest")
{
    $currentPath = $PWD
    Write-Output "Pulling $image"
    docker pull $image
    
    Write-Output "Starting $serviceName..."
    docker-compose --env-file $envPath up -d $serviceName
    
    if(-not (getContainerHealth $serviceName))
    {
        Write-Output "Something is wrong with $serviceName. Unable to perform migrations..."
        exit
    }
    
    cd $projectFolder
    Write-Output "Running migrations..."
    dotnet ef database update
    
    cd $currentPath
    Write-Output "Complete..."
}

function resetDb([string]$composeFolder, [string]$serviceName, [string]$projectFolder, [string]$envPathName = "DB_PATH", [string]$image="mysql:latest")
{
    loadEnvFile
    $currentPath = $PWD
    
    cd $composeFolder
    Write-Output "Tearing down $serviceName..."
    docker-compose down $serviceName
    
    $path = [System.Environment]::GetEnvironmentVariable($envPathName)
    
    if(-not(Test-Path $path))
    {
        Write-Output "Oops. Was unable to locate $path..."
        exit
    }
    
    Write-Output "Cleaning up $path.."
    Remove-Item -Recurse $path
    
    startDb -composeFolder $composeFolder -serviceName $serviceName -projectFolder $projectFolder -image $image
    
    cd $currentPath
}

# example of using createEnv
#createEnv @{ dbPath = "meow\meow\meow"; dbPass = "testing123"}