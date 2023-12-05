# alphin
FROM hashicorp/terraform:1.5.2

# 現在のユーザーを取得: whoami
# ユーザー一覧を取得: cat /etc/passwd
# ユーザーとグループを作成し、sudoをインストール、sudo権限を付与
RUN addgroup -g 1000 vscode && \
    adduser -u 1000 -G vscode -s /bin/ash -D vscode && \
    apk add --no-cache sudo && \
    echo "vscode   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install tflint
# https://github.com/terraform-linters/tflint
ENV TFLINT_VER=0.43.0
RUN apk update && \
    apk add --no-cache curl sudo unzip make jq bash && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/v${TFLINT_VER}/install_linux.sh | sh && \
    # 不要なパッケージ削除
    apk del sudo unzip && \
    # 不要なキャッシュ削除
    rm -rf /var/cache/apk/*
