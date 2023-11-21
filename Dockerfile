FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Install Chocolatey
ENV chocolateyVersion=1.4.0
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

# Install msys2 (possibly included with choco bazel install?)
RUN choco install -y msys2

# Install Microsoft Visual C++ Redistributable for Visual Studio using Chocolatey
#RUN choco install -y vcRedist2015
RUN choco install -y vcRedist2017

# Install bazel  
RUN choco install -y bazel

# It looks like these paths cannot have escaped slashes, otherwise \\ will be passed on.
RUN setx BAZEL_SH "C:\msys64\usr\bin\bash.exe"
RUN setx PATH "%PATH%;c:\msys64\usr\bin"

##Install Git and posh-git for advanced repo operations
#https://hub.docker.com/r/ehong/git-windows-server
#Install Git
RUN choco install git.install -y 
# Install NuGet provider
RUN powershell -Command "Install-PackageProvider -Name NuGet -Force -Scope AllUsers -RequiredVersion 2.8.5.201 -ErrorAction Stop"
# Set the PSGallery as a trusted repository
RUN powershell -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"
#Install posh-git
RUN powershell Install-Module -Name 'posh-git'


### ToDo
##Install Visual Studio build tools using Chocolatey (preferred, not working)
##RUN choco install visualstudio2019buildtools -y
#
##Install build tools via direct web download (working)
##https://learn.microsoft.com/en-us/visualstudio/install/build-tools-container?view=vs-2019
#
#RUN \
#    # Download the Build Tools bootstrapper.
#    curl -SL --output vs_buildtools.exe https://aka.ms/vs/16/release/vs_buildtools.exe \
#    \
#    # Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
#    && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache \
#        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools" \
#        --add Microsoft.VisualStudio.Workload.AzureBuildTools \
#        --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
#        --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
#        --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
#        --remove Microsoft.VisualStudio.Component.Windows81SDK \
#        || IF "%ERRORLEVEL%"=="3010" EXIT 0) \
#    \
#    # Cleanup
#    && del /q vs_buildtools.exe
#
##Test installation by compiling hello-world example (not working, complains about missing build tools)
#RUN git clone https://github.com/bazelbuild/bazel 
#RUN cd bazel && bazel build //examples/cpp:hello-world