# Maintainer: Arthur Williams <taaparthur@gmail.com>


pkgname='dual-pointer-x'
pkgver='1.1.4'
_language='en-US'
pkgrel=1
pkgdesc='Automate creating multiple mouse pointers'

arch=('any')
license=('MIT')
depends=('xorg-xinput' 'coreutils')
opt_depends=('notify-send')
md5sums=('SKIP')

source=("git://github.com/TAAPArthur/DualPointerX.git")
_srcDir="DualPointerX"

package() {

  cd "$_srcDir"
  pwd
  mkdir -p "$pkgdir/usr/bin/"
  echo "$pkgdir/usr/share/man/man1/"
  mkdir -p "$pkgdir/usr/share/man/man1/"
  echo "$pkgdir/usr/local/share/man/man1/"
  install -D -m 0755 "dual-pointer-x" "$pkgdir/usr/bin/"
  install -D -m 0755 "dual-pointer-x.1" "$pkgdir/usr/share/man/man1/"
  mandb

}
