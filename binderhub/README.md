# BinderHub on K8s

This deployment guide broadly follows the zero to BinderHub guide: https://binderhub.readthedocs.io/en/latest/zero-to-binderhub/index.html. We have added some additional steps that may be useful for those wishing to deploy from scratch in a cloud environment.

For general setup of the K8s cluster, see the instructions at the top level of this repository.

We use the Docker Hub mirror hosted by STFC Cloud for storing image environments.

## BinderHub Deployment

1. On head and worker nodes, add Docker Hub mirror in `etc/docker/daemon.json`:
    ```json
    {
        "registry-mirrors": ["https://dockerhub.stfc.ac.uk"]
    }
    ```

2. Restart Docker and verify changes
    ```bash
    $ sudo systemctl restart docker
    $ docker info
    ...
     Registry Mirrors:
      https://dockerhub.stfc.ac.uk/
    ...
    ```

3. Create directory for BinderHub config files, and add `config.yaml` and `secret.yaml` files - examples are provided in this repository. Update the `<output>` in `secret.yaml` with the outputs in the code snippet below.

    (We set the service type as NodePort in `config.yaml` as it helps the correct LoadBalancer acquire the external IP in the following steps)

    ```bash
    $ mkdir binderhub
    $ cd binderhub/
    $ openssl rand -hex 32
      <output 1>
    $ openssl rand -hex 32
      <output 2>
    $ vim secret.yaml
    $ vim config.yaml
    ```

4. Create new K8s namespace, add `jupyterhub` Helm repo, and update.
    
    ```bash
    $ kubectl create namespace binder
    $ helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
    $ helm repo update
    ```

