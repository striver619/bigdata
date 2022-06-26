# Deploy Hadoop cluster on K8s cross multiple arch

## 1. Building Docker image for ARM64 platform

- Download and load openEuler docker image
    - For openEuler-20.09 ARM
      ```shell script
      # For openEuler-20.09 ARM
      curl -L -O https://repo.openeuler.org/openEuler-20.09/docker_img/aarch64/openEuler-docker.aarch64.tar.xz
      docker load --input openEuler-docker.aarch64.tar.xz
      docker tag openeuler-20.09 openeuler-20.09-arm
      docker rmi openeuler-20.09
      ```
     - For openEuler-20.09 x86
       ```shell script
       # For openEuler-20.09 ARM
       curl -L -O https://repo.openeuler.org/openEuler-20.09/docker_img/x86_64/openEuler-docker.x86_64.tar.xz
       docker load --input openEuler-docker.x86_64.tar.xz
       docker tag openeuler-20.09 openeuler-20.09-x86
       docker rmi openeuler-20.09
       ```
- Build Hadoop docker images based on openEuler

  - Build on ARM machine
    ```shell script
    docker build . -f arm.Dockerfile -t ghcr.io/liusheng/hadoop-3.3.0-openeuler:aarch64
    ```
  - Build on X86 machine
    ```shell script
    docker build . -f x86.Dockerfile -t ghcr.io/liusheng/hadoop-3.3.0-openeuler:x86
    ```

## 2. Deploy Hadoop cluster on K8S

- Deploy Hadoop cluster
```shell script
kubectl create -f hadoop-cluster.yaml
```
- Check resources of Hadoop cluster
```shell script
kubectl get pods -n hadoop -o wide
kubectl get services -n hadoop -o wide
```
