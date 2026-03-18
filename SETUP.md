# SETUP.md

## Installation and Configuration Instructions

### Step 1: Install Ollama
1. Visit the [Ollama official website](https://ollama.com) to download the installer for your operating system.
2. Follow the installation instructions provided on the website.
3. After installation, verify it by running `ollama --version` in your terminal.

### Step 2: Install N8N
1. Ensure you have Node.js installed on your machine (version 14 or later).
2. Install N8N globally using npm:
   ```bash
   npm install n8n -g
   ```
3. Start N8N by running:
   ```bash
   n8n
   ```
4. Open your web browser and navigate to `http://localhost:5678` to access N8N.

### Step 3: Configure GitHub API
1. Go to your GitHub account settings and navigate to **Developer settings**.
2. Click on **Personal access tokens** and then **Generate new token**.
3. Select the necessary scopes based on your requirements (e.g., `repo`, `workflow`).
4. Copy the generated token as you will need it for authentication in N8N.

### Step 4: Integrate Claude/Ollama with N8N
1. In N8N, create a new workflow.
2. Add the Ollama node to your workflow:
   - Set it up with the necessary parameters.
3. Configure the GitHub API node to use the token generated previously:
   - Input the token in the authentication section.
4. Link the nodes accordingly to enable communication between Ollama and GitHub.

### Step 5: Test the Integration
1. Execute the N8N workflow to ensure that Ollama can interact with GitHub via the API.
2. Verify that data is exchanged correctly.
3. Monitor for any errors and resolve them as needed.

### Conclusion
Following these steps will set up your environment with Ollama, N8N, and the GitHub API integration efficiently. Make sure to consult the respective documentation for more detailed instructions as needed.