5. Install Binder from Helm chart (we selected a recent Helm chart version from [this](https://jupyterhub.github.io/helm-chart/#development-releases-binderhub) list that did not throw any errors)

    ```
    $ helm install binder jupyterhub/binderhub --version=0.2.0-n600.h36369a7 --namespace=binder -f secret.yaml -f config.yaml
    ```

6. Verify:

    ```bash
    $ kubectl get pods -n binder
    NAME                              READY   STATUS    RESTARTS   AGE
    binder-7c5f9945fd-l9ld4           1/1     Running   0          112s
    binder-image-cleaner-wc8j2        1/1     Running   0          112s
    hub-9fbbbb596-jmk4m               1/1     Running   0          112s
    proxy-6b5cd6c7c7-9xxhv            1/1     Running   0          112s
    user-scheduler-6fffd85c85-qghwp   1/1     Running   0          112s
    user-scheduler-6fffd85c85-z6hn8   1/1     Running   0          112s
    ```

    In principle both BinderHub and JupyterHub are now running, however, some additional configuration is required to enable external access.

7. Deploy a Metal Load Balancer instance, per the instructions at the [top level of this repository](https://github.com/rohinijoshi06/jupyterhub-on-k8s#load-balancer-for-bare-metal-cluster).

8. Ensure MetalLB configmaps are pointing to correct floating IP (in this case 130.246.215.38):

    ```
    $ kubectl describe configmaps -n metallb-system config
    ...
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 130.246.215.38-130.246.215.38
    ```

9. Ensure that the `proxy-public` LoadBalancer service (in the `binder` namespace) has grabbed the floating IP.

    (Note: If it is `<pending>`, ensure that no other LoadBalancer service has grabbed the IP. In the event that it has, you can force the correct LoadBalancer service to pick up the IP by changing all 'LoadBalancer's to 'NodePort's (via e.g. `kubectl edit svc -n binder binder`), and then change the `proxy-public` back to a LoadBalancer; this should force a recheck and allow it to acquire the IP.)

    ```
    $ kubectl get svc -n binder 
    NAME           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
    binder         NodePort       10.106.206.14   <none>           80:32574/TCP   18h
    hub            ClusterIP      10.97.129.246   <none>           8081/TCP       18h
    proxy-api      ClusterIP      10.107.210.22   <none>           8001/TCP       18h
    proxy-public   LoadBalancer   10.97.232.26    130.246.215.38   80:30600/TCP   18h
    ```

10. (Optional) Configure external NGINX proxy. This isn't strictly necessary, though it is recommended to add an extra level of security, and will make it easier to enable SSL-encryption. On the NGINX proxy machine, initially configure a redirect for HTTP traffic. Since we will be running both BinderHub and JupyterHub services on the same cluster, we will add two routes to the control plane of this cluster, with paths `/binderhub/` and `/jupyterhub/`. A section of `/etc/nginx/sites-available/default` is as follows:

    ```
        location /binderhub/ {
            proxy_pass http://192.168.50.163:32574$request_uri;
            proxy_redirect off;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        
            access_log /root/logs/srcdev.skatelescope.org-binderhub-access.log;
            error_log /root/logs/srcdev.skatelescope.org-binderhub-error.log;
        }
        location /jupyterhub/ {
            proxy_pass http://192.168.50.163:80/jupyterhub/;
            proxy_redirect off;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        
            access_log /root/logs/srcdev.skatelescope.org-jupyterhub-access.log;
            error_log /root/logs/srcdev.skatelescope.org-jupyterhub-error.log;
        }
    ```

    Note: we route `/binderhub/` through to the high port number (32574) that the binder instance is mapped to, and `/jupyterhub/` to port 80, since the `proxy-public` LoadBalancer is listening on this port.
    Note 2: The $request_uri variable is used in the BinderHub location to prevent NGINX sanitising redirect links, which may have unintended consequences.

11. Configure the base URLs of both BinderHub and JupyterHub, so the applications function correctly when accessed through the proxy. Also update the `hub_url` property of the BinderHub deployment, so it can talk to JupyterHub (see full chart [here](https://github.com/jupyterhub/binderhub/blob/master/helm-chart/binderhub/values.yaml#L30)). The example `config.yaml` file has example values added, which may need modifying if using different locations in the NGINX config above.

12. Upgrade the Helm chart:

    ```bash
    $ helm upgrade --install binder jupyterhub/binderhub --version=0.2.0-n600.h36369a7 --namespace=binder -f secret.yaml -f config.yaml
    ```

13. Navigate to http://130.246.214.144/binderhub/ in a browser to view the BinderHub front end.

14. Verify functionality by adding an example GitHub repository URL (e.g. https://github.com/binder-examples/requirements) into the corresponding field. BinderHub should be able to build an image from this, push to the registry, and then launch and redirect to a Jupyter Notebook environment.

15. (Optional) Configure authentication. BinderHub defers to JupyterHub for authenticating users with an external service, and an example `config-options.yaml` file, using a client registered with ESCAPE IAM, is provided in this repository.

16. (Optional) Configure persistent storage. Volumes can be mounted in the BinderHub's JupyterHub environment in the same way as in the standard JupyterHub. An example setup is shown in `config-options.yaml`, which would require a PVC called `binderhub-data-rw-pvc` to be created.

## User Guide

The deployment can be used in the same way as other Binder deployments, for example, the publicly available [MyBinder](https://mybinder.org/). For a repository to be compatible with BinderHub, it needs a standard configuration file to define the environment requirements, be that an `environment.yml` or a `requirements.txt` file.

So for Python projects, it is usually the case that a `requirements.txt` file will set out all of the Python packages that are required to run the code in that project. This has some limitations, notably where a project's dependencies are not pure Python, though it is usually possible to wrap non-Python code into Python packages.

An example of a Binder-compliant repository is provided for the [HCG-16 Project](https://ui.adsabs.harvard.edu/abs/2019A%26A...632A..78J/abstract): https://github.com/AMIGA-IAA/hcg-16. This link can be added to the GitHub repository URL field of the Binder page, and used to spawn an interactive environment where the analysis can be reproduced.