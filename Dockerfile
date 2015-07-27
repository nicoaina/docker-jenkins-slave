FROM grams/ubuntu-base

# Create Jenkins user
RUN useradd -m -d /home/jenkins -u 18001 -p $(perl -e 'print crypt("jenkins", "jenkins"),"\n"') -s /bin/bash -U jenkins
# Allow jenkins to start supervisord (in jobs that require Xvfb)
RUN /bin/echo -e "jenkins ALL=(root) NOPASSWD: /usr/sbin/service supervisor start"> /etc/sudoers.d/jenkins && chmod 0440 /etc/sudoers.d/jenkins

# Install Jenkins slave
RUN mkdir -p /home/jenkins/slave/workspace
ADD assets/slave.jar /home/jenkins/slave/slave.jar
ADD assets/toolchains.xml /home/jenkins/.m2/toolchains.xml
RUN chown -R jenkins:jenkins /home/jenkins

VOLUME ["/home/jenkins/slave/workspace"]

CMD ["sudo", "-i", "-u", "jenkins", "java", "-jar", "/home/jenkins/slave/slave.jar"]

## Jenkins slave features can be freely added or removed by adding or removing sections below

## Sun/Oracle Java 6 JDK
# to skip the license screen:
RUN /bin/echo -e "debconf shared/accepted-oracle-license-v1-1 select true\ndebconf shared/accepted-oracle-license-v1-1 seen true"| /usr/bin/debconf-set-selections
RUN add-apt-repository ppa:webupd8team/java && apt-get update && apt-get install -y oracle-java6-installer && apt-get clean

## Oracle Java 8 JDK
RUN add-apt-repository ppa:webupd8team/java && apt-get update && apt-get install -y oracle-java8-installer && apt-get clean

# Keep Java7 as default jdk
RUN update-java-alternatives -s java-1.7.0-openjdk-amd64

# Maven SDKs
USER jenkins
RUN mkdir -p /home/jenkins/slave/tools/hudson.tasks.Maven_MavenInstallation/
WORKDIR /home/jenkins/slave/tools/hudson.tasks.Maven_MavenInstallation/
RUN curl "http://archive.apache.org/dist/maven/binaries/apache-maven-3.0.4-bin.tar.gz" | tar xz && mv apache-maven-3.0.4 Maven_3.0.4
RUN curl "http://archive.apache.org/dist/maven/binaries/apache-maven-3.0.5-bin.tar.gz" | tar xz && mv apache-maven-3.0.5 Maven_3.0.5
USER root
WORKDIR /

## Xvfb and Firefox
# for Selenium
RUN curl "http://security.ubuntu.com/ubuntu/pool/main/f/firefox/firefox_37.0+build2-0ubuntu1_amd64.deb" > firefox.deb ; dpkg -i firefox.deb ; apt-mark hold firefox ; apt-get -y install libstartup-notification0 libxcb-util0 ; apt-get -f --force-yes --yes install ; dpkg -i firefox.deb ; rm firefox.deb
RUN apt-get update && apt-get install -y xvfb && apt-get clean
RUN /bin/echo -e "[program:xvfb] \ncommand=Xvfb :99 -screen 0 1600x1200x24 -ac \nautostart=true \nautorestart=true \nredirect_stderr=true" > /etc/supervisor/conf.d/xvfb.conf

## Ansible
RUN apt-get install software-properties-common && apt-add-repository ppa:ansible/ansible && apt-get update && apt-get install -y ansible && apt-get clean

## Jenkins autojobs
RUN apt-get install -y python-pip python-dev libxml2-dev libxslt1-dev zlib1g-dev && apt-get clean
RUN pip install jenkins-autojobs

