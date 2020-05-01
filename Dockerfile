FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 as prepare

# gather only artifacts necessary for nuget restore, retaining directory structure
COPY . C:/temp
RUN Invoke-Expression 'robocopy C:/temp C:/nuget /s /ndl /njh /njs nuget.config *.sln *.csproj packages.config'

FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 as build

# setup
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    NUGET_XMLDOC_MODE=skip

ARG CONFIGURATION=Release

WORKDIR C:\\workspace

# trigger dotnet first run experience by running arbitrary command
RUN dotnet help | Out-Null

# restore packages from artifacts produced in the prepare stage
COPY --from=prepare C:/nuget .
RUN msbuild -t:Restore -p:RestorePackagesConfig=true -m -v:m -noLogo

# copy source
COPY src/ ./src/

# build and publish website project
RUN msbuild -t:Build -p:Configuration=$($env:CONFIGURATION) -p:PublishUrl='C:\\out\\Website' -p:DeployOnBuild=True -p:DeployDefaultTarget=WebPublish -p:WebPublishMethod=FileSystem -p:CollectWebConfigsToTransform=False -p:TransformWebConfigEnabled=False -p:AutoParameterizationWebConfigConnectionStrings=False -m -v:m -noLogo ./src/Project/code/Website/Website.csproj

FROM build as production

WORKDIR C:\\workspace

# copy serialized items
RUN Copy-Item -Path '.\\src\\Foundation\\serialization' -Destination 'C:\\out\\serialization\\Foundation' -Recurse -Force; \
    Copy-Item -Path '.\\src\\Feature\\serialization' -Destination 'C:\\out\\serialization\\Feature' -Recurse -Force; \
    Copy-Item -Path '.\\src\\Project\\serialization' -Destination 'C:\\out\\serialization\\Project' -Recurse -Force;
