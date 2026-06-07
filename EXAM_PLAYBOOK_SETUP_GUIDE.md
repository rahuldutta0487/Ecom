# Exam Infrastructure & Pipeline Setup Guide (Ansible VM Provisioning)

This guide provides step-by-step instructions to automatically provision your entire DevOps infrastructure (Jenkins, SonarQube + PostgreSQL, Tomcat) on bare-metal or virtual machines (VMs) using Ansible, configure their integrations, and deploy the J2EE Ecommerce Application.

---

## 1. Environment & IP Architecture

Before running the playbooks, assign IP addresses to your VMs. This guide assumes the following environment setup:

| VM Hostname | Targeted Group | Assumed IP (Example) | Role / Installed Components |
| :--- | :--- | :--- | :--- |
| **jenkins-server-01** | `[jenkins]` | `192.168.50.11` | Jenkins, Maven, Git, JDK 11, Ansible Control Node |
| **sonar-server-01** | `[sonarqube]` | `192.168.50.12` | SonarQube Server, PostgreSQL Database, JDK 17 |
| **staging-app-01** | `[staging]` | `192.168.50.10` | Tomcat 9, JDK 11, SQLite DB (J2EE Staging App) |
| **prod-app-01** | `[production]` | `10.0.100.20` | Tomcat 9, JDK 11, SQLite DB (J2EE Prod Server 1) |
| **prod-app-02** | `[production]` | `10.0.100.21` | Tomcat 9, JDK 11, SQLite DB (J2EE Prod Server 2) |

---

## 2. Prerequisites & SSH Passwordless Access

Ansible requires passwordless SSH access from the Jenkins controller (or your local machine running the playbooks) to all target servers.

1. **Log in to the Ansible Control Node** (usually the Jenkins server).
2. **Generate SSH key pair** (if not already done):
   ```bash
   ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
   ```
3. **Distribute SSH public key** to all target servers (`jenkins`, `sonarqube`, `staging`, `production`):
   ```bash
   ssh-copy-id deploy@192.168.50.11
   ssh-copy-id deploy@192.168.50.12
   ssh-copy-id deploy@192.168.50.10
   ssh-copy-id deploy@10.0.100.20
   ssh-copy-id deploy@10.0.100.21
   ```
   *Replace `deploy` with your VM login username (e.g., `ubuntu`, `admin`, etc.).*
4. Ensure the remote user has `sudo` privileges without a password prompt.

---

## 3. Inventory Configuration (`hosts.ini`)

