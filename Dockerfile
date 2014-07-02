FROM grams/ubuntu-base

# Create Jenkins user
RUN useradd -m -d /home/jenkins -p $(perl -e 'print crypt("jenkins", "jenkins"),"\n"') -s /bin/bash -U jenkins

# Install Jenkins slave
RUN mkdir -p /home/jenkins/slave/workspace
ADD assets/slave.jar /home/jenkins/slave/slave.jar
RUN chown -R jenkins:jenkins /home/jenkins/slave

VOLUME ["/home/jenkins/slave/workspace"]

CMD ["sudo", "-i", "-u", "jenkins", "java", "-jar", "/home/jenkins/slave/slave.jar"]

## Jenkins slave features can be freely added or removed by adding or removing sections below

## Java6 SDK
#RUN apt-get install -y openjdk-6-jdk

## Sun/Oracle Java 6 JDK
# to skip the license screen:
RUN /bin/echo -e "debconf shared/accepted-oracle-license-v1-1 select true\ndebconf shared/accepted-oracle-license-v1-1 seen true"| /usr/bin/debconf-set-selections
RUN add-apt-repository ppa:webupd8team/java && apt-get update
RUN apt-get install -y oracle-java6-installer

## Dart SDK
RUN curl "http://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip" > dartsdk.zip && unzip -q dartsdk.zip && rm -f dartsdk.zip && chmod -R a+r dart-sdk && find dart-sdk -type d -exec chmod 755 {} \; && chmod -R a+x dart-sdk/bin && cp -R dart-sdk /usr/lib/dart-sdk && rm -rf dart-sdk

## Android SDK
RUN curl "http://dl.google.com/android/android-sdk_r22.6.1-linux.tgz" | tar xz && mv android-sdk-linux /usr/lib/android-sdk
# Update Android SDK
# Answering yes trick found here http://stackoverflow.com/a/21910110/1472121
RUN ( sleep 5 && while [ 1 ]; do sleep 1; echo y; done ) | /usr/lib/android-sdk/tools/android update sdk --no-ui --filter platform-tool,android-19,sysimg-19,build-tools

## Xvfb and Firefox
# for Selenium
RUN apt-get install -y xvfb firefox
RUN /bin/echo -e "[program:xvfb] \ncommand=Xvfb :99 -screen 0 1600x1200x24 -ac \nautostart=true \nautorestart=true \nredirect_stderr=true" > /etc/supervisor/conf.d/xvfb.conf
RUN /bin/echo -e "\nexport DISPLAY=:99 \n" >> /etc/profile  
RUN /bin/echo -e "#!/bin/bash\nxvfb-run firefox\n" > /usr/bin/xvfb-run-firefox && chmod 755 /usr/bin/xvfb-run-firefox

## Asciidoc
RUN apt-get install -y asciidoc

## Ruby with rbenv
# Before installing Ruby, you’ll want to make sure you have a sane build environment. The following list of packages comes from
# the ruby-build wiki:https://github.com/sstephenson/ruby-build/wiki#wiki-suggested-build-environment
RUN apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev
RUN sudo -u jenkins -i /bin/bash -c "git clone git://github.com/sstephenson/rbenv.git ~/.rbenv && git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build"
RUN /bin/echo -e '\nif [ -n "$BASH_VERSION" ]; then\n\texport PATH="$PATH:$HOME/.rbenv/bin"\n\teval "$(rbenv init -)"\nfi\n' >> /home/jenkins/.profile
RUN sudo -u jenkins -i /bin/bash -c "rbenv install 1.9.3-p484 && rbenv global 1.9.3-p484"

## Ruby gem asciidoctor 
RUN sudo -u jenkins -i /bin/bash -c "gem install asciidoctor"
