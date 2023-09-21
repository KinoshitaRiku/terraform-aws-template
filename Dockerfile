# Use multistage build to separate the build-time and runtime dependencies
FROM hashicorp/terraform:1.5.2

# Install tflint
# https://github.com/terraform-linters/tflint
ENV TFLINT_VER=0.43.0
RUN apk update && \
    apk add --no-cache curl sudo unzip make jq && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/v${TFLINT_VER}/install_linux.sh | sh && \
    # 不要なパッケージ削除
    apk del sudo unzip make && \
    # apk del curl sudo unzip make jq && \
    # 不要なキャッシュ削除
    rm -rf /var/cache/apk/*
