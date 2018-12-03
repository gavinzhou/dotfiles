FILE="google-cloud-sdk-101.0.0-linux-x86_64.tar.gz"
LINK="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/"
cd ${HOME}
curl -L "$link""$file" | tar xz
CLOUDSDK_CORE_DISABLE_PROMPTS=1 ${HOME}/google-cloud-sdk/install.sh

y | curl -L https://git.io/n-install | bash
\curl -sSL https://get.rvm.io | bash