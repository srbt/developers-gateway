## Use case: Docker network with containers for development of modularized application

### Problem Statement
We have a modularized application consisting of multiple components (e.g., API, backoffice) that communicate with each other over HTTP or HTTPS.

From outer network, we want to access these components using production URLs over HTTPS.

As developers, we need to create a development environment that closely mirrors the production setup to test our changes effectively. We also want to simplify the network configuration, enable easier debugging, and improve the development workflow.

### Proposed Solution
We propose using Docker to create a network of containers that simulate the production environment, along with forward and reverse proxies to manage traffic between the components. The setup includes the following components:

- examples of modules: API, backoffice
- reverse proxy: handles incoming requests and routes them to the appropriate module
- forward proxy: forwards requests from the browser to the reverse proxy

```mermaid
graph TD;
    subgraph Outer Network
        browser
        FP[forward-proxy:3128]
        browser -->|https-proxy| FP
    end
    
    subgraph Docker Network
        RP[reverse-proxy:443]
        API[api:8080]
        BO[backoffice:8080]
        
        FP -->|https| RP
        RP -->|http| API
        RP -->|http| BO
    end

```
Solution contains two variants of the setup - one with HTTP and one with HTTPS communication between the modules.

## Developers access the application using the forward proxy
Developers configure their browsers to use the forward proxy to access the application modules using production URLs. The forward proxy forwards the requests to the reverse proxy, which routes them to the appropriate module based on the URL path.
Proxy configuration can be passed to the browser environment variables.
Is recommended to use a separate profile for the browser to avoid conflicts with the default profile.

For example, in Linux:
```bash
mkdir -p /path/to/profile
https_proxy=http://${HOSTNAME}:3128 firefox --profile /path/to/profile
https_proxy=http://${HOSTNAME}:3128 google-chrome --user-data-dir=/path/to/profile
https_proxy=http://${HOSTNAME}:3128 curl https://api.in.application.com
```

For best comfort is recomended to import Certificate Authority (CA) certificate generated for the reverse proxy to the browser's profile.

If you are worried about confusion between production and development environments, you can use a slightly different domain name for the development environment, e.g., `backoffice.in.application.com` or differentiate test version by color or other visual cues. Color scheme can be modified in the browser's profile.
For example, in Firefox you can set color for panels in css file as described in https://stackoverflow.com/questions/78206548/firefox-124-how-to-change-background-color-of-active-tab-in-userchrome-css or https://www.userchrome.org/.

For two or more docker network setups, you must use different ports for the forward proxy, but it is only one port to change in the configuration.

## ChatGpt opinion about the solution

This configuration offers several benefits to developers by simulating a production-like environment, facilitating easier development, testing, and debugging processes. Here's a detailed description of the advantages:

1. **Production-like Environment**:
    - **Realistic Testing**: Developers can test their changes in an environment that closely mirrors the production setup. This ensures that the application behaves as expected when deployed.
    - **Integration Testing**: Developers can run integration tests in an environment that simulates real-world interactions between different modules (api, backoffice) and the proxies.

2. **Simplified Network Configuration**:
    - **Consistent Access**: By configuring their browsers to use the forward proxy, developers can access the different modules using production URLs. This avoids the need for changing URLs or configurations when switching between development and production environments.
    - **Uniform Access Control**: The reverse proxy manages access to the api and backoffice modules, ensuring consistent access control and routing rules.

3. **Improved Development Workflow**:
    - **Easier Debugging**: The reverse proxy can be configured to log requests and responses, providing valuable insights during debugging. Developers can trace requests from the browser through the proxies to the application modules.
    - **Modular Development**: By isolating the api and backoffice modules within their own containers, developers can work on individual modules independently without affecting others. This modularity speeds up the development process and reduces the risk of breaking the application.

4. **Proxy Caching and Load Balancing**:
    - **Enhanced Performance**: The forward and reverse proxies can be configured to cache certain requests, reducing the load on the application modules and improving response times during development.
    - **Load Balancing**: Proxies can distribute incoming requests evenly across multiple instances of a module, simulating load balancing scenarios and ensuring that the application can handle traffic spikes effectively.

5. **Security and Isolation**:
    - **Isolated Development Environment**: The Docker network provides an isolated environment, preventing potential conflicts with other services running on the developer's machine.
    - **Secure Access**: Using HTTPS between the forward proxy and reverse proxy ensures secure communication, protecting sensitive data during development.

6. **Flexible Configuration**:
    - **Customizable Setup**: Developers can easily modify the configuration of the proxies and modules to test different scenarios or configurations. This flexibility is crucial for identifying potential issues and optimizing the application's performance and reliability.

By leveraging this Docker network setup with forward and reverse proxies, developers can create a robust, scalable, and secure development environment that closely mimics production, ultimately leading to higher quality software and more efficient development processes.
