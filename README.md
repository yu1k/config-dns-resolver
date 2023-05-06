# config-dns-resolver

DNSリゾルバの設定ファイルです。

Dockerコンテナ上で動かします。

zoneファイルを用意し、簡易なネームサーバとしても機能します。

## Requirement

### 確認済みの環境

- ホストOS: Ubuntu 20.04
  - Kernel: x86_64 Linux 5.4.0.*
- シェル: bash
- docker -v: `Docker version 20.10.21`
- docker-compose -v: `docker-compose version 1.25.0`

## Unbound ログの概要

Unboundのログファイルが格納される場所は以下の通りです。

- ホスト側; `./logs/`
- コンテナ側: `$HOME/logs/`

ホスト側の`./logs/`はDockerコンテナ側の`$HOME/logs/`にマウントされているので、ログファイルはホスト、Dockerコンテナ間で同期されます。

## Usage

```
$ git clone https://github.com/yu1k/config-dns-resolver.git config-dns-resolver && cd $_
```

リポジトリをcloneします。

`./unbound.conf` の18行目~のIPv4/IPv6の項目、42行目~のACLの項目をUnboundを動かす環境にあわせて適当に変更します。

`./unbound.conf` の `forward-zone: ` の `forward-addr: ` は適当なDNSリゾルバを指定します。`./unbound.conf`では `8.8.8.8` , `8.8.4.4` を指定しています。

### パフォーマンスの設定

`./unbound.conf` では、以下の環境にあわせて最適化しています。

- CPUコア数: 2コア
- スレッド数: 2スレッド

実際にUnboundを動かす環境に合わせてパフォーマンスまわりの項目を変更します。

参考資料: [Unbound: 最適化の方法 - 日本Unboundユーザ会](https://unbound.jp/unbound/howto_optimise/)

### ゾーンファイルの設定

ゾーンファイルは `./local.zone` としています。

- サンプル

  ```
  local-zone: "local." static
  # Aレコード
  local-data: "host.local. 3600 IN A 172.16.0.1"
  # PTRレコード
  local-data-ptr: "172.16.0.1 3600 host.local."
  ```

上記のサンプルを参考にして `./local.zone` を編集します。

local-dataのパラメータは `[hostname.local]. [TTL] IN [record type] [IP addr]` で設定します。

local-data-ptrのパラメータは `[IP addr] [TTL] [hostname.local].` で設定します。

存在しないTLDを指定する場合は `./unbound.conf` に `domain-insecure` を指定します。

- `domain-insecure` サンプル

  ```
  server:
    domain-insecure: "hoge.huga."
    private-domain: "hoge.huga."
  ```

## Unboundの起動

```
$ docker network create --driver=bridge --subnet=172.16.53.0/24 br_dns_network --attachable -o com.docker.network.bridge.name="br_dns_network"

$ systemctl stop systemd-resolved.service

$ docker-compose up -d --build
```

Dockerコンテナに割り当てる `br_dns_network` というDockerネットワークを作成します。サブネットは適当に指定します。

systemd-resolve が動いている環境の場合、停止します。

DockerfileでビルドしてDockerコンテナを起動します。

## トラブルシュート例

### Dockerコンテナ起動に失敗してしまう

  ```
  ERROR: for dns_resolver_ns  Cannot start service dns_resolver_ns: driver failed programminge
  ERROR: Encountered errors while bringing up the project.
  ```

  上のエラーメッセージが表示されてDockerコンテナの起動に失敗します。systemd-resolveと競合してしまうようです。

  このエラーメッセージが表示された際は systemd-resolve を停止させたところ、Dockerコンテナを起動することができました。

### iOS端末にて手動でDNSリゾルバをしている設定で名前解決に失敗する

  - この不具合を確認した環境
    - iOS 15.6.1
    - iOS 15.7.2

  ```
  このWi-FiネットワークのDNSリクエストはiCloudプライベートリレーによるルーティングがされています。
  DNS設定を手動で行うには、プライベートリレーをオフにしてください。
  ```

  Wi-Fi設定のDNSリゾルバ設定画面で上記のメッセージが表示されていて、かつ、DNSリゾルバを `172.16.0.2` の表記で設定している環境で名前解決に失敗してしまいました。
  
  DNSリゾルバを `172.16.0.2:53` のような表記で設定したところ、名前解決ができるようになりました。

## Unboundのエラーチェック

### unbound.conf のエラーチェック

```
$ docker-compose exec dns_resolver /bin/bash
Dockerコンテナに入ります。

$ unbound-checkconf
> unbound-checkconf: no errors in /etc/unbound/unbound.conf
が返ってくれば大丈夫です。
```

## 参考資料

以下のリンク先を参考にしました。

- Unbound
  - [Unboundの紹介とその運用 IIJ - dnsops.jp](https://dnsops.jp/event/20160624/unbound.pdf)
  - [Unboundの最適化 - 日本Unboundユーザ会](https://unbound.jp/wp/wp-content/uploads/2011/04/Unbound-osc2011tk-optimize.pdf)
  - [Unboundサーバ運用Tips 第4回 - gihyo.jp](https://gihyo.jp/admin/feature/01/unbound/0004)
  - [local-zoneのtypeについて](https://memo.techack.net/dns/unbound/local-zone-type.html)
  - [Unboundで内向きDNSを建てる](https://jyn.jp/unbound-internal-dns/)

- シェルスクリプト
  - [trap コマンドを使ったシェルスクリプトのエラーハンドリング](https://blog.amedama.jp/entry/shell-script-trap-error-handling)
  - [シグナルと trap コマンド](https://shellscript.sunone.me/signal_and_trap.html)