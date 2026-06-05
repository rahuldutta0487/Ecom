FROM tomcat:9-jdk11

# Install Python 3 for Ansible management connection
RUN apt-get update && apt-get install -y python3 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Move default webapps to make them active
RUN rm -rf /usr/local/tomcat/webapps && \
    mv /usr/local/tomcat/webapps.dist /usr/local/tomcat/webapps

# Overwrite context.xml to remove Remote IP restrictions
COPY context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml
COPY context.xml /usr/local/tomcat/webapps/host-manager/META-INF/context.xml
COPY context.xml /usr/local/tomcat/webapps/examples/META-INF/context.xml

# Copy users and roles configuration
COPY tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
