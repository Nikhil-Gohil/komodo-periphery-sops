# 1. Define Versions (Visible to Renovate)
# renovate: datasource=docker depName=moghtech/komodo-periphery
ARG KOMODO_VERSION=1.19.5

# renovate: datasource=github-releases depName=getsops/sops
ARG SOPS_VERSION=v3.11.0

# renovate: datasource=github-releases depName=FiloSottile/age
ARG AGE_VERSION=v1.2.1

# 2. Start the Build
FROM moghtech/komodo-periphery:${KOMODO_VERSION}

# 🔴 CRITICAL FIX: Re-declare these to use them inside the image
ARG SOPS_VERSION
ARG AGE_VERSION

USER root

# Install dependencies
RUN apt-get update && apt-get install -y curl tar && rm -rf /var/lib/apt/lists/*

# Install SOPS
# (We add -f to curl so it fails immediately if the link is wrong, preventing silent errors)
RUN curl -f -L "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64" -o /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops

# Install Age
RUN curl -f -L "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" -o age.tar.gz \
    && tar -xzf age.tar.gz \
    && mv age/age /usr/local/bin/age \
    && chmod +x /usr/local/bin/age \
    && rm -rf age.tar.gz age

# Bake the scripts
RUN echo '#!/bin/sh\n\
if [ -f ".env.enc" ]; then\n\
    echo "🔐 Found .env.enc, decrypting..."\n\
    sops --decrypt .env.enc > .env\n\
    if [ $? -eq 0 ]; then echo "✅ Decryption successful."; else echo "❌ Failed!"; exit 1; fi\n\
else\n\
    echo "ℹ️ No .env.enc found, skipping."\n\
fi' > /usr/local/bin/komodo-pre-deploy && chmod +x /usr/local/bin/komodo-pre-deploy

RUN echo '#!/bin/sh\n\
if [ -f ".env" ] && [ -f ".env.enc" ]; then\n\
    echo "🧹 Cleaning up .env..."\n\
    rm .env\n\
fi' > /usr/local/bin/komodo-post-deploy && chmod +x /usr/local/bin/komodo-post-deploy
