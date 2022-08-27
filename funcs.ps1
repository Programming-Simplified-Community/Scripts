$envPath = [IO.Path]::Combine($PSScriptRoot, "..", ".env")
$defaultVarPath = [IO.Path]::Combine($PSScriptRoot, "..", ".defaults")

function loadEnvFile()
{
    foreach($line in Get-Content $envPath)
    {
        $split = $line -split '='
        [System.Environment]::SetEnvironmentVariable($split[0], $split[1])
    }
}

function createEnv()
{
    param(
        [Parameter()][Hashtable]$params,
        [Parameter()][Boolean]$append=$False,
        [Parameter()][string]$defaultSettingsFile=$null,
        [Parameter()][string]$saveTo=$null,
        [Parameter()][Boolean]$allowDefaults=$False
    )
    
    # use default settings file if we didn't provide a path AND are allowing defaults
    if(([string]::IsNullOrEmpty($defaultSettingsFile)) -and $allowDefaults)
    {
        $defaultSettingsFile = $defaultVarPath
    }
    
    if([string]::IsNullOrEmpty($saveTo))
    {
        $saveTo = $envPath
    }
    
    # only if default settings file was provided shall we load it up
    if($allowDefaults -and (-not([string]::IsNullOrEmpty($defaultSettingsFile))) -and (Test-Path $defaultSettingsFile))
    {
        foreach($line in Get-Content $defaultSettingsFile)
        {
            $split = $line -split '='
            
            # only give value IF we didn't manually set it
            if(-not ($params.ContainsKey($split[0])))
            {
                $params[$split[0]] = $split[1]
            }
        }
    }
    
    # create file if not exists
    if((-not([string]::IsNullOrEmpty($saveTo))) -and -not (Test-Path $saveTo))
    {
        New-Item $envPath
    }
    
    if(-not $append)
    {
        Remove-Item $saveTo
        New-Item $saveTo
    }
    
    foreach($key in $params.Keys)
    {
        $val = $params["$key"]
        Add-Content $saveTo "$key=$val"
    }
}

function getContainerHealth()
{
    param(
        [Parameter()][string]$containerName,
        [Parameter()][Int32]$attempts=10,
        [Parameter()][Int32]$waitInterval=5
    )
    
    $check = $False

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

function startDb()
{
    param(
        [Parameter()][string]$composeFolder,
        [Parameter()][string]$serviceName,
        [Parameter()][string]$projectFolder,
        [Parameter()][string]$image="mysql:latest"
    )
    
    if([string]::IsNullOrEmpty($image))
    {
        Write-Output "Invalid image '$image'"
        exit
    }
    
    $currentPath = $PWD
    Write-Output "Pulling $image"
    docker pull $image
    
    Write-Output "Starting $serviceName..."
    docker-compose --env-file "$envPath" up -d "$serviceName"
    
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

function resetDb()
{
    param(
        [Parameter()][string]$composeFolder,
        [Parameter()][string]$serviceName,
        [Parameter()][string]$projectFolder,
        [Parameter()][string]$envPathName="DB_PATH",
        [Parameter()][string]$image="mysql:latest"
    )
    
    loadEnvFile
    $currentPath = $PWD

    Write-Output "Changing Context: $composeFolder"
    cd $composeFolder
    Write-Output "Tearing down $serviceName..."
    docker-compose --env-file "$envPath" rm -svf $serviceName
    
    $path = [System.Environment]::GetEnvironmentVariable($envPathName)
    
    if([string]::IsNullOrEmpty($path))
    {
        Write-Output "Oops. $envPathName -- Was unable to locate $path..."
        exit
    }
    
    if(Test-Path $path)
    {
        Write-Output "Cleaning up $path.."
        Remove-Item -Recurse $path    
    }
    
    startDb -composeFolder $composeFolder -serviceName $serviceName -projectFolder $projectFolder -image $image
    
    cd $currentPath
}

# example of using createEnv
#createEnv @{ dbPath = "meow\meow\meow"; dbPass = "testing123"}