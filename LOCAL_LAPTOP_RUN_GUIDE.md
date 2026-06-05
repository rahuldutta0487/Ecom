# Local Laptop Setup and Run Guide
This guide explains how to run the entire DevOps pipeline on your personal laptop using **Docker Desktop**. This mirrors the exam's multi-server architecture locally without needing multiple virtual machines.

---

## Step 1: Install Docker Desktop
To run containers on your laptop, you need Docker installed:
1. Download **Docker Desktop** from [docker.com](https://www.docker.com/products/docker-desktop/).
2. Run the installer and restart your computer when prompted.
3. Launch Docker Desktop and make sure it is running in the background.

---

## Step 2: Start the Stack in VS Code
1. Open the project folder `C:\Users\user\.gemini\antigravity\scratch\devops-case-study` in **VS Code**.
2. Open the integrated terminal in VS Code:
   *   Menu ➔ **Terminal** ➔ **New Terminal** (or press ``Ctrl + ` ``).
3. Start the three server containers by running:
   ```bash
   docker-compose up --build -d
   ```
   *This downloads the software images, compiles the custom Jenkins image (with Maven and Ansible preinstalled), and starts the containers in the background.*

---

## Step 3: Access the Local Servers
Once the containers start up, open your web browser on your laptop:

1.  **Jenkins UI**: Go to [http://localhost:8085](http://localhost:8085)
    *   To get the initial Admin password, run this command in your VS Code terminal:
        ```bash
        docker exec -it jenkins_local cat /var/jenkins_home/secrets/initialAdminPassword
        ```
    *   Copy and paste this password to unlock Jenkins and complete the default plugin setup.
2.  **SonarQube UI**: Go to [http://localhost:9005](http://localhost:9005)
    *   Login using: Username = `admin` / Password = `admin`.
    *   Change the password when prompted (e.g. to `admin123`).
3.  **Tomcat Server**: Go to [http://localhost:8087](http://localhost:8087)
    *   You should see the Tomcat default home screen.
    *   **Manager / Host Manager App Access**:
        *   **Username**: `tomcat`
        *   **Password**: `s3cretpassword`
        *   *(IP restrictions have been automatically removed).*

---

## Step 4: Configure Jenkins & Run locally

### 1. Register Maven in Jenkins
1. Open Jenkins ([http://localhost:8085](http://localhost:8085)) ➔ **Manage Jenkins** ➔ **Tools**.
2. Scroll to **Maven** ➔ Click **Add Maven**.
3. Name: `Maven 3.8.x` and check **Install automatically**. Click **Save**.

### 2. Create and Run the Pipeline Job
1. In Jenkins, click **New Item**.
2. Enter the name `Local-Ecommerce-Pipeline`, select **Pipeline**, and click **OK**.
3. Scroll down to **Pipeline** settings:
   *   **Definition**: Select **Pipeline script from SCM**.
   *   **SCM**: Select **Git**.
   *   **Repository URL**: `https://github.com/Msocial123/EcommerceApp.git`
   *   **Branch Specifier**: `*/master`
   *   **Script Path**: `EcommerceApp/Jenkinsfile-local`
4. Click **Save**.
5. Click **Build Now** to trigger the build!

---

## Step 5: Check the Results
1.  **Stage View**: Watch the pipeline complete its stages in Jenkins.
2.  **SonarQube Gate**: Open [http://localhost:9005](http://localhost:9005) to see the code scans.
3.  **Deployed Website**: Visit [http://localhost:8087/EcommerceApp/](http://localhost:8087/EcommerceApp/) in your browser to interact with the running J2EE Ecommerce storefront!

---

## Step 6: Shutdown the Stack
To stop the servers and save your laptop's memory:
```bash
docker-compose down
```
