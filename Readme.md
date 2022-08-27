# Scripts

A set of reusable scripts for our projects.

This repo is meant to be added as a submodule for any project wishing to use these scripts.

# How appropriately clone a project
When you clone a project with this as a submodule you will have to do:

```bash
git clone --recurse-submodules REPO_URL
```

If this repo is ever updated, and you wish to pull those updates. The following commands are to be utilized:

```bash
git submodule update --remote

# be sure to tell the project repo our ref has been updated
git add Scripts
git commit -m "Updated Scripts Repo Reference"
```

## loadEnvFile

This loads the `.env` file located at project root into `System.Environment`

(This assumes it is a submodule so whatever is `Scripts\..`)

## createEnv

Will either overwrite the `.env` file with incoming data, or 
append depending on the `append` flag.

Consumes a `HashTable`, saves environment variables as 
`KEYNAME=VALUE`

| Parameter Name | Purpose                                                                      | 
|----------------|------------------------------------------------------------------------------|
| params         | HashTable which contains all of the environment variables to save            |
| append         | Defaults to `false` - indicates whether we are adding to file or overwriting |

## getContainerHealth
This function takes a container name (or ID) and tries to determine whether or not it is healthy.

If the container responds as healthy within `attempts`, it will return `true`. Otherwise, `false`.

| Parameter Name | Purpose                                                               |
|----------------|-----------------------------------------------------------------------|
| containerName  | name of container, or ID in which we're checking on                   |
| attempts       | Amount of attempts to check if container is healthy. Defaults to `10` |
| waitInterval   | Time in seconds between checking. Defaults to `5`                     |

## startDb

Attempts to start a database service, then run migration scripts automatically.

| Parameter Name | Purpose                                                          |
|----------------|------------------------------------------------------------------|
| composeFolder  | Folder Path which contains the compose file to use               |
| serviceName    | name of db service to start                                      |
| projectFolder  | Path to .NET project that has our migrations                     |
| image          | Database image that our service uses. Defaults to `mysql:latest` |

## resetDb

Resets our database to a clean state

| Parameter Name | Purpose                                                                                    |
|----------------|--------------------------------------------------------------------------------------------|
| composeFolder  | Folder Path which contains the compose file to use                                         |
| serviceName    | name of db service to stop/reset                                                           |
| projectFolder  | Path to .NET project that has our migrations                                               |
| envPathName    | Environment variable key which points to where our DB is mounted to. Defaults to `DB_PATH` |
| image          | Image in which our DB service uses. Defaults to `mysql:latest`                             |
