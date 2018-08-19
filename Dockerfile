FROM fedora:27

RUN dnf install gnupg wget dnf-plugins-core -y  \
	&& rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF" \
	&& dnf config-manager --add-repo http://download.mono-project.com/repo/centos7/ \
        && dnf install libzip bzip2 bzip2-libs mono-devel nuget msbuild referenceassemblies-pcl lynx git -y \
        && dnf clean all

RUN dnf install curl unzip java-1.8.0-openjdk-headless java-1.8.0-openjdk-devel -y && \
    dnf clean all

RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    wget -q https://packages.microsoft.com/config/fedora/27/prod.repo && \
    mv prod.repo /etc/yum.repos.d/microsoft-prod.repo && \
    chown root:root /etc/yum.repos.d/microsoft-prod.repo
RUN dnf install dotnet-sdk-2.1 -y

RUN mkdir -p /android/sdk && \
    curl -k https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -o sdk-tools-linux-4333796.zip && \
    unzip -q sdk-tools-linux-4333796.zip -d /android/sdk && \
    rm -f sdk-tools-linux-4333796.zip

RUN cd /android/sdk && \
    yes | ./tools/bin/sdkmanager --licenses && \
    ./tools/bin/sdkmanager "build-tools;27.0.3" "platform-tools" "platforms;android-26" "platforms;android-27"

RUN lynx -listonly -dump https://jenkins.mono-project.com/view/Xamarin.Android/job/xamarin-android-linux/lastSuccessfulBuild/Azure/ | grep -o "https://.*/Azure/processDownloadRequest/xamarin-android/xamarin.android-oss_v.*.tar.bz2" > link.txt
RUN curl -L $(cat link.txt) \
        -o xamarin.tar.bz2
RUN bzip2 -cd xamarin.tar.bz2 | tar -xvf -
RUN mv xamarin.android-oss_v* /android/xamarin && \
    rm -f xamarin.tar.bz2

# Xamarin.Android build depends on libzip.so.4
RUN ln -s /usr/lib64/libzip.so.5 /usr/lib64/libzip.so.4

ENV MSBuildSDKsPath=/usr/share/dotnet/sdk/2.1.400/Sdks
ENV PATH=/android/xamarin/bin/Debug/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java/
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true