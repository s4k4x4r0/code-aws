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
./run_instance.sh -r code
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
Include ~/.ssh/code_aws/config
```

次に、以下のコマンドを実行して、設定ファイルをローカルマシンの設定に追加する。

```sh:一時設定のプッシュ
./push_ssh_client_settings.sh ec2-user code 22
```

次に、VS CodeがGit-BashのSSHを使用するように、VS Codeの設定を変更する。

```json:settings.json
{
  "remote.SSH.path": "<repository_full_path>\\bat\\git-bash-ssh.bat"
}
```

VS Codeを起動し、Remote-SSHにて`code`にアクセス。
Remote-SSHでのアクセスが完了する。

## Windowsで実施するときの注意点。

- スクリプトの実行はGit-Bashで実施する。
- 環境によるが、AWSの認証は2回行う必要がある。
  - Git-Bashの実行環境
  - VS Codeの実行環境
- SSHの認証に失敗する場合があるが、リトライ（再試行、Reload Window）すると成功することがある。
  - 恐らく、失敗する場合は古い秘密鍵を使いまわそうとしているときである。