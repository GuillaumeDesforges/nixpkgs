{ lib, buildGoPackage, fetchFromGitLab, fetchurl }:

let
  version = "12.8.0";
  # Gitlab runner embeds some docker images these are prebuilt for arm and x86_64
  docker_x86_64 = fetchurl {
    url = "https://gitlab-runner-downloads.s3.amazonaws.com/v${version}/helper-images/prebuilt-x86_64.tar.xz";
    sha256 = "02k9nzfqlsd78dan522qynbz2i2ggvf960968vmg0wdg6rjv19z2";
  };

  docker_arm = fetchurl {
    url = "https://gitlab-runner-downloads.s3.amazonaws.com/v${version}/helper-images/prebuilt-arm.tar.xz";
    sha256 = "098g6948w8skbz9z5212ndsxvf3k12aijy0v2a7c86r0zhlga52x";
  };
in
buildGoPackage rec {
  inherit version;
  pname = "gitlab-runner";
  goPackagePath = "gitlab.com/gitlab-org/gitlab-runner";
  commonPackagePath = "${goPackagePath}/common";
  buildFlagsArray = ''
    -ldflags=
      -X ${commonPackagePath}.NAME=gitlab-runner
      -X ${commonPackagePath}.VERSION=${version}
      -X ${commonPackagePath}.REVISION=v${version}
  '';

  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "gitlab-runner";
    rev = "v${version}";
    sha256 = "17cs7bs3dxkj6r7hip6kv7cj7g5lq9x1g3gcl2kjj8djxzkhfc4m";
  };

  patches = [ ./fix-shell-path.patch ];

  postInstall = ''
    touch $bin/bin/hello
    install -d $bin/bin/helper-images
    ln -sf ${docker_x86_64} $bin/bin/helper-images/prebuilt-x86_64.tar.xz
    ln -sf ${docker_arm} $bin/bin/helper-images/prebuilt-arm.tar.xz
  '';

  meta = with lib; {
    description = "GitLab Runner the continuous integration executor of GitLab";
    license = licenses.mit;
    homepage = https://about.gitlab.com/gitlab-ci/;
    platforms = platforms.unix ++ platforms.darwin;
    maintainers = with maintainers; [ bachp zimbatm globin ];
  };
}
