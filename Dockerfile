FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine

RUN apk --update add --no-cache \
coreutils \
curl \
gettext \
jq \
openssl \
python3 \
unzip \
wget

ENV TERRAFORM_VERSION=1.0.9

# Install terraform
RUN echo "INSTALL TERRAFORM v${TERRAFORM_VERSION}" \
&& wget -q -O terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
&& unzip terraform.zip \
&& chmod +x terraform \
&& mv terraform /usr/local/bin \
&& rm -rf terraform.zip

# Install a pinned version of kustomize
ENV KUSTOMIZE_VERSION=4.4.0
RUN curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz --output kustomize.tar.gz \
&& tar -xzf kustomize.tar.gz --directory /usr/local/bin \
&& rm kustomize.tar.gz

# Install additional tools
RUN gcloud components install \
kpt \
kubectl \
alpha \
beta \
&& rm -rf $(find google-cloud-sdk/ -regex ".*/__pycache__") \
&& rm -rf google-cloud-sdk/.install/.backup