Edit the inventory file [hosts.ini](file:///C:/Users/user/.gemini/antigravity/scratch/devops-case-study/hosts.ini) in the repository to match your actual server IPs and SSH credentials:

```ini
[jenkins]
jenkins-server-01 ansible_host=192.168.50.11 ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_rsa

[sonarqube]
sonar-server-01 ansible_host=192.168.50.12 ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_rsa

[staging]
staging-app-01 ansible_host=192.168.50.10 ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_rsa

[production]
prod-app-01 ansible_host=10.0.100.20 ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_rsa
prod-app-02 ansible_host=10.0.100.21 ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_rsa
```

---

## 4. Execution of Infrastructure Provisioning

Run the Ansible playbooks to install and configure all servers:

### Option A: Provision the Entire Infrastructure in One Command (Recommended)
```bash
ansible-playbook -i hosts.ini setup_all.yml
```

### Option B: Run Specific Component Playbooks Individually
```bash
# Provision Jenkins (CI/CD Server) only
ansible-playbook -i hosts.ini setup_jenkins.yml

# Provision SonarQube and PostgreSQL Database only
ansible-playbook -i hosts.ini setup_sonarqube.yml

# Provision Tomcat J2EE App Servers only
ansible-playbook -i hosts.ini setup_tomcat.yml
```

### Verification of Service Statuses
Verify that services are running successfully on their respective nodes:
```bash
# On Jenkins server
systemctl status jenkins

# On SonarQube server
systemctl status sonar
sudo -u postgres psql -c "\l" | grep sonar  # Verify PostgreSQL DB exists

# On Tomcat application servers
systemctl status tomcat
```

---

## 5. First-Time Setup & Integrations

Once the infrastructure is successfully hosted, configure integration settings via their Web GUIs:

### Step 1: Configure SonarQube
1. Open your browser and navigate to `http://<sonarqube-server-ip>:9000`.
2. Login with credentials: Username `admin`, Password `admin`. Change the password when prompted.
3. **Create an API Token for Jenkins**:
   - Go to **My Account** (top-right avatar) ➔ **Security** tab.
   - Enter a token name (e.g., `jenkins-token`), select **User Token** type, and click **Generate**.
   - **Copy the generated token immediately** (e.g., `sqa_abcdef123456...`). You will need it in Jenkins.
4. **Create a Jenkins Webhook**:
   - Go to **Administration** (top menu bar) ➔ **Configuration** (dropdown) ➔ **Webhooks**.
   - Click **Create**, configure:
     - Name: `Jenkins-Webhook`
     - URL: `http://<jenkins-server-ip>:8080/sonarqube-webhook/`
   - Click **Create**. This webhook allows SonarQube to report Quality Gate status back to Jenkins.

### Step 2: Configure Jenkins
1. Navigate to `http://<jenkins-server-ip>:8080`.
2. Retrieve the initial admin password from the Ansible terminal execution output or by running:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Follow the wizard, select **Install suggested plugins**, and create your admin account.
4. **Install Required Jenkins Plugins**:
   - Go to **Manage Jenkins** ➔ **Plugins** ➔ **Available Plugins**.
   - Search for and check:
     *   `SonarQube Scanner`
     *   `Ansible`
   - Click **Install without restart** (or install and restart Jenkins).
5. **Configure Global Tools**:
   - Go to **Manage Jenkins** ➔ **Tools**.
   - **Maven**: Scroll down to Maven, click **Add Maven**, set Name to `Maven 3.8.x`, check **Install automatically**, and select version `3.8.8` (or similar).
   - **JDK**: Scroll down to JDK, click **Add JDK**, set Name to `Java 11`. You can configure a manual path if pre-installed, or choose auto-install.
6. **Add Credentials to Jenkins**:
   - Go to **Manage Jenkins** ➔ **Credentials** ➔ **System** ➔ **Global credentials** ➔ **Add Credentials**.
   - **Credential 1: SonarQube Auth Token**
     - **Kind**: `Secret text`
     - **ID**: `sonar-token`
     - **Secret**: Paste the token copied from SonarQube.
     - Click **Create**.
   - **Credential 2: Ansible Deployment SSH Key**
     - **Kind**: `SSH Username with private key`
     - **ID**: `ansible-ssh-key`
     - **Username**: `deploy` (SSH username for Tomcat VMs)
     - **Private Key**: Select *Enter directly* and paste the contents of `~/.ssh/id_rsa` from the Ansible node.
     - Click **Create**.
7. **Configure SonarQube System Connection**:
   - Go to **Manage Jenkins** ➔ **System** (formerly System Configuration).
   - Scroll down to **SonarQube servers**.
   - Check **Enable injection of SonarQube server configuration as build variables**.
   - Click **Add SonarQube**. Configure:
     - Name: `SonarQube` (Must match the `SONAR_SERVER_NAME` inside the [Jenkinsfile](file:///C:/Users/user/.gemini/antigravity/scratch/devops-case-study/EcommerceApp/Jenkinsfile))
     - Server URL: `http://<sonarqube-server-ip>:9000`
     - Server authentication token: Select the `sonar-token` credential created earlier.
   - Click **Save**.

---

## 6. Project Pipeline Execution

1. In Jenkins dashboard, click **New Item**.
2. Name it `Ecommerce-CI-CD-Pipeline`, select **Pipeline**, and click **OK**.
3. In the Job configuration page:
   - Scroll down to the **Pipeline** section.
   - **Definition**: Select **Pipeline script from SCM**.
   - **SCM**: Select **Git**.
   - **Repository URL**: `https://github.com/Msocial123/EcommerceApp.git`
   - **Branch Specifier**: `*/main` (or the branch you want to build).
   - **Script Path**: `EcommerceApp/Jenkinsfile`
4. Click **Save**.
5. Click **Build Now** to execute the pipeline.

---

## 7. Pipeline Workflow Verification

During pipeline execution, you can watch the steps run:
1. **Checkout Source**: Clones git repository `EcommerceApp` workspace.
2. **Code Quality Analysis**: Compiles Java code and executes SonarQube SAST analysis via Maven (`mvn clean compile sonar:sonar`).
3. **Quality Gate Validation**: Pauses build. Jenkins queries SonarQube or waits for the webhook. If analysis violates Quality Gate parameters (e.g. security hotspots or vulnerabilities), the pipeline stops and alerts developers.
4. **Package Application**: Compiles application and bundles resources into `EcommerceApp.war` file.
5. **Deploy to Staging**: Jenkins invokes Ansible to execute [deploy.yml](file:///C:/Users/user/.gemini/antigravity/scratch/devops-case-study/deploy.yml) playbook limiting scope to `staging`. Ansible stops Tomcat, backups the previous WAR, deploys the new WAR, restarts Tomcat, and asserts HTTP 200 health.
6. **Promote to Production (Gated)**: Pauses execution waiting for approval. Once approved, executes [deploy.yml](file:///C:/Users/user/.gemini/antigravity/scratch/devops-case-study/deploy.yml) targeting `production` (deploying to both Tomcat production nodes).

---

## 8. Failure Handling and Rollback Verification

To verify that the automated rollback mechanism works:
1. Trigger a pipeline build with a corrupted version or make an error in Tomcat database connection strings causing application startup to fail.
2. The deployment task will run:
   - Stops Tomcat.
   - Deploys corrupted `EcommerceApp.war`.
   - Starts Tomcat.
   - Polls `http://localhost:8080/EcommerceApp/` and encounters timeouts or HTTP 500 errors.
3. Ansible notices the failure after `retries: 15` and enters the `rescue` block:
   - Stops Tomcat.
   - Deletes corrupted files.
   - Restores `/opt/tomcat/backups/EcommerceApp.war.bak`.
   - Restarts Tomcat.
   - Asserts health check of the restored previous version.
4. The deployment pipeline fails safely, preserving 100% uptime of the old working code.
