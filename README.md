# Dify on Azure VM — **Bicep Quick Start** 🚀

セルフホスト型 GenAI プラットフォーム **Dify** を **Azure VM + Docker Compose v2** でデプロイするリポジトリです。

- Infrastructure‑as‑Code : **Azure Bicep**
- プロビジョニング : **cloud‑init**（Docker & Dify 自動起動）
- セキュリティ : NSG で **ポート80 を管理端末だけ許可**（初期セットアップ用）
- 起動確認 : VM 拡張機能 **Custom Script Extension** でコンテナ起動までポーリング

---

## 🛠️ 前提条件

- **Azure サブスクリプション**
- **Azure CLI** インストール済み (v2.59.0 以上)
- **SSH 公開鍵** `~/.ssh/id_ed25519.pub` など
- **自端末のグローバル IPv4** `/32` 形式（例 `203.0.113.5/32`）

> **検証環境**  
> 本 README のコマンドは **macOS Sequoia 15.x / Azure CLI 2.74.0** で動作確認済みです。    
> Windows PowerShell の場合は `curl` オプションやパス表記に注意してください。

---

## 🔑 SSH 鍵をまだ持っていない場合

```bash
# 推奨: ed25519 で鍵ペアを生成（パスフレーズは任意）
ssh-keygen -t ed25519 -C "dify-vm-$(date +%Y%m%d)" -f ~/.ssh/id_ed25519_dify

# 公開鍵を確認（これをパラメータに渡す）
cat ~/.ssh/id_ed25519.pub
```

> **ポイント**  
> - `.pub` が **公開鍵** ‑‑ Bicep に渡す  
> - `id_ed25519` が **秘密鍵** ‑‑ **公開しない**  
> - すでに鍵を持っている場合はスキップ

---

## ⚡ デプロイ手順

```bash
# 1. 作業端末の IPv4 を取得（IPv6 環境でも -4 で固定）
export ADMIN_IP_CIDR="$(curl -4 -s https://api.ipify.org)/32"

# 2. デプロイ
az deployment sub create \
  --location japaneast \
  --template-file main.bicep \
  --parameters \
      environmentName=prod \
      adminSourceIp=$ADMIN_IP_CIDR \
      adminPublicKey="$(cat ~/.ssh/id_ed25519.pub)"

# 3. 完了メッセージに表示される SSH & Public IP を確認
```
> 📝 **出力例**
> ```text
> "outputs": {
>   "publicIp": {
>     "type": "String",
>     "value": "203.0.113.1"
>   },
>   "sshCommand": {
>     "type": "String",
>     "value": "ssh azureuser@203.0.113.1"
>   }
> ```

---

## 🐳 初期セットアップ（ブラウザ）

1. （自IPのみ許可）された端末から `http://203.0.113.1` へアクセス
2. 管理者アカウントを登録 → ログイン直後に Dashboard が表示されれば OK
3. OpenAI API Key とモデル を設定

> 初期セットアップ用に **22 (SSH)** と **80 (HTTP)** が開いています。運用フェーズでは 22 のアクセス元を絞り、Web は 443 (HTTPS) のみにするとさらに安全です。

---

## 📂 リポジトリ構成

```
.
├── main.bicep                 # サブスクスコープ：RG＋ネットワーク/VM モジュール呼び出し
├── modules/
│   ├── network.bicep          # VNet & NSG（22 と 80 を管理端末 IP のみに許可）
│   └── vm.bicep               # Linux VM + cloud-init + Custom Script Extension
├── scripts/
│   ├── cloud-init.yaml        # VM ブート時：Docker & Dify を自動インストール＆起動
│   └── wait-dify.sh           # CSE が実行するコンテナ起動待ちシェル
└── README.md                  # このドキュメント
```