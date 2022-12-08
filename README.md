# dotfiles

my mac dotfiles

```sh
bash bootstrap.sh
```


## keybase設定参考

### 環境変数 GPG_TTY の設定
export GPG_TTY=$(tty)
#### fish shell なら `set -x GPG_TTY (tty)`

```sh
brew install gnupg pinentry-mac
```

```sh
echo "pinentry-program $(whereis pinentry-mac)" > ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```



```sh
keybase pgp export | gpg --import

keybase pgp export --secret | gpg --allow-secret-key --import
```


### show gpg sercert

```sh
gpg --list-secret-keys
```

```sh
gpg --list-secret-keys
/Users/gavinzhou/.gnupg/pubring.kbx
-----------------------------------
sec   rsa4096 2018-11-19 [SC] [有効期限: 2034-11-15]
      FDAADBA6170F0***********************
uid           [  不明  ] gavin zhou <gavin.zhou@gmail.com>
ssb   rsa4096 2018-11-19 [E] [有効期限: 2034-11-15]
```

```sh
git config --global user.signingkey FDAADBA6170F0***********************
git config --global gpg.program $(which gpg)
```

### 確認

```sh
git commmit -S
```
