FROM registry.redhat.io/ubi8:8.2

ARG INSTALL_DEPS=false
ENV INSTALL_DEPS="$INSTALL_DEPS"

ADD ./driver/smb /bin/smb
ADD ./install_smb_flexvol.sh /bin/install_smb_flexvol.sh

ENTRYPOINT ["/bin/install_smb_flexvol.sh"]
