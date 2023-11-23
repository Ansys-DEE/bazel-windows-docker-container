# FROM mcr.microsoft.com/windows/servercore:ltsc2019
# Bare Windows 10 with .NET Framework:
# FROM mcr.microsoft.com/windows:10.0.17763.5122-amd64
FROM mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019 AS build

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue'; $verbosePreference='Continue';"]

# Install Chocolatey
ENV chocolateyVersion=2.2.0
RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); \
   $Env:PATH+=';'+$Env:ALLUSERSPROFILE+'\chocolatey\bin'

# Install Visual Studio build tools
RUN choco install visualstudio2019buildtools -y 
# VCTools, required and recommended by default:
# https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2019
RUN choco install visualstudio2019-workload-vctools -y

# Install msys2
# Deleting Recycle.Bin to overcome hang after installing msys2:
# https://github.com/microsoft/hcsshim/issues/696
RUN choco install msys2 -y ; \
   Remove-Item -Path 'C:\$Recycle.Bin' -Recurse -Force 

# Setup environment for msys2
RUN $Env:BAZEL_SH += 'C:\tools\msys64\usr\bin\bash.exe'; \
   $Env:PATH += ';C:\tools\msys64\usr\bin'; \
   [Environment]::SetEnvironmentVariable('BAZEL_SH', $Env:BAZEL_SH, 'User'); \
   [Environment]::SetEnvironmentVariable('PATH', $Env:PATH, 'User')

# Install msys2 packages required by Bazel
RUN function msys() { C:\tools\msys64\usr\bin\bash.exe @('-lc') + @Args; } \
   msys 'pacman --noconfirm -S zip unzip patch diffutils git';

# ##Install Git and posh-git for advanced repo operations
# #https://hub.docker.com/r/ehong/git-windows-server
# # Install Git
# RUN choco install git.install -y 

# Install NuGet provider
#RUN Install-PackageProvider -Name NuGet -Force -Scope AllUsers -RequiredVersion 2.8.5.201 -ErrorAction Stop
# Set the PSGallery as a trusted repository
#RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
# Install posh-git (this likes to fail intermittently)
#RUN Install-Module -Name 'posh-git'

# Install bazelisk
RUN choco install bazelisk -y

# Test installation by compiling hello-world example (not working, complains about missing build tools)
RUN git clone https://github.com/bazelbuild/bazel 
RUN cd bazel && bazel build //examples/cpp:hello-world
