# README

## 準備
まずは、以下のコマンドを実行して、ネットワークと起動テンプレートをデプロイする。
ここまでは、無償リソースのみ。

```sh:ネットワークと起動テンプレートのデプロイ
chmod u+x ./script/*
./cfn_deploy.sh
```

次に、以下のコマンドを実行して、EC2を起動する。
課金が始まるので注意。

```sh:EC2の起動
./run_instance.sh
```

## code-serverにアクセス

まずは、以下のコマンドを実行して、ポートフォワードする。

```sh:ポートフォワード
./port_forward.sh -l 8080 -l 8080
```

ローカルマシンのブラウザで、次のURLにアクセスすれば、code-serverにアクセス可能。
<https://localhost:8080/>

## Remote-SSHでアクセス。

エディタで`~/.ssh/config`を修正し、次の設定文をファイルの先頭に記載。

```ssh_config
# code
Include ~/.ssh/code/config
```

次に、以下のコマンドを実行して、一時的な公開鍵をサーバにプッシュし、一時的な秘密鍵と設定ファイルをローカルマシンの設定に追加する。

```sh:一時設定のプッシュ
./push_temporary_settings.sh
```

VS Codeを起動し、Remote-SSHにて`code`にアクセス。
Remote-SSHでのアクセスが完了する。

## Windowsで実施するときの注意点。

- スクリプトの実行はGit-Bash等で実施する。
- 環境によるが、AWSの認証は2回行う必要がある。
  - Git-Bashの実行環境
  - VS Codeの実行環境