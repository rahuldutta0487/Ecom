# Exam Run & Verification Guide
This guide explains exactly how to run and verify your pipeline steps step-by-step during a live exam on a Virtual Machine (VM).

---

## Step 1: Start All Services on Your VM
Before doing anything, make sure all your servers are active. Run these commands on your VM terminal:

```bash
# 1. Start Jenkins (Orchestration Server)
sudo systemctl start jenkins

# 2. Start SonarQube (Quality Server)
# (Assuming SonarQube is installed in /opt/sonarqube)
sudo -u sonar /opt/sonarqube/bin/linux-x86-64/sonar.sh start

# 3. Start Tomcat (Application Server)
sudo /opt/tomcat/bin/startup.sh

# Verify they are active and running:
sudo systemctl status jenkins
ps aux | grep sonar
ps aux | grep tomcat
```

---

## Step 2: Open the Web Interfaces
Open your browser on the exam machine (or your host machine if accessing the VM remotely) and load these URLs:

1.  **Jenkins UI**: `http://<VM-IP>:8080`
    *   *What you will see*: The Jenkins login page. Enter your credentials.
2.  **SonarQube UI**: `http://<VM-IP>:9000`
    *   *What you will see*: The code quality dashboard. Login with default admin credentials (`admin`/`admin` or what the exam provides).
3.  **Tomcat Landing Page**: `http://<VM-IP>:8082` (Note: Often configured to port `8082` to avoid port conflict with Jenkins on `8080`).
    *   *What you will see*: The classic Apache Tomcat "Congratulations!" page.

---

## Step 3: Add & Push the Pipeline Files to Git
For Jenkins to run the pipeline, the configuration files we created must be in your Git repository. Run these commands in the terminal of the repository folder on your VM:

```bash
# 1. Check current status of files
git status

# 2. Add files to Git staging area
git add EcommerceApp/Jenkinsfile
git add EcommerceApp/sonar-project.properties
git add deploy.yml
git add hosts.ini

# 3. Commit the changes
git commit -m "docs: Add CI/CD pipeline automation files"

# 4. Push changes to GitHub
git push origin main
```

---

## Step 4: Run the Jenkins Pipeline & Watch It
1. Open **Jenkins** (`http://<VM-IP>:8080`).
2. Select your pipeline job (`Ecommerce-CI-CD-Pipeline`).
3. Click **Build Now** in the left-hand menu.
4. **How to see it working**:
   *   Look at the **Stage View** grid. You will see blocks representing:
       `Checkout ➔ Code Quality ➔ Quality Gate ➔ Package ➔ Deploy`
   *   The blocks will turn **Green** one by one as they pass.
   *   If you click on a build number and select **Console Output**, you can see the live build logs scrolling down (e.g. Maven compile output, SonarQube scanner output, and Ansible playbook execution logs).

---

## Step 5: Verify Code Quality in SonarQube
1. Open **SonarQube** (`http://<VM-IP>:9000`).
2. You will see a project named **EcommerceApp**.
3. **How to verify**:
   *   Check the status of the **Quality Gate** (should show `Passed` or `Failed`).
   *   Click on the project to inspect the number of **Bugs**, **Vulnerabilities**, and **Code Smells** detected.

---

## Step 6: Verify the Deployed Website
1. Open **Tomcat Application Page**: `http://<VM-IP>:8082/EcommerceApp/`
2. **How to verify**:
   *   You should see the landing page of the Ecommerce website (JSP/Servlet storefront).
   *   Try clicking links or adding items to checkout to verify that database connections (SQL/SQLite) and J2EE servlets are functioning.
