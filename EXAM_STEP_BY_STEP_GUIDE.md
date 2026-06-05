# Step-by-Step DevOps CI/CD Exam Guide
This guide is designed to help you set up and run the entire pipeline during an exam or lab test. It covers every command, installation, and configuration step.

---

## Part 1: Prerequisites & Installation

If your exam environment does not have the tools installed, run these commands in your terminal:

### 1. Install Java 11 & Maven (Build Environment)
```bash
# Update package list
sudo apt update

# Install JDK 11
sudo apt install -y openjdk-11-jdk

# Install Maven
sudo apt install -y maven

# Verify installations
java -version
mvn -version
```

### 2. Install Jenkins (CI/CD Server)
```bash
# Add Jenkins GPG key and repository
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins
```
*Access Jenkins in your browser at: `http://<server-ip>:8080` (get the initial admin password from `/var/lib/jenkins/secrets/initialAdminPassword`).*

### 3. Install Tomcat (Application Server)
```bash
# Create Tomcat user and group
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

# Download and extract Tomcat 9
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz
sudo mkdir /opt/tomcat
sudo tar xzvf apache-tomcat-9.0.75.tar.gz -C /opt/tomcat --strip-components=1

# Set permissions
cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ log/
```

### 4. Install Ansible (Configuration Management)
```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

---

## Part 2: Step-by-Step Tool Configuration

### Step 1: Set up Ansible SSH Keys
To allow Ansible to deploy files to your application server without asking for a password:
1. Generate an SSH key on your Jenkins/Ansible server:
   ```bash
   ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
   ```
2. Copy the key to your target Application Server:
   ```bash
   ssh-copy-id deploy@<app-server-ip>
   ```

### Step 2: Configure SonarQube in Jenkins
1. Open Jenkins Dashboard, go to **Manage Jenkins** ➔ **Plugins** ➔ **Available Plugins** and install:
   *   `SonarQube Scanner`
   *   `Ansible`
2. Go to **Manage Jenkins** ➔ **System** ➔ scroll down to **SonarQube servers**:
   *   Name: `SonarQube`
   *   Server URL: `http://<sonarqube-server-ip>:9000`
   *   Server authentication token: Add your SonarQube API token.
3. Go to **Manage Jenkins** ➔ **Tools** ➔ scroll down to **Maven**:
   *   Click **Add Maven**, set Name to `Maven 3.8.x`, and select **Install automatically**.

### Step 3: Configure Ansible Credentials in Jenkins
1. Go to **Manage Jenkins** ➔ **Credentials** ➔ **System** ➔ **Global credentials** ➔ **Add Credentials**.
2. **Kind**: SSH Username with private key.
3. **ID**: `ansible-ssh-key`.
4. **Username**: `deploy` (or the username of your app server).
5. **Private Key**: Select *Enter directly* and paste the contents of your private key (`~/.ssh/id_rsa`).

---

## Part 3: Creating and Running the Pipeline in Jenkins

1. **Create Job**: On the Jenkins homepage, click **New Item**.
2. **Name**: Enter `Ecommerce-CI-CD-Pipeline` and select **Pipeline**, then click **OK**.
3. **Pipeline Script Source**: Scroll down to the **Pipeline** section:
   *   **Definition**: Select **Pipeline script from SCM**.
   *   **SCM**: Select **Git**.
   *   **Repository URL**: `https://github.com/Msocial123/EcommerceApp.git`
   *   **Branch Specifier**: `*/main`
   *   **Script Path**: `EcommerceApp/Jenkinsfile`
4. **Save** the job.
5. **Run the Pipeline**: Click **Build Now** in the left sidebar.

---

## Part 4: How to Explain the Architecture to the Examiner

If the examiner asks you how your solution works, explain these **5 key concepts**:

1. **Pipeline Flow**: "The pipeline is triggered when code is pushed to GitHub. Jenkins checks out the code, runs static analysis in SonarQube, enforces the Quality Gate, builds a J2EE WAR file using Maven, and calls Ansible to deploy it."
2. **Code Quality Gate**: "If the code has security vulnerabilities or bugs, SonarQube reports a failure, and Jenkins halts the pipeline before building or deploying. This prevents broken code from reaching staging."
3. **Automated Rollback**: "If the Tomcat health check fails after deployment, Ansible automatically rolls back to the backup WAR, minimizing downtime."
4. **No Hardcoded Passwords**: "All credentials (SSH keys, API tokens) are securely stored in the Jenkins Credentials Store and injected at runtime."
5. **Infrastructure as Code**: "All deployment steps (stopping services, moving files, starting services, health checking) are written in `deploy.yml`, so they are fully repeatable."
