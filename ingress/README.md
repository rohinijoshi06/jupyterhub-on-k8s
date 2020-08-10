### This section provides a way to set up a custom Ingress route to the JupyterHub instance

#### JupyterHub baseUrl
Configure a custom baseUrl for the JupyterHub deployment by setting the corresponding value in the config file. See jupyterhub-config-escape.yaml.  
Also, this yaml file points to the ESCAPE IAM instance. 
#### Deploy the ingress-nginx controller based on documentation [here](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal) 
`kubectl apply -f deployIngressController.yaml`

#### Deploy an Ingress resource 
Edit the metadata.namespace to match that of your JupyterHub deployment. Also edit the path to match the baseURL of the JupyterHub deployment.
`kubectl apply -f ingressJhubESCAPE.yaml`    

This will now redirect traffic to a JupyterHub deployment running at `http://<public IP>/escape`
