# exec_cloud_functions_by_github_actions

# はじめに

# 概要

# 環境

Google Cloud

# 設定手順

大まかな手順は以下の通りです。

1. サービスアカウントを準備する
2. 呼び出すCloud Functionsを準備する
3. GitHub Actionsで使用するWorkload Identityを準備する

## 1. SAを準備する

## 1.1. SAを作成する

Cloud FunctionsとGitHub Actionsで使用するSAを準備する

* Cloud Functions用にSA`sa-gcf-executor`を作成する

```
gcloud iam service-accounts create sa-gcf-executor \
    --display-name=sa-gcf-executor
```

* GitHub Actions用にSA`sa-github-actions`を作成する

```
gcloud iam service-accounts create sa-github-actions \
    --display-name=sa-github-actions
```

## 1.2. SAに必要な権限を付与する

* `sa-github-actions`にサービスアカウントトークン作成者（`roles/iam.serviceAccountTokenCreator`）の権限をプロジェクトレベルで付与する

```
gcloud projects add-iam-policy-binding hanzawa-yuya \
    --member=serviceAccount:sa-gcf-executor@hanzawa-yuya.iam.gserviceaccount.com \
    --role=roles/iam.serviceAccountTokenCreator \
    --condition=None
```

* 必要に応じて`sa-gcf-executor`にも権限を付与する

# 2. Cloud Functionsを準備する

## 2.1. Cloud Functionsをデプロイする

* 必要に応じてスクリプトやライブラリを変更する

```
cd CloudFunctions/
bash ./deploy.sh
```

## 2.2. Cloud Functionsを起動する権限を付与

* `sa-github-actions`にCloud Run起動元（`roles/run.invoker`）の権限を2.1で作成したCloud Functions単体レベルで付与する

```
gcloud functions add-invoker-policy-binding hello-world \
    --region='asia-northeast1' \
    --member='serviceAccount:sa-github-actions@hanzawa-yuya.iam.gserviceaccount.com'
```

# 3. Workload Identity Federationを準備する

## 3.1. Workload Identityプールを作成する

```
gcloud iam workload-identity-pools create "github-actions" \
    --location="global"
```

## 3.2. Workload Identityプールにプロバイダを追加する

* 3.1で作成したWorkload Identityプールにプロバイダを追加する

```
gcloud iam workload-identity-pools providers create-oidc "github" \
    --location="global" \
    --workload-identity-pool="github-actions" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --issuer-uri="https://token.actions.githubusercontent.com"
```

## 3.3. サービスアカウントにアクセス権を付与する

```
REPO="yuya-hanzawa/exec_cloud_functions_by_github_actions"
WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe github-actions --location="global" --format=json | jq -r .name)

gcloud iam service-accounts add-iam-policy-binding "sa-github-actions@hanzawa-yuya.iam.gserviceaccount.com" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"
```
